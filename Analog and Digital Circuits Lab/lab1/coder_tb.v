`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 20:58:18
// Design Name: 
// Module Name: coder_tb
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

module coder_tb;
    // 输入信号
    reg         e;
    reg         p;
    reg  [9:0]  x;
    reg  [3:0]  a;
    
    // 输出信号
    wire        f;
    wire [3:0]  d;
    wire [9:0]  y;
    wire [6:0]  cn;
    wire [7:0]  an;

    // 实例化被测模块
    coder dut (
        .e(e),
        .p(p),
        .x(x),
        .a(a),
        .f(f),
        .d(d),
        .y(y),
        .cn(cn),
        .an(an)
    );

    // 测试用例
    initial begin
        // 初始化
        e = 0; p = 0; x = 4'b0; a = 4'b0;
        #10
        
        // 测试用例1：编码器功能
        e = 1; p = 0; x = 10'b0000000001; a = 4'b0000;
        #10;

        // 测试用例2：多路选择器功能
        e = 0; p = 0; x = 10'b0000000000; a = 4'b1010;
        #10;

        // 测试用例3：优先级编码
        e = 1; p = 1; x = 10'b0000010100; a = 4'b0000;
        #10;

        // 测试用例4：BCD解码
        e = 0; p = 0; x = 10'b0000000000; a = 4'b0011;
        #10;

        // 测试用例5：数码管显示
        e = 0; p = 0; x = 10'b0000000000; a = 4'b0110;
        #10;
    end

    // 生成波形文件
    initial begin
        $dumpfile("coder_tb.vcd");
        $dumpvars(0, coder_tb);
    end
endmodule
