`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/29 17:30:51
// Design Name: 
// Module Name: add
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


module add(
    input        clk,    // clock (clk100mhz)
    input [7:0]  a,      // sw15-8
    input [7:0]  b,      // sw7-0
    input        ci,     // btnc
    input        rst,    // btnu (reset)
    input        en,     // btnl (enable for registers)
    output [7:0] s,      // led7-0 (registered sum)
    output       co      // led15  (registered carry-out)
    );

    // registered inputs
    wire [7:0] q_a;
    wire [7:0] q_b;
    wire       q_ci;

    // combinational sum from registered inputs
    wire [7:0] s_d;
    wire       co_d;

    // input registers: store a, b, ci on clock when en asserted (and rst)
    register #(.WIDTH(8), .RST_VAL(0)) reg_a (
        .clk(clk),
        .rst(rst),
        .en(en),
        .d(a),
        .q(q_a)
    );

    register #(.WIDTH(8), .RST_VAL(0)) reg_b (
        .clk(clk),
        .rst(rst),
        .en(en),
        .d(b),
        .q(q_b)
    );

    register #(.WIDTH(1), .RST_VAL(0)) reg_ci (
        .clk(clk),
        .rst(rst),
        .en(en),
        .d(ci),
        .q(q_ci)
    );

    // combinational adder uses the registered inputs
    assign {co_d, s_d} = q_a + q_b + q_ci;

    // output registers: capture sum and carry when en asserted
    register #(.WIDTH(8), .RST_VAL(0)) reg_s (
        .clk(clk),
        .rst(rst),
        .en(en),
        .d(s_d),
        .q(s)
    );

    register #(.WIDTH(1), .RST_VAL(0)) reg_co (
        .clk(clk),
        .rst(rst),
        .en(en),
        .d(co_d),
        .q(co)
    );

endmodule
