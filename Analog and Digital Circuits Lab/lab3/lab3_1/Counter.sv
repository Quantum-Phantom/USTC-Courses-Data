`timescale 1ns / 1ps
module  Counter #(
    parameter WIDTH = 32
)(
    input clk, rst, 
    input pe, ce, 
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk) begin
        if (rst)  q <= 0;
        else if (pe)  q <= d;
        else if (ce)  q <= q - 1; 
    end
endmodule