`timescale 1ns / 1ps
module FSM #(
    parameter RST_VLU = 0
)(
    input  st,       // 开始信号
    input  rst,      // 同步复位信号 (高电平有效)
    input  clk,      // 时钟
    input  ifequal,  // 比较器结果 (1: 计数完成, 0: 计数未完成)
    output pe,       // 置数使能 (两段式输出)
    output ce,       // 计数使能 (两段式输出)
    output td        // 定时完成信号 (三段式输出)
);

// 状态定义：使用宏定义或局部参数提高可读性
localparam S_IDLE = 2'b00; // 空闲/复位状态
localparam S_LOAD = 2'b01; // 置数状态
localparam S_COUNT = 2'b10; // 计数状态

reg [1:0] cs, ns; // 当前状态 (Current State), 下一状态 (Next State)
reg pe_comb, ce_comb; // 用于两段式输出的组合逻辑寄存器
reg td_next; // 用于三段式输出的下一拍信号

// 第一段：状态寄存器 (时序逻辑)
always@(posedge clk) begin
    if (rst) cs <= RST_VLU; 
    else cs <= ns;
end

// 第二段：下一状态逻辑 & 两段式输出逻辑 (组合逻辑)
always_comb begin
    // 默认值：保持状态，输出无效
    ns = cs;
    pe_comb = 1'b0;
    ce_comb = 1'b0;
    td_next = 1'b1; // 注意：这是td下一周期的值

    case (cs)
        S_IDLE: begin
            if (st && ifequal) begin // 收到开始信号且为0，开始计数
                ns = S_LOAD;
                pe_comb = 1'b1; // 准备置数
                td_next=1'b0;
            end
            else// 否则停留在 S_IDLE
                td_next = 1'b1; // 空闲状态下td为1
        end

        S_LOAD: begin
            // 置数状态通常只持续一个周期，然后进入计数状态
            ns = S_COUNT;
            ce_comb = 1'b1; // 开始计数
            td_next = 1'b0;
        end

        S_COUNT: begin
            if (ifequal) begin
                // 计数完成，回到空闲状态
                ns = S_IDLE;
                ce_comb = 1'b0; // 停止计数
                td_next = 1'b1; // 下一个时钟周期td拉高
            end else begin
                // 计数未完成，继续计数
                ns = S_COUNT;
                ce_comb = 1'b1; // 继续计数
                td_next = 1'b0;
            end
        end

        default: begin // 避免生成锁存器
            ns = S_IDLE;
            td_next = 1'b1;
        end
    endcase
end

// 第三段：三段式输出寄存器 (时序逻辑)
reg td_reg;
always_ff @(posedge clk) begin
    if (rst) begin
        td_reg <= 1'b1; // 复位时td为0
    end else begin
        td_reg <= td_next; // 将组合逻辑计算出的下一拍值寄存输出
    end
end

// 输出赋值
assign pe = pe_comb;
assign ce = ce_comb;
assign td = td_reg;

endmodule