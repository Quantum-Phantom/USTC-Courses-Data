`timescale 1ns / 1ps

module RF (
    input           clk,
    input           rstn,
    
    input           we,             // 写使能
    input  [3:0]    wa,             // 写地址（4位，0-15）
    input  [15:0]   wd,             // 写数据
    
    input  [3:0]    ra0,            // 读地址0（队头指针）
    output [15:0]   rd0,            // 读数据0（出队数据）
    
    input  [3:0]    ra1,            // 读地址1（调试地址）
    output [15:0]   rd1             // 读数据1（调试数据）
);

// 寄存器堆：16个16位寄存器
reg [15:0] rf [0:15];

// 读优先设计：读写地址冲突时，读出的仍是旧数据
assign rd0 = rf[ra0];
assign rd1 = rf[ra1];

always @(posedge clk) begin
    integer i; // 循环变量
    if (!rstn) begin
        // 使用for循环对所有寄存器进行复位
        for (i = 0; i < 16; i = i + 1) begin
            rf[i] <= 16'b0;
        end
    end 
    else if (we) begin
        rf[wa] <= wd;
    end
end
endmodule