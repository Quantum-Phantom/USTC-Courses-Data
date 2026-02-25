`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 13:17:39
// Design Name: 
// Module Name: ECD
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


module ECD(
    input           e,//使能，等于1时，对x进行编码
    input           p,//优先，0-普通，1-优先，优先时x[9], x[8], …, x[0]优先级依次降低
    input      [9:0]x,//
    output reg      f,//标志，等于1时，指示y为有效的编码
    output reg [3:0]y
    );

    always @(*) begin//别落下*
        if(e==0)begin
            f=1'b0;
            y=4'b0000;
        end
        else begin
            if(p==0)//普通译码器
                case(x)
                    10'b0000000001: begin y=4'b0000;  f=1'b1; end//0
                    10'b0000000010: begin y=4'b0001;  f=1'b1; end//1
                    10'b0000000100: begin y=4'b0010;  f=1'b1; end//2
                    10'b0000001000: begin y=4'b0011;  f=1'b1; end//3
                    10'b0000010000: begin y=4'b0100;  f=1'b1; end//4
                    10'b0000100000: begin y=4'b0101;  f=1'b1; end//5
                    10'b0001000000: begin y=4'b0110;  f=1'b1; end//6
                    10'b0010000000: begin y=4'b0111;  f=1'b1; end//7
                    10'b0100000000: begin y=4'b1000;  f=1'b1; end//8
                    10'b1000000000: begin y=4'b1001;  f=1'b1; end//9
                    default:        begin y=4'b0000;  f=1'b0; end
                endcase    
            else//优先译码器
                if(x[9]==1)       begin y=4'b1001;  f=1'b1; end//9
                else if(x[8]==1)  begin y=4'b1000;  f=1'b1; end//8
                else if(x[7]==1)  begin y=4'b0111;  f=1'b1; end//7
                else if(x[6]==1)  begin y=4'b0110;  f=1'b1; end//6
                else if(x[5]==1)  begin y=4'b0101;  f=1'b1; end//5
                else if(x[4]==1)  begin y=4'b0100;  f=1'b1; end//4
                else if(x[3]==1)  begin y=4'b0011;  f=1'b1; end//3
                else if(x[2]==1)  begin y=4'b0010;  f=1'b1; end//2
                else if(x[1]==1)  begin y=4'b0001;  f=1'b1; end//1
                else if(x[0]==1)  begin y=4'b0000;  f=1'b1; end//0
                else              begin y=4'b0000;  f=1'b0; end
        end
    end
endmodule
