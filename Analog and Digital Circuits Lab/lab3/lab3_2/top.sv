module top(
    input [15:0] sw,
    input       rst,
    input       clk,
    input       btnl,//tx_vld
    output      rdy,
    output      txd
);
wire [7:0] ascii;
wire       tx_vld;
Hot_to_ASCII hta(
    .sw(sw),
    .ascii(ascii)
);

DEBOUNCE #(
    .TD_CYCLES(1000000)
)decounce(
    .clk(clk),
    .rst(rst),
    .x(btnl),
    .y(tx_vld)
);

TIF tif(
    .clk(clk),
    .rst(rst),
    .din(ascii),
    .tx_vld(tx_vld),
    .tx_rdy(rdy),
    .txd(txd)
);
endmodule