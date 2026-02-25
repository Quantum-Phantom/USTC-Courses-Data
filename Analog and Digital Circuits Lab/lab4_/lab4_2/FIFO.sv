`timescale 1ns / 1ps

module FIFO (
    input           clk,
    input           rstn,
    // FIFO操作接口
    input           wr_en,          // 写使能btnl
    input           rd_en,          // 读使能btnr
    input  [15:0]   din,            // 数据输入 sw
    output [15:0]   dout,           // 数据输出
    output          full,           // 满标志
    output          empty,          // 空标志
    // SDU调试接口
    input  [3:0]    sdu_addr,       // 调试地址
    output [15:0]   sdu_data         // 调试数据
);

    // IOU内部信号
    wire [3:0] ra0, wa;
    wire [15:0] rd0, wd;
    wire we;
        
    // IOU模块实例化 - 负责FIFO控制逻辑
    IOU iou_inst (
        .clk(clk),
        .rstn(rstn),
        .btnl(wr_en),               // 映射自wr_en
        .btnr(rd_en),               // 映射自rd_en
        .sw(din),                   // 映射自din
        .full(full),
        .empty(empty),
        .dout(dout),
        // RF接口
        .ra0(ra0),
        .rd0(rd0),
        .wa(wa),
        .wd(wd),
        .we(we)
    );
    
    // RF模块实例化 - 纯存储功能
    RF rf_inst (
        .clk(clk),
        .rstn(rstn),
        // FIFO写端口
        .we(we),
        .wa(wa),
        .wd(wd),
        // FIFO读端口
        .ra0(ra0),
        .rd0(rd0),
        // SDU调试端口
        .ra1(sdu_addr),            // 直接连接sdu_addr
        .rd1(sdu_data)             // 输出sdu_data
    );

endmodule