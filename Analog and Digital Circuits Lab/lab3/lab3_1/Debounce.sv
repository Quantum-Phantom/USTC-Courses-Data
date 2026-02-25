`timescale 1ns / 1ps
module Debounce #(
    parameter TD_CYCLES = 1000000  // 10ms延时对应的时钟周期数
)(
    input  clk,        // 时钟信号
    input  rst,        // 同步复位信号  
    input  x,          // 原始输入信号
    output y           // 去抖动后的输出信号
);

reg x_sync, x_sync_dly;     // 同步和延迟一拍的输入信号
reg y_reg;                  // 去抖动输出寄存器
reg [31:0] counter;        // 计数器
wire counter_timeout;       // 计数器超时信号

// 输入同步器（两级同步防亚稳态）
always @(posedge clk) begin
    if (rst) begin
        {x_sync_dly, x_sync} <= 2'b00;
    end else begin
        {x_sync_dly, x_sync} <= {x_sync, x};
    end
end

// 计数器逻辑：使用延迟一拍的信号避免组合环路
always @(posedge clk) begin
    if (rst) begin
        counter <= TD_CYCLES;
    end else if (y_reg == x_sync_dly) begin  // 使用x_sync_dly而非x_sync
        counter <= TD_CYCLES;  // 若y=x，计数器置常数(N)
    end else if (counter > 0) begin
        counter <= counter - 1; // 若y≠x，计数器递减计数
    end
    // counter==0时保持0值不变
end

// 检测计数器是否减到0
assign counter_timeout = (counter == 0);

// 输出寄存器更新逻辑
always @(posedge clk) begin
    if (rst) begin
        y_reg <= 1'b0;
    end else if (counter_timeout) begin
        y_reg <= x_sync;  // 当计数器计数到0时，y <= x
    end
end

// 输出赋值
assign y = y_reg;

endmodule