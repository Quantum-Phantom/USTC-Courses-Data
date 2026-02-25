`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 13:17:39
// Design Name: 
// Module Name: SSD
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


module SSD (
    input       [3:0] d,
    output reg  [6:0] yn//yn表示低电平有效，七段字形a, b, … g依次对应y[6], y[5], … y[0]
    );

    always @(*) begin
        case(d)
            4'b0000: yn=7'b00_00001;//0
            4'b0001: yn=7'b100_1111;//1
            4'b0010: yn=7'b001_0010;//2
            4'b0011: yn=7'b000_0110;//3
            4'b0100: yn=7'b100_1100;//4
            4'b0101: yn=7'b010_0100;//5
            4'b0110: yn=7'b010_0000;//6
            4'b0111: yn=7'b000_1111;//7
            4'b1000: yn=7'b000_0000;//8
            4'b1001: yn=7'b000_0100;//9
            default: yn=7'b111_1111;
    endcase
    end
endmodule
