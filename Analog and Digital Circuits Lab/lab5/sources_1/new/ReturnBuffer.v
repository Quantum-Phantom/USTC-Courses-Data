`timescale 1ns / 1ps

module ReturnBuffer (
    input               clk,
    input               rstn,
    input               miss_start,     // 用于清空计数器和准备好信号

    // AXI 接口
    input               ret_valid,      // 数据有效信号
    input       [31:0]  ret_data,       // 32位数据
    input               ret_last,       // 结束标识

    // 来自 Request Buffer 的保存信息
    input               op,             // 1 为写操作，0 为读操作
    input       [3:0]   offset,         // 块内偏移
    input       [31:0]  wdata,          // CPU 想要写入的数据
    input       [3:0]   wstrb,          // 字节写使能

    // 输出给 Cache RAM
    output reg  [1:0]   ret_cnt,        // 已返回数据计数
    output reg  [127:0] final_data,     // 最终拼好的128位行
    output reg          refill_ready    // 重填就绪信号
);

    reg [31:0] data_storage [3:0];      // 存储 AXI 返回的原始数据
    wire [1:0] target_bank = offset[3:2];

    always @(posedge clk) begin
        if (!rstn || miss_start) begin
            ret_cnt <= 2'b00;
        end 
        else if (ret_valid) begin
            data_storage[ret_cnt] <= ret_data;
            ret_cnt <= ret_cnt + 1'b1;
        end
    end

    always @(posedge clk) begin
        if (!rstn) 
            refill_ready <= 1'b0;
        else if (ret_valid && (ret_last == 1'b1))
            refill_ready <= 1'b1;
        else 
            refill_ready <= 1'b0;
     end

    always @(*) begin
        final_data = {data_storage[3], data_storage[2], data_storage[1], data_storage[0]};
        
        if (op) begin
            case (target_bank)
                2'b00: begin
                    if (wstrb[0]) final_data[ 7: 0] = wdata[ 7: 0];
                    if (wstrb[1]) final_data[15: 8] = wdata[15: 8];
                    if (wstrb[2]) final_data[23:16] = wdata[23:16];
                    if (wstrb[3]) final_data[31:24] = wdata[31:24];
                end
                2'b01: begin
                    if (wstrb[0]) final_data[39:32] = wdata[ 7: 0];
                    if (wstrb[1]) final_data[47:40] = wdata[15: 8];
                    if (wstrb[2]) final_data[55:48] = wdata[23:16];
                    if (wstrb[3]) final_data[63:56] = wdata[31:24];
                end
                2'b10: begin
                    if (wstrb[0]) final_data[71:64] = wdata[ 7: 0];
                    if (wstrb[1]) final_data[79:72] = wdata[15: 8];
                    if (wstrb[2]) final_data[87:80] = wdata[23:16];
                    if (wstrb[3]) final_data[95:88] = wdata[31:24];
                end
                2'b11: begin
                    if (wstrb[0]) final_data[103: 96] = wdata[ 7: 0];
                    if (wstrb[1]) final_data[111:104] = wdata[15: 8];
                    if (wstrb[2]) final_data[119:112] = wdata[23:16];
                    if (wstrb[3]) final_data[127:120] = wdata[31:24];
                end
                default: ;
            endcase
        end
    end

endmodule