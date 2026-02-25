`timescale 1ns / 1ps
module top(
    input           clk,        // 时钟信号
    input           rstn,      // 复位信号
    input    [15:0] sw,        // 定时器设置的周期数（16位）
    input           btnr,       // 定时器开始信号(btnr)
    input           btnl,       // 分频器开始信号(btnl)
    output   [ 7:0] an,        // 数码管位选信号
    output   [ 6:0] seg,       // 数码管段选信号
    output          td         // 定时器到时信号，接入任何一个led灯即可
);

// 内部信号定义
wire rst,rst_fd;                       // 同步复位信号
wire st;                        // 去抖动后的开始信号                     
wire [15:0] d_16;               // 数码管显示的值                                 
wire yl_2;                      // 500Hz扫描时钟
wire [1:0] f;                   // 数码管选择信号
wire [3:0] mux_out;             // 多路选择器输出

//复位处理模块
Reset reset(
    .clk(clk),
    .rstn(rstn),
    .rst(rst)
);
assign rst_fd=btnl;
//Reset reset_fd(
//  .clk(clk),
//  .rstn(btnl),
//  .rst(rst_fd)
//);
//去抖动：
Debounce #(
    .TD_CYCLES(1000000)
)deb(
    .clk(clk),
    .rst(rst),
    .x(btnr),
    .y(st)
);
//1Hz_16位计时器
Timer #(
    .K(32'd99_999_999),
    .WIDTH(16)
)timer(
    .clk(clk),
    .rst(rst),
    .rst_fd(rst_fd),
    .st(st),
    .sw(sw),
    .q(d_16),
    .td(td)
);
//500Hz分频器（用于数码管扫描）
FrequencyDivider #(
    .K(32'd199_999)            // 100MHz -> 500Hz
) FD_2 (
    .clk(clk),
    .rst(rst_fd),//按一下复位，然后一直开着
    .st(1'b1),                  // 常开，持续扫描
    .yp(),
    .yl(yl_2),                  // 500Hz扫描时钟
    .q()
);
//2位计数器（500Hz时钟驱动，用于数码管选择）
Counter_2 counter_500Hz (
    .clk(yl_2),                 // 500Hz时钟
    .rst(rst_fd),//只要调频器复位就复位
    .f(f)                       // 2位选择信号
);

//4选1多路选择器（选择要显示的数码管位数）
MUX mux (
    .d0(d_16[3:0]),             // 个位
    .d1(d_16[7:4]),             // 十位
    .d2(d_16[11:8]),            // 百位
    .d3(d_16[15:12]),           // 千位
    .f(f),                      // 选择信号
    .d(mux_out)                 // 选择的4位数据
);

//七段译码器
Segment_Decoder_7 SSD(
                .d(mux_out),
                .cn(seg)
);
//独热码编码器（数码管位选）
One_Hot_Decoder ohd (
    .f(f),                      // 2位选择信号
    .an(an[3:0])                     // 8位位选信号
);
assign an[7:4]=4'b1111;

endmodule