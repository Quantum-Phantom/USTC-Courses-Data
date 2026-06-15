/*
N路组相连Cache
- 保持与 simple_cache.v 相同的 CPU / 内存接口
- 采用写回写分配策略
- WAY_NUM 仅要求支持 2 / 4 / 8 / 16
- LRU 采用按组递增时间戳，优先替换无效路，否则替换时间戳最小的路
*/
`timescale 1ns/1ps
module n_cache #(
    parameter INDEX_WIDTH       = 2,    // 组索引位宽，组数为 2^INDEX_WIDTH
    parameter LINE_OFFSET_WIDTH = 2,    // 行内字偏移位宽，每行字数为 2^LINE_OFFSET_WIDTH
    parameter SPACE_OFFSET      = 2,    // 字节偏移位宽，32-bit 字通常固定为 2
    parameter WAY_NUM           = 8     // 组相连路数，只支持 2/4/8/16
)(
    input                     clk,
    input                     rstn,
    /* CPU接口 */  
    input [31:0]              addr,   // CPU地址
    input                     r_req,  // CPU读请求
    input                     w_req,  // CPU写请求
    input [31:0]              w_data,   // CPU写数据
    output [31:0]             r_data,   // CPU读数据
    output reg                miss,     // 当前请求是否 miss
    /* 内存接口 */
    output reg                mem_r,    // 触发整行读内存
    output reg                mem_w,    // 触发整行写回内存
    output reg [31:0]         mem_addr, // 内存行基地址
    output reg [127:0]        mem_w_data, // 写回的一整行数据
    input      [127:0]        mem_r_data, // 内存返回的一整行数据
    input                     mem_ready   // 内存读/写完成握手
);

    initial begin // 静态限制支持的路数
        if ((WAY_NUM != 2) && (WAY_NUM != 4) && (WAY_NUM != 8) && (WAY_NUM != 16)) begin
            $display("n_cache only supports WAY_NUM = 2, 4, 8, 16");
            $finish;
        end
    end

    function integer clog2_int; // 计算容纳 value 所需的地址位宽
        input integer value;
        integer i;
        begin
            clog2_int = 0;
            for (i = value - 1; i > 0; i = i >> 1) begin
                clog2_int = clog2_int + 1;
            end
            if (clog2_int == 0) begin
                clog2_int = 1;
            end
        end
    endfunction

    localparam LINE_WIDTH      = 32 << LINE_OFFSET_WIDTH; // 一整行总位宽
    localparam TAG_WIDTH       = 32 - INDEX_WIDTH - LINE_OFFSET_WIDTH - SPACE_OFFSET; // tag 位宽
    localparam WAY_INDEX_WIDTH = clog2_int(WAY_NUM); // 路号编码位宽
    localparam TAG_META_WIDTH  = TAG_WIDTH + 2; // valid/dirty/tag 合并后的位宽
    localparam LRU_WIDTH       = 32; // 每组时间戳位宽

    reg  [31:0] addr_buf;                  // 锁存当前正在处理的 CPU 地址
    reg  [31:0] w_data_buf;                // 锁存当前写请求数据
    reg         op_buf;                    // 锁存当前操作类型，0读1写
    reg  [LINE_WIDTH-1:0] ret_buf;         // 锁存从内存读回的一整行
    reg         refill;                    // 标记下一拍在 IDLE 中执行重填
    reg  [WAY_INDEX_WIDTH-1:0] refill_way; // 记录要重填到哪一路

    reg  [31:0] dirty_mem_addr_buf;        // 写回脏块时保存其内存地址
    reg  [LINE_WIDTH-1:0] dirty_mem_data_buf; // 写回脏块时保存其整行数据

    wire [INDEX_WIDTH-1:0]       r_index;     // 当前输入地址对应的组号
    wire [INDEX_WIDTH-1:0]       w_index;     // 锁存地址对应的组号
    wire [TAG_WIDTH-1:0]         tag;         // 锁存地址对应的 tag
    wire [LINE_OFFSET_WIDTH-1:0] word_offset; // 锁存地址对应的行内字偏移

    reg                          addr_buf_we;   // 地址缓冲写使能
    reg                          ret_buf_we;    // 内存返回缓冲写使能
    reg  [WAY_NUM-1:0]           data_we;       // 每一路 data BRAM 写使能
    reg  [WAY_NUM-1:0]           tag_we;        // 每一路 tag/meta BRAM 写使能
    reg  [WAY_NUM-1:0]           lru_we;        // 每一路 LRU 时间戳写使能
    reg                          counter_we;    // 每组全局访问时间戳写使能
    reg                          data_from_mem; // r_data 选择 ret_buf 还是 cache line
    reg                          w_valid;       // 回写 tag/meta 时的 valid 位
    reg                          w_dirty;       // 回写 tag/meta 时的 dirty 位
    reg  [LRU_WIDTH-1:0]         lru_din;       // 要写入命中/重填路的时间戳
    reg  [LRU_WIDTH-1:0]         counter_din;   // 要写入该组计数器的新时间戳

    reg  [2:0] CS; // 当前状态
    reg  [2:0] NS; // 下一状态

    localparam  //五个状态
        IDLE    = 3'd0,
        READ    = 3'd1,
        MISS    = 3'd2,
        WRITE   = 3'd3,
        W_DIRTY = 3'd4;

    wire [WAY_NUM*LINE_WIDTH-1:0]     data_dout_bus;     // 拼接所有 way 的数据行输出
    wire [WAY_NUM*TAG_META_WIDTH-1:0] tag_meta_dout_bus; // 拼接所有 way 的 tag/valid/dirty 输出
    wire [WAY_NUM*LRU_WIDTH-1:0]      lru_dout_bus;      // 拼接所有 way 的 LRU 时间戳输出
    wire [LRU_WIDTH-1:0]              set_lru_counter;   // 当前组的访问时间基准

    wire [LINE_WIDTH-1:0] w_line_mask; // 命中字的 32-bit 写掩码
    wire [LINE_WIDTH-1:0] w_data_line; // 写数据移动到目标字槽位后的整行形式
    reg  [LINE_WIDTH-1:0] w_line;      // 最终写回 data BRAM 的整行

    reg                         hit_r;           // 当前组是否命中任一路
    reg  [WAY_INDEX_WIDTH-1:0]  hit_way_r;       // 命中的 way 编号
    reg  [WAY_INDEX_WIDTH-1:0]  victim_way_r;    // 替换目标的 way 编号
    reg  [LINE_WIDTH-1:0]       victim_line_r;   // 被替换路当前整行数据
    reg  [TAG_WIDTH-1:0]        victim_tag_r;    // 被替换路当前 tag
    reg                         victim_valid_r;  // 被替换路 valid 位
    reg                         victim_dirty_r;  // 被替换路 dirty 位
    reg  [LRU_WIDTH-1:0]        victim_stamp_r;  // 被替换路时间戳
    reg  [LINE_WIDTH-1:0]       selected_line_r; // 命中时为命中行，否则为 victim 行
    reg                         invalid_found_r; // victim 搜索时是否已找到空路

    wire [31:0] next_lru_stamp; // 本次访问后应写入的新时间戳
    wire [31:0] mem_data_word;  // 从 ret_buf 里切出的目标字
    wire [31:0] cache_data_word; // 从 cache line 里切出的目标字
    wire [31:0] victim_mem_addr; // victim 对应的写回基地址

    integer i;
    genvar gi;

    assign r_index = addr[INDEX_WIDTH + LINE_OFFSET_WIDTH + SPACE_OFFSET - 1:LINE_OFFSET_WIDTH + SPACE_OFFSET]; // 直接用输入地址查当前组
    assign w_index = addr_buf[INDEX_WIDTH + LINE_OFFSET_WIDTH + SPACE_OFFSET - 1:LINE_OFFSET_WIDTH + SPACE_OFFSET]; // 用锁存地址执行 miss 后续流程
    assign tag = addr_buf[31:INDEX_WIDTH + LINE_OFFSET_WIDTH + SPACE_OFFSET]; // 从锁存地址取 tag
    assign word_offset = addr_buf[LINE_OFFSET_WIDTH + SPACE_OFFSET - 1:SPACE_OFFSET]; // 从锁存地址取行内字偏移

    assign w_line_mask = {{(LINE_WIDTH - 32){1'b0}}, 32'hFFFF_FFFF} << (word_offset * 32); // 对应字位置 1，其余为 0
    assign w_data_line = {{(LINE_WIDTH - 32){1'b0}}, w_data_buf} << (word_offset * 32); // 写数据移到目标字位置
    assign next_lru_stamp = set_lru_counter + 1'b1; // 每次命中/重填都推进该组时间戳
    assign mem_data_word = ret_buf >> (word_offset * 32); // 从内存返回行中取目标字
    assign cache_data_word = selected_line_r >> (word_offset * 32); // 从选中 cache 行中取目标字
    assign victim_mem_addr = {victim_tag_r, w_index, {(LINE_OFFSET_WIDTH + SPACE_OFFSET){1'b0}}}; // victim 写回地址
    assign r_data = data_from_mem ? mem_data_word : cache_data_word; // miss 重填后读内存，否则读 cache

    generate    //tag+data+LRU
        for (gi = 0; gi < WAY_NUM; gi = gi + 1) begin : gen_way // 每一路各自例化 tag/data/lru BRAM
            bram #(
                .ADDR_WIDTH(INDEX_WIDTH),
                .DATA_WIDTH(TAG_META_WIDTH)
            ) tag_bram (
                .clk(clk),
                .raddr(r_index),
                .waddr(w_index),
                .din({w_valid, w_dirty, tag}),
                .we(tag_we[gi]),
                .dout(tag_meta_dout_bus[gi*TAG_META_WIDTH +: TAG_META_WIDTH])   //提取第几路
            );

            bram #(
                .ADDR_WIDTH(INDEX_WIDTH),
                .DATA_WIDTH(LINE_WIDTH)
            ) data_bram (
                .clk(clk),
                .raddr(r_index),
                .waddr(w_index),
                .din(w_line),
                .we(data_we[gi]),
                .dout(data_dout_bus[gi*LINE_WIDTH +: LINE_WIDTH])
            );

            bram #(
                .ADDR_WIDTH(INDEX_WIDTH),
                .DATA_WIDTH(LRU_WIDTH)
            ) lru_bram (
                .clk(clk),
                .raddr(r_index),
                .waddr(w_index),
                .din(lru_din),
                .we(lru_we[gi]),
                .dout(lru_dout_bus[gi*LRU_WIDTH +: LRU_WIDTH])
            );
        end
    endgenerate

    bram #(
        .ADDR_WIDTH(INDEX_WIDTH),   //行数为set
        .DATA_WIDTH(LRU_WIDTH)  //32
    ) lru_counter_bram ( // 每组一个公共计数器，为时间戳 LRU 提供递增基准
        .clk(clk),
        .raddr(r_index),
        .waddr(w_index),
        .din(counter_din),
        .we(counter_we),
        .dout(set_lru_counter)
    );

    always @(posedge clk or negedge rstn) begin //状态转换
        if (!rstn) begin
            CS <= IDLE;
        end
        else begin
            CS <= NS;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            addr_buf <= 32'b0;  // 锁存当前正在处理的 CPU 地址
            w_data_buf <= 32'b0;
            op_buf <= 1'b0;
            ret_buf <= {LINE_WIDTH{1'b0}};
            refill <= 1'b0;
            refill_way <= {WAY_INDEX_WIDTH{1'b0}};
            dirty_mem_addr_buf <= 32'b0;
            dirty_mem_data_buf <= {LINE_WIDTH{1'b0}};
        end
        else begin
            if (addr_buf_we) begin
                addr_buf <= addr;   //锁存当前正在处理的 CPU 地址
                w_data_buf <= w_data;
                op_buf <= w_req;
            end

            if (ret_buf_we) begin
                ret_buf <= mem_r_data;  // 锁存从内存读回的一整行
            end

            if (CS == READ || CS == WRITE) begin // miss 判定拍先保存 victim 信息，供后续写回/重填使用
                refill_way <= victim_way_r; // 替换目标的 way 编号
                dirty_mem_addr_buf <= victim_mem_addr;  //替换写回地址
                dirty_mem_data_buf <= victim_line_r;    //被替换路当前整行数据
            end

            if (CS == MISS && mem_ready) begin
                refill <= 1'b1;
            end
            else if (CS == IDLE) begin
                refill <= 1'b0;
            end
        end
    end

    always @(*) begin // 命中检测 + victim 选择：先找命中，再按“空路优先，否则最小时间戳”选 victim
        hit_r = 1'b0;
        hit_way_r = {WAY_INDEX_WIDTH{1'b0}};    //命中的路号
        victim_way_r = {WAY_INDEX_WIDTH{1'b0}}; //替换目标路号
        victim_line_r = data_dout_bus[0 +: LINE_WIDTH]; //第 0 路从 BRAM 读出来的数据
        victim_tag_r = tag_meta_dout_bus[0 +: TAG_WIDTH];
        victim_valid_r = tag_meta_dout_bus[TAG_WIDTH + 1];
        victim_dirty_r = tag_meta_dout_bus[TAG_WIDTH];
        victim_stamp_r = lru_dout_bus[0 +: LRU_WIDTH];
        selected_line_r = data_dout_bus[0 +: LINE_WIDTH];
        invalid_found_r = 1'b0; //是否找到空闲无效路

        for (i = 0; i < WAY_NUM; i = i + 1) begin   //命中检测
            if (!hit_r &&   //防止多路命中保护
                tag_meta_dout_bus[i*TAG_META_WIDTH + TAG_WIDTH + 1] &&  //有效位
                (tag_meta_dout_bus[i*TAG_META_WIDTH +: TAG_WIDTH] == tag)) begin
                hit_r = 1'b1;
                hit_way_r = i[WAY_INDEX_WIDTH-1:0];
            end
        end

        for (i = 0; i < WAY_NUM; i = i + 1) begin   //寻找victim
            if (!invalid_found_r &&
                !tag_meta_dout_bus[i*TAG_META_WIDTH + TAG_WIDTH + 1]) begin //找到无效路
                victim_way_r = i[WAY_INDEX_WIDTH-1:0];
                victim_line_r = data_dout_bus[i*LINE_WIDTH +: LINE_WIDTH];
                victim_tag_r = tag_meta_dout_bus[i*TAG_META_WIDTH +: TAG_WIDTH];
                victim_valid_r = 1'b0;
                victim_dirty_r = 1'b0;
                victim_stamp_r = lru_dout_bus[i*LRU_WIDTH +: LRU_WIDTH];
                invalid_found_r = 1'b1;
            end
            else if (!invalid_found_r &&
                     lru_dout_bus[i*LRU_WIDTH +: LRU_WIDTH] < victim_stamp_r) begin //时间戳更小
                victim_way_r = i[WAY_INDEX_WIDTH-1:0];
                victim_line_r = data_dout_bus[i*LINE_WIDTH +: LINE_WIDTH];
                victim_tag_r = tag_meta_dout_bus[i*TAG_META_WIDTH +: TAG_WIDTH];
                victim_valid_r = 1'b1;
                victim_dirty_r = tag_meta_dout_bus[i*TAG_META_WIDTH + TAG_WIDTH];
                victim_stamp_r = lru_dout_bus[i*LRU_WIDTH +: LRU_WIDTH];
            end
        end

        if (hit_r) begin // 命中时输出命中路的数据
            selected_line_r = data_dout_bus[hit_way_r*LINE_WIDTH +: LINE_WIDTH];
        end
        else begin // 未命中时 selected_line_r 退化为 victim 行，便于统一写路径
            selected_line_r = victim_line_r;
        end
    end

    always @(*) begin // 状态转移：命中直接完成，miss 时必要时先写回脏块
        case (CS)
            IDLE: begin
                if (r_req) begin
                    NS = READ;
                end
                else if (w_req) begin
                    NS = WRITE;
                end
                else begin
                    NS = IDLE;
                end
            end
            READ: begin
                if (!hit_r && victim_valid_r && victim_dirty_r) begin
                    NS = W_DIRTY;
                end
                else if (!hit_r) begin
                    NS = MISS;
                end
                else if (r_req) begin
                    NS = READ;
                end
                else if (w_req) begin
                    NS = WRITE;
                end
                else begin
                    NS = IDLE;
                end
            end
            MISS: begin
                if (mem_ready) begin
                    NS = IDLE;
                end
                else begin
                    NS = MISS;
                end
            end
            WRITE: begin
                if (!hit_r && victim_valid_r && victim_dirty_r) begin
                    NS = W_DIRTY;
                end
                else if (!hit_r) begin
                    NS = MISS;
                end
                else if (r_req) begin
                    NS = READ;
                end
                else if (w_req) begin
                    NS = WRITE;
                end
                else begin
                    NS = IDLE;
                end
            end
            W_DIRTY: begin
                if (mem_ready) begin
                    NS = MISS;
                end
                else begin
                    NS = W_DIRTY;
                end
            end
            default: begin
                NS = IDLE;
            end
        endcase
    end

    always @(*) begin // 输出与写使能控制
        addr_buf_we = 1'b0;
        ret_buf_we = 1'b0;
        data_we = {WAY_NUM{1'b0}};  // 每一路 data BRAM 写使能
        tag_we = {WAY_NUM{1'b0}};
        lru_we = {WAY_NUM{1'b0}};
        counter_we = 1'b0;
        data_from_mem = 1'b0;
        w_valid = 1'b0;
        w_dirty = 1'b0;
        lru_din = {LRU_WIDTH{1'b0}};
        counter_din = {LRU_WIDTH{1'b0}};
        miss = 1'b0;
        mem_r = 1'b0;
        mem_w = 1'b0;
        mem_addr = 32'b0;
        mem_w_data = {LINE_WIDTH{1'b0}};

        w_line = selected_line_r;

        case (CS)
            IDLE: begin
                addr_buf_we = 1'b1;
                if (refill) begin // 在 IDLE 拍真正把内存返回行写入选中的 victim way
                    data_from_mem = 1'b1;
                    w_valid = 1'b1;
                    w_dirty = op_buf;
                    lru_din = next_lru_stamp;
                    counter_din = next_lru_stamp;
                    counter_we = 1'b1;

                    if (op_buf) begin
                        w_line = (ret_buf & ~w_line_mask) | w_data_line;
                    end
                    else begin
                        w_line = ret_buf;
                    end

                    data_we[refill_way] = 1'b1;
                    tag_we[refill_way] = 1'b1;
                    lru_we[refill_way] = 1'b1;
                end
            end
            READ: begin
                if (hit_r) begin // 读命中只更新 LRU，不改数据阵列
                    addr_buf_we = 1'b1;
                    lru_din = next_lru_stamp;
                    counter_din = next_lru_stamp;
                    counter_we = 1'b1;
                    lru_we[hit_way_r] = 1'b1;
                end
                else begin // 读 miss：若 victim 脏则先发写回
                    miss = 1'b1;
                    if (victim_valid_r && victim_dirty_r) begin
                        mem_w = 1'b1;
                        mem_addr = victim_mem_addr;
                        mem_w_data = victim_line_r;
                    end
                end
            end
            MISS: begin
                miss = 1'b1;
                mem_r = 1'b1;
                mem_addr = {tag, w_index, {(LINE_OFFSET_WIDTH + SPACE_OFFSET){1'b0}}};
                if (mem_ready) begin // 内存返回后把整行锁存到 ret_buf，下一拍回 IDLE 重填
                    mem_r = 1'b0;
                    ret_buf_we = 1'b1;
                end
            end
            WRITE: begin
                w_line = (selected_line_r & ~w_line_mask) | w_data_line;
                if (hit_r) begin // 写命中直接改命中路并置脏
                    addr_buf_we = 1'b1;
                    w_valid = 1'b1;
                    w_dirty = 1'b1;
                    lru_din = next_lru_stamp;
                    counter_din = next_lru_stamp;
                    counter_we = 1'b1;
                    data_we[hit_way_r] = 1'b1;
                    tag_we[hit_way_r] = 1'b1;
                    lru_we[hit_way_r] = 1'b1;
                end
                else begin // 写 miss：走写分配，必要时先写回 victim
                    miss = 1'b1;
                    if (victim_valid_r && victim_dirty_r) begin
                        mem_w = 1'b1;
                        mem_addr = victim_mem_addr;
                        mem_w_data = victim_line_r;
                    end
                end
            end
            W_DIRTY: begin
                miss = 1'b1;
                mem_w = 1'b1;
                mem_addr = dirty_mem_addr_buf;
                mem_w_data = dirty_mem_data_buf;
                if (mem_ready) begin
                    mem_w = 1'b0;
                end
            end
            default: begin
            end
        endcase
    end

endmodule
