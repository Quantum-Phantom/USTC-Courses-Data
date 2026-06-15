/*
参数化 N 路组相连 Cache 实现
- 支持 N=2,4,8,16 的多路组相连
- 采用 LRU 替换策略
- 采用写回写分配策略
- 块大小：4字（16字节 128位）
*/
module cache #(
    parameter INDEX_WIDTH       = 2,    // Cache索引位宽 2^2=4组
    parameter LINE_OFFSET_WIDTH = 2,    // 行偏移位宽，决定每行字的个数 2^2=4字
    parameter SPACE_OFFSET      = 2,    // 一个地址空间占1个字节，因此一个字需要4个地址空间
    parameter WAY_NUM           = 2     // Cache N路组相联(2,4,8,16)
)(
    input                     clk,    
    input                     rstn,
    /* CPU接口 */  
    input [31:0]              addr,   // CPU地址
    input                     r_req,  // CPU读请求
    input                     w_req,  // CPU写请求
    input [31:0]              w_data,  // CPU写数据
    output [31:0]             r_data,  // CPU读数据
    output reg                miss,   // 缓存未命中
    /* 内存接口 */  
    output reg                     mem_r,      // 内存读请求
    output reg                     mem_w,      // 内存写请求
    output reg [31:0]              mem_addr,   // 内存地址
    output reg [127:0]             mem_w_data, // 内存写数据
    input      [127:0]             mem_r_data, // 内存读数据
    input                          mem_ready   // 内存就绪信号
);

    // Cache参数
    localparam
        LINE_WIDTH = 32 << LINE_OFFSET_WIDTH,   // Cache行宽度 = 128位
        TAG_WIDTH = 32 - INDEX_WIDTH - LINE_OFFSET_WIDTH - SPACE_OFFSET,
        SET_NUM   = 1 << INDEX_WIDTH;
    
    // 地址分解
    wire [INDEX_WIDTH-1:0]         r_index;
    wire [INDEX_WIDTH-1:0]         w_index;
    wire [TAG_WIDTH-1:0]           tag;
    wire [LINE_OFFSET_WIDTH-1:0]   word_offset;
    
    assign r_index = addr[INDEX_WIDTH+LINE_OFFSET_WIDTH+SPACE_OFFSET - 1: LINE_OFFSET_WIDTH+SPACE_OFFSET];
    assign w_index = addr_buf[INDEX_WIDTH+LINE_OFFSET_WIDTH+SPACE_OFFSET - 1: LINE_OFFSET_WIDTH+SPACE_OFFSET];
    assign tag = addr_buf[31:INDEX_WIDTH+LINE_OFFSET_WIDTH+SPACE_OFFSET];
    assign word_offset = addr_buf[LINE_OFFSET_WIDTH+SPACE_OFFSET-1:SPACE_OFFSET];

    // 缓存寄存器
    reg [31:0]           addr_buf;
    reg [31:0]           w_data_buf;
    reg                  op_buf;     // 0:读 1:写
    reg [LINE_WIDTH-1:0] ret_buf;
    
    // 状态机
    localparam 
        IDLE      = 3'd0,
        READ      = 3'd1,
        MISS      = 3'd2,
        WRITE     = 3'd3,
        W_DIRTY   = 3'd4;
    reg [2:0] CS, NS;

    // 从每个way读出数据
    wire [LINE_WIDTH-1:0]  data_out[0:WAY_NUM-1];
    wire [TAG_WIDTH-1:0]   tag_out[0:WAY_NUM-1];
    wire                   valid_out[0:WAY_NUM-1];
    wire                   dirty_out[0:WAY_NUM-1];
    wire [7:0]             lru_out[0:WAY_NUM-1];   // 每个way的LRU时间戳
    
    // 全局计时器
    reg [15:0] global_timer;

    // 生成BRAM实例
    generate
        genvar i;
        for (i = 0; i < WAY_NUM; i = i + 1) begin : WAYS
            bram #(
                .ADDR_WIDTH(INDEX_WIDTH),
                .DATA_WIDTH(TAG_WIDTH + 2)  // valid + dirty + tag
            ) tag_bram(
                .clk(clk),
                .raddr(r_index),
                .waddr(w_index),
                .din({w_valid, w_dirty, tag}),
                .we(tag_we[i]),
                .dout({valid_out[i], dirty_out[i], tag_out[i]})
            );

            bram #(
                .ADDR_WIDTH(INDEX_WIDTH),
                .DATA_WIDTH(LINE_WIDTH)
            ) data_bram(
                .clk(clk),
                .raddr(r_index),
                .waddr(w_index),
                .din(w_line),
                .we(data_we[i]),
                .dout(data_out[i])
            );
            
            // LRU时间戳BRAM - 每个way一个
            bram #(
                .ADDR_WIDTH(INDEX_WIDTH),
                .DATA_WIDTH(8)
            ) lru_bram(
                .clk(clk),
                .raddr(r_index),
                .waddr(w_index),
                .din(w_lru_timestamp),
                .we(lru_we[i]),
                .dout(lru_out[i])
            );
        end
    endgenerate

    // 命中检测与路选择
    reg [WAY_NUM-1:0] hit_way;
    wire hit;
    reg [3:0] hit_way_idx;
    reg [3:0] victim_way_idx;
    integer k;
    
    // 组合逻辑：检查命中
    always @(*) begin
        for (k = 0; k < WAY_NUM; k = k + 1) begin
            if (valid_out[k] && tag_out[k] == tag) begin
                hit_way[k] = 1'b1;
            end else begin
                hit_way[k] = 1'b0;
            end
        end
    end
    
    assign hit = |hit_way;

    // 优先级编码器：找第一个命中的way
    always @(*) begin
        hit_way_idx = 0;
        for (k = 0; k < WAY_NUM; k = k + 1) begin
            if (hit_way[k]) begin
                hit_way_idx = k;
            end
        end
    end

    // 找到最旧的way（应该被替换）
    always @(*) begin
        victim_way_idx = 0;
        if (!valid_out[0]) begin
            victim_way_idx = 0;
        end else begin
            for (k = 1; k < WAY_NUM; k = k + 1) begin
                if (!valid_out[k]) begin
                    victim_way_idx = k;
                end else if (lru_out[k] < lru_out[victim_way_idx]) begin
                    victim_way_idx = k;
                end
            end
        end
    end

    wire victim_dirty = dirty_out[victim_way_idx];
    wire victim_valid = valid_out[victim_way_idx];
    wire [LINE_WIDTH-1:0] victim_line = data_out[victim_way_idx];
    wire [TAG_WIDTH-1:0] victim_tag = tag_out[victim_way_idx];

    // 计算脏块地址
    wire [31:0] dirty_mem_addr = {victim_tag, w_index} << (LINE_OFFSET_WIDTH + SPACE_OFFSET);
    
    reg [31:0] dirty_mem_addr_buf;
    reg [127:0] dirty_mem_data_buf;

    // 控制信号
    reg addr_buf_we, ret_buf_we;
    reg [WAY_NUM-1:0] data_we, tag_we, lru_we;
    reg w_valid, w_dirty;
    reg [7:0] w_lru_timestamp;
    reg data_from_mem;
    reg refill;
    reg [3:0] refill_way;

    // 从Cache选择数据
    wire [31:0] cache_data;
    wire [31:0] mem_data_out;
    
    assign cache_data = data_out[hit_way_idx] >> (word_offset * 32);
    assign mem_data_out = ret_buf >> (word_offset * 32);
    assign r_data = data_from_mem ? mem_data_out : cache_data;

    // 写数据的掩码和移位
    wire [LINE_WIDTH-1:0] w_line;
    wire [31:0] w_line_mask = 32'hFFFFFFFF << (word_offset * 32);
    wire [LINE_WIDTH-1:0] w_data_shifted = {{(LINE_WIDTH-32){1'b0}}, w_data_buf} << (word_offset * 32);
    
    assign w_line = (CS == IDLE && op_buf) ? (ret_buf & ~w_line_mask) | w_data_shifted :
                    (CS == IDLE) ? ret_buf :
                    (data_out[hit_way_idx] & ~w_line_mask) | w_data_shifted;

    // 状态机
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            CS <= IDLE;
        end else begin
            CS <= NS;
        end
    end

    // 全局计时器 + LRU更新
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            global_timer <= 0;
        end else begin
            global_timer <= global_timer + 1;
        end
    end

    // 缓存寄存器更新
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            addr_buf <= 0;
            w_data_buf <= 0;
            op_buf <= 0;
            ret_buf <= 0;
            refill <= 0;
            refill_way <= 0;
            dirty_mem_addr_buf <= 0;
            dirty_mem_data_buf <= 0;
        end else begin
            if (addr_buf_we) begin
                addr_buf <= addr;
                w_data_buf <= w_data;
                op_buf <= w_req;
            end
            if (ret_buf_we) begin
                ret_buf <= mem_r_data;
            end
            if (CS == MISS && mem_ready) begin
                refill <= 1;
                refill_way <= victim_way_idx;
            end
            if (CS == IDLE) begin
                refill <= 0;
            end
            if (CS == READ || CS == WRITE) begin
                dirty_mem_addr_buf <= dirty_mem_addr;
                dirty_mem_data_buf <= victim_line;
            end
        end
    end

    // 状态转移逻辑
    always @(*) begin
        case (CS)
            IDLE: begin
                if (r_req) NS = READ;
                else if (w_req) NS = WRITE;
                else NS = IDLE;
            end
            READ: begin
                if (hit) NS = IDLE;
                else if (victim_dirty && victim_valid) NS = W_DIRTY;
                else NS = MISS;
            end
            MISS: begin
                NS = mem_ready ? IDLE : MISS;
            end
            WRITE: begin
                if (hit) NS = IDLE;
                else if (victim_dirty && victim_valid) NS = W_DIRTY;
                else NS = MISS;
            end
            W_DIRTY: begin
                NS = mem_ready ? MISS : W_DIRTY;
            end
            default: NS = IDLE;
        endcase
    end

    // 控制信号生成
    always @(*) begin
        // 默认值
        addr_buf_we = 1'b0;
        ret_buf_we = 1'b0;
        data_we = {WAY_NUM{1'b0}};
        tag_we = {WAY_NUM{1'b0}};
        lru_we = {WAY_NUM{1'b0}};
        w_valid = 1'b0;
        w_dirty = 1'b0;
        w_lru_timestamp = global_timer[7:0];
        data_from_mem = 1'b0;
        miss = 1'b0;
        mem_r = 1'b0;
        mem_w = 1'b0;
        mem_addr = 32'b0;
        mem_w_data = 128'b0;

        case (CS)
            IDLE: begin
                addr_buf_we = 1'b1;
                if (refill) begin
                    data_from_mem = 1'b1;
                    w_valid = 1'b1;
                    w_dirty = op_buf ? 1'b1 : 1'b0;
                    data_we[refill_way] = 1'b1;
                    tag_we[refill_way] = 1'b1;
                    lru_we[refill_way] = 1'b1;
                end
            end
            READ: begin
                if (hit) begin
                    miss = 1'b0;
                    addr_buf_we = 1'b1;
                    lru_we[hit_way_idx] = 1'b1;
                end else begin
                    miss = 1'b1;
                    if (victim_dirty && victim_valid) begin
                        mem_w = 1'b1;
                        mem_addr = dirty_mem_addr_buf;
                        mem_w_data = dirty_mem_data_buf;
                    end
                end
            end
            MISS: begin
                miss = 1'b1;
                mem_r = 1'b1;
                mem_addr = {tag, w_index} << (LINE_OFFSET_WIDTH + SPACE_OFFSET);
                if (mem_ready) begin
                    ret_buf_we = 1'b1;
                end
            end
            WRITE: begin
                if (hit) begin
                    miss = 1'b0;
                    addr_buf_we = 1'b1;
                    w_valid = 1'b1;
                    w_dirty = 1'b1;
                    data_we[hit_way_idx] = 1'b1;
                    tag_we[hit_way_idx] = 1'b1;
                    lru_we[hit_way_idx] = 1'b1;
                end else begin
                    miss = 1'b1;
                    if (victim_dirty && victim_valid) begin
                        mem_w = 1'b1;
                        mem_addr = dirty_mem_addr_buf;
                        mem_w_data = dirty_mem_data_buf;
                    end
                end
            end
            W_DIRTY: begin
                miss = 1'b1;
                mem_w = 1'b1;
                mem_addr = dirty_mem_addr_buf;
                mem_w_data = dirty_mem_data_buf;
            end
        endcase
    end

endmodule