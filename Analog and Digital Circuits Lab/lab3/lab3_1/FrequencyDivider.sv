`timescale 1ns / 1ps
module FrequencyDivider #(
    parameter K = 32'd100_000_000  // 分频系数，例如将100MHz分频为1Hz
)(
    input clk,      // 系统时钟
    input rst,      // 同步复位（高有效）
    input st,       // 启动/停止控制
    output yp,      // 脉冲输出（窄脉冲）
    output yl,      // 方波输出（占空比~50%）
    output [31:0] q // 计数器值（可选，用于监控）
);

// 内部信号定义
reg [31:0] counter;      // 计数器寄存器
reg [31:0] reload_value; // 重装载值寄存器
reg running;             // 运行状态标志
reg yl_reg;             // 方波输出寄存器
wire counter_timeout;    // 计数器超时信号

// 同步复位逻辑
always @(posedge clk) begin
    if (rst) begin
        // 同步复位：所有寄存器清零
        counter <= 32'b0;
        reload_value <= K;    // 加载分频系数
        running <= 1'b0;
        yl_reg <= 1'b0;
    end 
    else begin
        // 正常操作
        if (st && !running) begin
            // 启动分频器
            running <= 1'b1;
            counter <= reload_value;
            yl_reg <= 1'b0;
        end 
        else if (running) begin
            // 运行状态：递减计数
            if (counter > 0) begin
                counter <= counter - 1;
                
                // 生成方波输出（占空比约50% y1&yp周期相同哎）
                if (counter <= (reload_value >> 1)) begin//超过k一半
                    yl_reg <= 1'b1;
                end 
                else begin
                    yl_reg <= 1'b0;
                end
            end 
            else begin
                // 计数到0，自动重装载
                counter <= reload_value;
            end
        end 
        else if (!st) begin
            // 停止信号
            running <= 1'b0;
        end
    end
end

// 计数器超时检测（计数到0时产生脉冲）
assign counter_timeout = (counter == 0) && running;

// 输出信号生成
assign yp = counter_timeout;  // 脉冲输出：每个周期结束时产生一个时钟脉冲
assign yl = yl_reg;          // 方波输出：占空比约50%
assign q = counter;           // 计数器当前值输出

endmodule