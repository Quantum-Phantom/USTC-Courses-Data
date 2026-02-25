`timescale 1ns / 1ps

module DEBOUNCE #(
    parameter TD_CYCLES = 1000000  // 10ms延时对应的时钟周期数（假设100MHz时钟）
)(
    input  clk,        // 时钟信号
    input  rst,        // 同步复位信号  
    input  x,          // 原始输入信号
    output y           // 去抖动后的输出信号
);

reg x_sync, x_sync_dly;     // 同步和延迟一拍的输入信号
reg y_reg;                  // 去抖动输出寄存器
reg [31:0] counter;        // 计数器
reg counting;              // 计数使能标志[3](@ref)
wire counter_timeout;       // 计数器超时信号

// 输入同步器（两级同步防亚稳态）
always @(posedge clk) begin
    if (rst) begin
        {x_sync_dly, x_sync} <= 2'b00;
    end else begin
        {x_sync_dly, x_sync} <= {x_sync, x};
    end
end

// 计数使能逻辑：检测到输入变化时启动计数
always @(posedge clk) begin
    if (rst) begin
        counting <= 1'b0;
    end else if (x_sync_dly != y_reg) begin
        counting <= 1'b1;  // 检测到变化，开始计数
    end else if (counter_timeout) begin
        counting <= 1'b0;  // 计数完成，停止计数
    end
end

// 计数器逻辑
always @(posedge clk) begin
    if (rst) begin
        counter <= TD_CYCLES;
    end else if (!counting) begin
        counter <= TD_CYCLES;  // 不在计数时重置计数器
    end else if (counter > 0) begin
        counter <= counter - 1; // 计数递减
    end
end

// 检测计数器是否减到0
assign counter_timeout = (counter == 0);

// 输出寄存器更新逻辑
always @(posedge clk) begin
    if (rst) begin
        y_reg <= 1'b0;
    end else if (counter_timeout && counting) begin
        y_reg <= x_sync_dly;  // 当计数器超时且正在计数时，更新输出
    end
end

// 输出赋值
assign y = y_reg;

endmodule