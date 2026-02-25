`timescale 1ns / 1ps

module Reset(
    input  clk,        // 系统时钟
    input  rstn,       // 异步复位输入（低电平有效）
    output reg rst     // 同步复位输出（高电平有效）
);

// 使用2级同步器实现可靠的异步复位、同步释放
reg [1:0] rst_sync_pipe;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        // 异步复位：立即将同步管道置为全1
        rst_sync_pipe <= 2'b11;
    end else begin
        // 同步释放：通过管道传递0
        rst_sync_pipe <= {rst_sync_pipe[0], 1'b0};
    end
end

// 生成同步复位信号
always @(posedge clk) begin
    rst <= rst_sync_pipe[1];  // 使用第二级同步信号
end

endmodule