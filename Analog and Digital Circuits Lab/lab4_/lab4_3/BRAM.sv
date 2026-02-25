`timescale 1ns / 1ps

module BRAM (
    input               clk,
    input               rstn,

    input               bram_we,        // 写使能（与BUBBLE对应）
    input  [9:0]        bram_addr,      // 地址（与BUBBLE对应）
    input  [31:0]       bram_din,       // 写数据（与BUBBLE对应）
    output [31:0]   bram_dout,      // 读数据（与BUBBLE对应）
    
    // 调试接口
    input  [9:0]        debug_addr,     // 调试读地址
    output [31:0]   debug_data      // 调试读数据
);

// 寄存器堆：1024个32位寄存器
reg [31:0] bram [0:1023];

initial begin
    $readmemh("E:/CoursesData/AnalogandDigitalCircuitsLab/lab4_3/check_example.hex", bram);
end

always @(posedge clk) begin
        if (bram_we) 
            bram[bram_addr] <= bram_din;    // 后写新数据
end
assign bram_dout = bram[bram_addr];
assign debug_data = bram[debug_addr];

endmodule