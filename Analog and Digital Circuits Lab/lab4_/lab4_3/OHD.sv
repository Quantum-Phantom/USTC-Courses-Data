`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/03 13:34:52
// Design Name: 
// Module Name: OHD
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


module OHD(
    input      [1:0] f,
    output reg [3:0] an
    );
    always @(*) begin
        case(f)
            2'h0:   an=4'b1110;//
            2'h1:   an=4'b1101;//
            2'h2:   an=4'b1011;//
            2'h3:   an=4'b0111;//
            default:an=4'b1111;
        endcase
    end
endmodule
