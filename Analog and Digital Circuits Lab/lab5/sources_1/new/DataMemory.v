`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/19 20:41:47
// Design Name: 
// Module Name: DataMemory
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


module DataMemory(//BRAM同步读写，不可异步读
    input               clk,
    input               rstn,

    input [7:0]         index,
    input               w_en,
    input [127:0]       w_data,//以块为单位写入

    output reg [127:0]  r_data//以块为单位读出
    );

    reg [127:0] memory [0:255];//128（一个块16B（128位））D,V之类的放在TagMemory

    // 硬件初始化：复位时清零所有存储单元
    integer i;
    always @(posedge clk) begin
        if (!rstn) begin
            // 复位时初始化所有存储器内容为0
            for (i = 0; i < 256; i = i + 1) begin
                memory[i] <= 128'b0;
            end
            r_data <= 128'b0;
        end
        else begin
            r_data <= memory[index];
            
            if (w_en) begin
                memory[index] <= w_data;
            end
        end
    end

endmodule
