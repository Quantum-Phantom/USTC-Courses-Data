`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 13:17:39
// Design Name: 
// Module Name: BCD
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

/*2线-4线BCD译码器*/

module BCD(
    input [3:0] d,
    output reg [9:0] y
    );

    always @(*) begin
        case(d)
            4'b0000: y=10'b0000000001;//
            4'b0001: y=10'b0000000010;//1
            4'b0010: y=10'b0000000100;//2
            4'b0011: y=10'b0000001000;//3
            4'b0100: y=10'b0000010000;//4
            4'b0101: y=10'b0000100000;//5
            4'b0110: y=10'b0001000000;//6
            4'b0111: y=10'b0010000000;//7
            4'b1000: y=10'b0100000000;//8
            4'b1001: y=10'b1000000000;//9
            default: y=10'b0000000000;
        endcase
    end
endmodule
