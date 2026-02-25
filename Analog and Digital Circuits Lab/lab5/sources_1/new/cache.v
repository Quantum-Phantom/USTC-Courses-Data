`timescale 1ns / 1ps

module cache(
    input wire          clk,
    input wire          resetn,

    // --- CPU 流水线接口 ---
    input wire          valid,      // CPU 请求有效信号
    input wire          op,         // 读写操作类型 (1: 写, 0: 读)
    input wire [7:0]    index,      // 地址的 index 域
    input wire [19:0]   tag,        // 地址的 tag 域
    input wire [3:0]    offset,     // 块内偏移
    input wire [3:0]    wstrb,      // 写字节使能
    input wire [31:0]   wdata,      // CPU 写入数据
    
    output wire         addr_ok,    // 地址接收确认
    output wire         data_ok,    // 数据接收确认
    output wire [31:0]  rdata,      // 读出的 32 位数据结果

    // --- AXI 总线接口 ---
    output wire         rd_req,     
    output wire [2:0]   rd_type,    
    output wire [31:0]  rd_addr,    
    input wire          rd_rdy,     
    input wire          ret_valid,  
    input wire          ret_last,   
    input wire [31:0]   ret_data,   
    
    output wire         wr_req,     
    output wire [2:0]   wr_type,    
    output wire [31:0]  wr_addr,    
    output wire [3:0]   wr_wstrb,   
    output wire [127:0] wr_data,    
    input wire          wr_rdy      
);

    // --- 内部信号定义 ---
    wire        req_op;
    wire [7:0]  req_index;      //Request Buffer 输出信号
    wire [19:0] req_tag;
    wire [3:0]  req_offset;
    wire [31:0] req_wdata;
    wire [3:0]  req_wstrb;

    wire [127:0] r_data1, r_data2, m_data;
    wire [19:0]  tag1, tag2;
    wire         v1, v2;
    
    wire [1:0]   hit;
    wire         hit1, hit2;
    wire         hit_way;
    wire         select_way;//index一旦确定，select_way就确定了
    wire         select_valid;
    wire         write_hit;
    wire         miss, miss_start, refill_ready;

    wire [127:0] wb_wdata;//Write Buffer 输出信号(write_hit)
    wire [7:0]   wb_index;
    wire         wb_way, wb_wen;

    wire [127:0] WB_data;//WBuffer 输出信号(refill,来自内存)
    wire [7:0]   WB_index;
    wire [19:0]  WB_tag;
    wire         WB_way, WB_wen;

    // RAM 合并逻辑，不能例化多个
    wire [7:0]   ram_w_index = WB_wen ? WB_index : wb_index;
    wire [127:0] ram_w_data  = WB_wen ? WB_data  : wb_wdata;
    wire         ram_wen1    = (WB_wen && (WB_way == 1'b0)) || (wb_wen && (wb_way == 1'b0));
    wire         ram_wen2    = (WB_wen && (WB_way == 1'b1)) || (wb_wen && (wb_way == 1'b1));
    wire [19:0]  w_tag1      = WB_wen ? WB_tag : req_tag;
    wire [19:0]  w_tag2      = WB_wen ? WB_tag : req_tag;

    // 1. 请求缓冲
    RequestBuffer u_request_buffer (
        .clk(clk),
        .rstn(resetn),
        .index(index),
        .tag(tag),
        .offset(offset),
        .wdata(wdata),
        .wstrb(wstrb),
        .op(op),
        .write_hit(write_hit),
        .miss(miss),

        .reg_index(req_index),
        .reg_tag(req_tag),
        .reg_offset(req_offset),
        .reg_wdata(req_wdata),
        .reg_wstrb(req_wstrb),
        .reg_op(req_op)
    );

    // 2. Data RAM Way1
    DM1 data_memory1 (
        .clka(clk),
        .ena(1'b1),
        .addra(ram_wen1 ? ram_w_index : index),//index
        .wea(ram_wen1),//w_en
        .dina(ram_w_data),//w_data
        .douta(r_data1)
    );
    // 3. Data RAM Way2
    DM1 data_memory2 (
        .clka(clk),
        .ena(1'b1),
        .addra(ram_wen2 ? ram_w_index : index),
        .wea(ram_wen2),
        .dina(ram_w_data),
        .douta(r_data2)
    );

    // 4. TagV RAM Way1
    TAG tag_memory1 (
        .clka(clk),
        .addra(ram_wen1 ? ram_w_index : index),//index
        .wea(ram_wen1),//w_en
        .dina(w_tag1),//tag
        .douta(tag1),
        .ena(1'b1)
    );
    // 5. TagV RAM Way2
    TAG tag_memory2 (
        .clka(clk),
        .addra(ram_wen2 ? ram_w_index : index),
        .wea(ram_wen2),
        .dina(w_tag2),
        .douta(tag2),
        .ena(1'b1)
    );
    V_Memory v_memory1 (
        .clk(clk),
        .rstn(resetn),
        .index(ram_wen1 ? ram_w_index : index),
        .w_en(ram_wen1),
        .v(v1)
    );
    V_Memory v_memory2 (
        .clk(clk),
        .rstn(resetn),
        .index(ram_wen2 ? ram_w_index : index),
        .w_en(ram_wen2),
        .v(v2)
    );

    // 6. 状态机
    assign select_valid=(select_way==1'b0) ? v1 : v2;
    FSM u_fsm (
        .clk(clk),
        .rstn(resetn),
        .valid(valid),
        .op(op),
        .hit(hit),
        .select_valid(select_valid),

        .wr_rdy(wr_rdy),
        .rd_rdy(rd_rdy),
        .refill_ready(refill_ready),
        .wr_req(wr_req),
        .rd_req(rd_req),

        .write_hit(write_hit),
        .miss(miss),
        .addr_ok(addr_ok),
        .data_ok(data_ok),
        .miss_start(miss_start)
    );

    // 7. 命中判断 Way1
    IfEqual ifequal1 (
        .r_tag(tag1),
        .v(v1),
        .tag(req_tag),
        .hit(hit1)
    );
    // 8. 命中判断 Way2
    IfEqual ifequal2 (
        .r_tag(tag2),
        .v(v2),
        .tag(req_tag),
        .hit(hit2)
    );

    assign hit = {hit2, hit1};
    assign hit_way = hit2; 

    // 9. 写命中缓冲
    WriteBuffer write_hit_buffer (
        .clk(clk),
        .rstn(resetn),
        .wbuffer_en(write_hit),
        .index(req_index),
        .wdata(req_wdata),
        .wstrb(req_wstrb),
        .offset(req_offset),
        .way(hit_way),
        .data1(r_data1),
        .data2(r_data2),

        .reg_index(wb_index),
        .reg_wdata(wb_wdata),
        .reg_way(wb_way),
        .reg_wen(wb_wen)
    );

    // 10. LRU
    wire ms_way;
    LRU u_lru (
        .clk(clk),
        .rstn(resetn),
        .index(index),//用直接来自CPU的index，LOOKUP周期出就得到select_way
        .hit(hit),
        .refill_ready(refill_ready),
        .ms_way(ms_way),    // 正在重填的那一路,非命中时，从内存得到数据
        .way_select(select_way)
    );

    // 11. 缺失请求缓冲
    MissBuffer u_miss_buffer (
        .clk(clk),
        .rstn(resetn),
        .miss_start(miss_start),
        .data1(r_data1),
        .data2(r_data2),
        .tag1(tag1),
        .tag2(tag2),
        .way(select_way),
        .index(req_index),

        .wr_data(wr_data),
        .wr_addr(wr_addr),
        .reg_way(ms_way)// 正在重填的那一路
    );

    // 12. AXI 重填拼装缓冲
    ReturnBuffer u_return_buffer (
        .clk(clk),
        .rstn(resetn),
        .miss_start(miss_start),
        .ret_valid(ret_valid),
        .ret_data(ret_data),
        .ret_last(ret_last),
        .op(req_op),
        .offset(req_offset),
        .wdata(req_wdata),
        .wstrb(req_wstrb),
        .final_data(m_data),
        .refill_ready(refill_ready)
    );

    // 13. 重填写入缓冲
    WBUFFER u_refill_wbuffer (
        .clk(clk),
        .rstn(resetn),
        .final_data(m_data),
        .refill_ready(refill_ready),
        .index(req_index),
        .tag(req_tag),
        .way(select_way),
        .reg_data(WB_data),
        .reg_index(WB_index),
        .reg_tag(WB_tag),
        .reg_way(WB_way),
        .reg_wen(WB_wen)
    );

    // 14. 读数据选择
    MUX_128 u_mux_rdata (
        .r_data1(r_data1),
        .r_data2(r_data2),
        .m_data(WB_wen ? WB_data : m_data),
        .offset(req_offset),
        .hit(hit),
        .rdata(rdata)
    );

    // AXI 固定值赋值
    assign rd_type  = 3'b010; 
    assign wr_type  = 3'b100; 
    assign rd_addr  = {req_tag, req_index, 4'b0000};
    assign wr_wstrb = 4'b1111;

endmodule
