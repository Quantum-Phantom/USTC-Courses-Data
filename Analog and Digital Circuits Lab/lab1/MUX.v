`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 13:17:39
// Design Name: 
// Module Name: MUX
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


module MUX(
    input       [3:0] a,
    input       [3:0] b,
    input             s,
    output reg  [3:0] y
    );
    
    always @(*) begin
        case(s)
            1'b0: y=a;
            1'b1: y=b;
        endcase
    end
endmodule
