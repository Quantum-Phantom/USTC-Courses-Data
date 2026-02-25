`timescale 1ns / 1ps
module SORT(
    input           clk,
    input           rstn,//
    input           rst,//bnc
    input           btnl,//btnl

    output          done,//led16
    output [7:0]    an,
    output [6:0]    seg,
    output [15:0]   round_count,
    // SDU调试接口
    input  [9:0]    sdu_addr,       // 调试地址
    output [31:0]   sdu_data         // 调试数据
    );

wire start;
wire yl;
wire [1:0] f;
wire [3:0] mux_out;

//去抖动：
DEBOUNCE #(
    .TD_CYCLES(1000000)
)deb(
    .clk(clk),
    .rst(rst),
    .x(btnl),
    .y(start)
);

//排序
BUBBLESORT bubble(
    .clk(clk),
    .rstn(rstn),
    .start(start),
    .done(done),
    .round_count(round_count),

    .sdu_addr(sdu_addr),     // 调试地址
    .sdu_data(sdu_data)       // 调试数据
);

//数码管动态显示
//500Hz分频器（用于数码管扫描）
FD_divider #(
    .K(32'd199_999)            // 100MHz -> 500Hz
) fd (
    .clk(clk),
    .rst(rst),//按一下复位，然后一直开着
    .st(1'b1),                  // 常开，持续扫描
    .yp(),
    .yl(yl),                  // 500Hz扫描时钟
    .q()
);
//2位计数器（500Hz时钟驱动，用于数码管选择）
COUNT counter_500Hz (
    .clk(yl),                 // 500Hz时钟
    .rst(rst),//只要调频器复位就复位
    .f(f)                       // 2位选择信号
);

//4选1多路选择器（选择要显示的数码管位数）
MUX mux (
    .d0(round_count[3:0]),             // 个位
    .d1(round_count[7:4]),             // 十位
    .d2(round_count[11:8]),            // 百位
    .d3(round_count[15:12]),           // 千位
    .f(f),                      // 选择信号
    .d(mux_out)                 // 选择的4位数据
);
//七段译码器
SSD ssd(
                .d(mux_out),
                .cn(seg)
);
//独热码编码器（数码管位选）
OHD ohd (
    .f(f),                      // 2位选择信号
    .an(an[3:0])                     // 8位位选信号
);
assign an[7:4]=4'b1111;
endmodule
