`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/05 16:58:20
// Design Name: 
// Module Name: Equality_Comparator
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


module Equality_Comparator#(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] q,
    output ifequal
);

assign ifequal = (q==0);
endmodule
