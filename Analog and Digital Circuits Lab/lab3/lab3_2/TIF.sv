module TIF(
    input       clk,
    input       rst,
    input [7:0] din,
    input       tx_vld,//通过它置0让计数器初始化吧
    output      tx_rdy,
    output      txd
);
wire en;
wire we_tx;
wire tx_vld_1;//取边沿后结果
assign we_tx=tx_rdy&&tx_vld_1;

Frequency_Divider#(
    .K(32'd10416)//d表示十进制 10416
)fd
(
    .clk(clk),
    .rst(rst),
    .st(1'b1),
    .en(en)
);
GET_Edge getedge(
    .clk(en),
    .rst(rst),
    .din(tx_vld),
    .dout_pulse(tx_vld_1)
);

Count cnt(//计数器的时钟可以用调频后的频率吧
    .clk(en),//所以复位的时候，rdy不会置1
    .rst(rst),
    .we_tx(we_tx),
    .cnt_out(),
    .rdy(tx_rdy)
);
Shift_Register shs(
    .din(din),
    .tx_vld(tx_vld_1),
    .tx_rdy(tx_rdy),
    .en(en),
    .clk(clk),
    .rst(rst),
    .txd(txd)
);


endmodule