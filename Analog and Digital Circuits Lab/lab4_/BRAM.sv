`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/26 09:55:56
// Design Name: 
// Module Name: BRAM
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


module BRAM#(
    parameter INIT_FILE = "E:\\CoursesData\\AnalogandDigitalCircuitsLab\\lab4_1\\BRAM.hex"  // 双反斜杠
)(
    input [4:0] addr,     // 地址总线：深度32需要5位地址线(2^5=32)
    input [15:0] din,     // 输入数据：16位宽度
    input clk,            // 时钟
    input we,             // 写使能
    output [15:0] dout    // 输出数据：16位宽度
    );
    
    (*ram_style="block"*)// 使用Block RAM实现，深度32，宽度16
    reg [15:0] BRAM [31:0];  // 32个深度，每个16位

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, BRAM);  // 加载hex文件
        end else begin
            // 备用初始化
            for (integer i = 0; i < 32; i = i + 1)
                BRAM[i] = 16'b0;
        end
    end

    // 单端口RAM操作
    always @(posedge clk) begin
        if (we) begin
            // 写操作：当时钟上升沿且we=1时，将din写入addr地址
            BRAM[addr] <= din;
        end
    end

    // 无寄存器输出：直接异步读取当前地址的数据
    assign dout = BRAM[addr];

endmodule

