`timescale 1ns / 1ps

module Frequency_Divider #(
    parameter K = 32'd100_000_000  // 分频系数，例如将100MHz分频为1Hz
)(
    input clk,      // 系统时钟
    input rst,      // 同步复位（高有效）
    input st,       // 启动/停止控制
    output en       // 使能信号输出（单周期脉冲）
);

// 内部信号定义
reg [31:0] counter;      // 计数器寄存器
reg [31:0] reload_value; // 重装载值寄存器
reg running;             // 运行状态标志
reg en_reg;             // 使能信号寄存器

// 同步逻辑
always @(posedge clk) begin
    if (rst) begin
        // 同步复位：所有寄存器清零
        counter <= 32'b0;
        reload_value <= K;    // 加载分频系数
        running <= 1'b0;
        en_reg <= 1'b0;
    end 
    else begin
        // 默认使能信号为0
        en_reg <= 1'b0;
        
        // 启动/停止控制
        if (st && !running)
            // 启动分频器
            running <= 1'b1;
        else if (!st && running)
            // 停止分频器
            running <= 1'b0;
        
        if (running) begin
            // 运行状态：递减计数
            if (counter > 0) begin
                counter <= counter - 1;
            end 
            else begin
                // 计数到0，重装载并产生使能脉冲
                counter <= reload_value;
                en_reg <= 1'b1;
            end
        end
        else
            // 停止状态，计数器清零
            counter <= 32'b0;
    end
end

// 输出信号生成
assign en = en_reg;           // 使能信号：单周期脉冲

endmodule