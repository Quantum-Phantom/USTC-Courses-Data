`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/04 09:22:19
// Design Name: 
// Module Name: BUBBLESORT
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


module BUBBLESORT(
    input           clk,
    input           rstn,//
    input           start,//btnl
    output          done,//led16
    output [15:0]   round_count,
    // SDU调试接口
    input  [9:0]    sdu_addr,       // 调试地址
    output [31:0]   sdu_data         // 调试数据
    );

wire [9:0]  bram_addr; // BRAM地址
wire        bram_we;    // BRAM写使能
wire [31:0] bram_din;   // BRAM写入数据
wire [31:0] bram_dout;   // BRAM读出数据

BUBBLE bubble(
    .clk(clk),
    .rst_n(rstn),
    .start(start),
    .done(done),
    .round_count(round_count),

    .bram_addr(bram_addr),
    .bram_we(bram_we),
    .bram_din(bram_din),
    .bram_dout(bram_dout)
);
BRAM bram(
    .clk(clk),
    .rstn(rstn),
    .bram_we(bram_we),        // 写使能
    .bram_addr(bram_addr),     // 地址
    .bram_din(bram_din),       // 写数据
    .bram_dout(bram_dout),     // 读数据
    .debug_addr(sdu_addr),     // 调试地址
    .debug_data(sdu_data)       // 调试数据
);
endmodule
