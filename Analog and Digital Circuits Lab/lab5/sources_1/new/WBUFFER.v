`timescale 1ns / 1ps
module WBUFFER( // 缺失重填缓冲区
    input               clk,
    input               rstn,

    input [127:0]       final_data,   //
    input               refill_ready,
    input [7:0]         index,        // 
    input [19:0]        tag,          // 
    input               way,          // 1 bit 正确

    output reg [127:0]  reg_data,
    output reg [7:0]    reg_index,
    output reg [19:0]   reg_tag,
    output reg          reg_way,
    output reg          reg_wen      // Write Buffer 有效标志（脏数据待写回
    );

    always @(posedge clk) begin
        if (!rstn) begin
            reg_data  <= 128'b0;
            reg_index <= 8'b0;
            reg_tag   <= 20'b0;
            reg_way   <= 1'b0;
            reg_wen     <= 1'b0;
        end 
        else if (refill_ready) begin
            reg_data  <= final_data;
            reg_index <= index;
            reg_tag   <= tag;
            reg_way   <= way;
            reg_wen     <= 1'b1; // 标记 Buffer 内有待写入 RAM 的数据
        end
        else begin
            reg_wen <= 1'b0; // 非重填周期，Write Buffer 无效
        end
    end
endmodule