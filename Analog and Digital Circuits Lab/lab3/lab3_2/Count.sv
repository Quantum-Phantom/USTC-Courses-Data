`timescale 1ns / 1ps

module Count(
    input            clk,          // 时钟信号
    input            rst,          // 复位信号
    input            we_tx,        // 写使能信号（来自SHR）
    output reg [3:0] cnt_out, // 4位计数器输出
    output reg       rdy
);

    always @(posedge clk) begin
        if (rst) begin
            cnt_out <= 4'b0000;
            rdy<=1;
        end 
        else if (we_tx) begin
            cnt_out <= 4'b1000; // 8的二进制表示
            rdy<=0;
        end 
        else if (cnt_out != 4'b0000) begin
            cnt_out <= cnt_out - 1;
            rdy<=0;
        end
        else begin
            cnt_out <= 4'b0000;
            rdy<=1;
        end 
    end

endmodule