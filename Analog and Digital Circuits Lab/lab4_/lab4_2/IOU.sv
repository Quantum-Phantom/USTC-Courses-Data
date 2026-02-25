`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/26 14:34:15
// Design Name: 
// Module Name: IOU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module IOU (
    input           clk,
    input           rstn,
    input           btnl,           // 写按钮
    input           btnr,           // 读按钮
    input   [15:0]  sw,             // 开关输入数据

    output          full,          // 满状态指示灯led16
    output          empty,          // 空状态指示灯led17
    output  [15:0]  dout,            // 数据输出指示灯led0~15 rd0

    // RF接口（内部连接，不在顶层端口）
    output  [3:0]   ra0,            // 读地址0到RF
    input   [15:0]  rd0,            // 读数据0从RF
    output  [3:0]   wa,             // 写地址到RF
    output  [15:0]  wd,             // 写数据到RF
    output          we              // 写使能到RF
);

    // 内部信号声明
    wire btn_write_debounced, btn_read_debounced;
    wire wr_request, rd_request;
    wire wr_en;
    wire inc_front, inc_rear;
    wire [4:0] front_ptr, rear_ptr;
    
    // 按钮去抖动模块实例化
    Debounce #(
        .TD_CYCLES(1)
    ) debounce_write (
        .clk(clk),
        .rst(!rstn),
        .x(btnl),                   // btnl作为写按钮
        .y(btn_write_debounced)
    );
    
    Debounce #(
        .TD_CYCLES(1)//1000000
    ) debounce_read (
        .clk(clk),
        .rst(!rstn),
        .x(btnr),                   // btnr作为读按钮
        .y(btn_read_debounced)
    );
    
    // 边沿检测模块实例化
    GET_Edge edge_detect_write (
        .clk(clk),
        .rst(!rstn),
        .din(btn_write_debounced),
        .dout_pulse(wr_request)
    );
    
    GET_Edge edge_detect_read (
        .clk(clk),
        .rst(!rstn),
        .din(btn_read_debounced),
        .dout_pulse(rd_request)
    );
    
    // POINTER模块实例化
    POINTER pointer_inst (
        .clk(clk),
        .rstn(rstn),
        .inc_front(inc_front),
        .inc_rear(inc_rear),

        .front_ptr(front_ptr),
        .rear_ptr(rear_ptr),
        .empty(empty),
        .full(full)
    );
    
    // FIFO_CONTROLLER模块实例化
    FSM controller_inst (
        .clk(clk),
        .rstn(rstn),
        .wr_request(wr_request),
        .rd_request(rd_request),
        .empty(empty),
        .full(full),

        .wr_en(wr_en),
        .inc_front(inc_front),
        .inc_rear(inc_rear)
    );
    
    // RF接口信号连接
    assign ra0 = front_ptr[3:0];    // 使用低4位（0-15地址范围）
    assign wa = rear_ptr[3:0];      // 写地址
    assign wd = sw;                 // 写数据来自开关
    assign we = wr_en;     // 写使能
    assign dout=rd0;
    
endmodule