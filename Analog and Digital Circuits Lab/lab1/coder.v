`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 20:21:58
// Design Name: 
// Module Name: coder
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


module coder(
    input            e, //模块声明时，input 端口必须是 wire 型变量
    input            p,
    input      [9:0] x,
    input      [3:0] a,
    output           f,
    output [3:0]     d, //模块声明时，output 端口可以是 wire 或 reg 型变量
    output [9:0]     y,
    output [6:0]     cn,
    output [7:0]     an
    );
    wire [3:0] y1;
    wire [3:0] y_enc;
    wire       f_enc;

    ECD encoder10_4(
        .e(e),
        .p(p),
        .x(x),//模块例化时，input 端口可以连接 wire 或 reg 型变量
        .f(f_enc),//模块例化时，output 端口必须连接 wire 型变量
        .y(y_enc)
    );
    assign d = y_enc;
    MUX mux(
        .a(a),
        .b(y_enc),
        .s(f_enc),
        .y(y1)
    );
    BCD decoder4_10(
        .d(y1),
        .y(y)
    );
    SSD seven_seg_decoder(
        .d(y1),
        .yn(cn)
    );
    assign f = f_enc;
    assign an = 8'b1111_1110;
endmodule
