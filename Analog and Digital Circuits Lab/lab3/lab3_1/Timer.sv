`timescale 1ns / 1ps
module Timer #(
    parameter K=32'd99_999_999,
              WIDTH=16
)(
    input              clk,
    input              rst,
    input              st,
    input              rst_fd,
    input  [WIDTH-1:0] sw,  // 开关输入
    output [WIDTH-1:0] q,
    output             td
);
//
wire yl_1;
wire pe,ce,ifequal;
//调频至1Hz（计时器）
FrequencyDivider #(
    .K(K)  // 分频系数，例如将100MHz分频为1Hz
)FD_1(
    .clk(clk),
    .rst(rst_fd),
    .st(1'b1),
    .yp(),
    .yl(yl_1),
    .q()
);
//WIDTH位计时器
Counter #(
    .WIDTH(WIDTH)
)counter_1Hz(
        .clk(yl_1),
        .rst(rst),
        .pe(pe),
        .ce(ce),
        .d(sw),
        .q(q)
);
FSM #(
    .RST_VLU(0)
)fsm(
    .st(st),
    .rst(rst),
    .clk(yl_1),
    .ifequal(ifequal),  
    .pe(pe),
    .ce(ce),
    .td(td)
);
Equality_Comparator #(
    .WIDTH(WIDTH)
) equ (
    .q(q),
    .ifequal(ifequal)
);
endmodule