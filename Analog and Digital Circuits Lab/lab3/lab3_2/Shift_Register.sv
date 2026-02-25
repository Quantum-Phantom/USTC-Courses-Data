`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/09 14:55:25
// Design Name: 
// Module Name: Shift_Register
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


module Shift_Register(
    input [7:0] din,//data in
    input       tx_vld,//valid
    input       tx_rdy,//来自count
    input       en,//分频后得到的使能
    input       clk,//系统自带时钟
    input       rst,//系统自带复位信号必须的样子
    output      txd//receive data
    );
    reg [9:0] dout;
    always @(posedge clk) begin
        if(rst)
            dout<=10'b11_1111_1111;
        else if(en)begin
            if(tx_vld&&tx_rdy)begin
                dout<={1'b1,din[7:0],1'b0};
            end
            else if(!tx_rdy)begin
                dout<={1'b1,dout[9:1]};
            end
        end 
        else
            dout<=dout;
    end
    assign txd=dout[0];
endmodule
