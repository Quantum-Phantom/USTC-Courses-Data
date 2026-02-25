`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/03 14:12:27
// Design Name: 
// Module Name: TOP
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


module TOP(
    input           clk,
    input           rstn,//
    input           rst,//bnc
    input           btnl,//btnl
    output          done,//led16
    output [7:0]    an,
    output [6:0]    seg,
    output [15:0]   round_count,

    input           rxd,
    output          txd
    );

    wire [31:0] sdu_addr;
    wire [31:0] sdu_data;
    wire [31:0] sdu_din;
    wire sdu_we;
    wire clk_ld;
SORT sort(
    .clk(clk),
    .rstn(rstn),//
    .rst(rst),//bnc
    .btnl(btnl),//btnl
    .done(done),//led1
    .an(an),
    .seg(seg),
    .round_count(round_count),
    .sdu_addr(sdu_addr[9:0]),//
    .sdu_data({sdu_data})
);

sdu_dm sdu_dm_inst(
    .clk(clk),
    .rstn(rstn),
    .rxd(rxd),
    .txd(txd),
    .addr(sdu_addr),//32位，我们这次使用其后10位（1024）
    .dout({sdu_data}),//32位，用于sdu查看bram内容
    .din(sdu_din),  //用于将数据加载到存储器，你可以不使用或者接入bram的写入数据
    .we(sdu_we),    //用于将数据加载到存储器，你可以不使用或者接入bram的写使能
    .clk_ld(clk_ld) //用于sdu写入数据的时钟，你可以不使用或者接入bram的用于sdu的端口时钟
);
endmodule
