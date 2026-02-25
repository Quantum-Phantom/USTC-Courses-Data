`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/09 14:35:18
// Design Name: 
// Module Name: Hot_to_ASCII
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


module Hot_to_ASCII(
    input [15:0] sw,
    output reg [7:0] ascii
);
    always @(*) begin
        casez (sw) // 优先编码
          16'b0000_0000_0000_0001: ascii = 8'h30; // 0
          16'b0000_0000_0000_0010: ascii = 8'h31; // 1
          16'b0000_0000_0000_0100: ascii = 8'h32; //2
          16'b0000_0000_0000_1000: ascii = 8'h33; //3
          16'b0000_0000_0001_0000: ascii = 8'h34; //4
          16'b0000_0000_0010_0000: ascii = 8'h35; //5
          16'b0000_0000_0100_0000: ascii = 8'h36; //6
          16'b0000_0000_1000_0000: ascii = 8'h37; //7
          16'b0000_0001_0000_0000: ascii = 8'h38; //8
          16'b0000_0010_0000_0000: ascii = 8'h39; //9
          16'b0000_0100_0000_0000: ascii = 8'h41; //A
          16'b0000_1000_0000_0000: ascii = 8'h42; //B
          16'b0001_0000_0000_0000: ascii = 8'h43; //C
          16'b0010_0000_0000_0000: ascii = 8'h44; //D
          16'b0100_0000_0000_0000: ascii = 8'h45; //E
          16'b1000_0000_0000_0000: ascii = 8'h46; // F  h是十六进制。。。
          default:                 ascii = 8'h00; // 无效输入
        endcase
    end
endmodule
