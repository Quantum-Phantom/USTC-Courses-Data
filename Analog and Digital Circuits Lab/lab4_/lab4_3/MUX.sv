`timescale 1ns / 1ps
module MUX(
    input  [3:0] d0,
    input  [3:0] d1,
    input  [3:0] d2,
    input  [3:0] d3,
    input  [1:0] f,
    output [3:0] d
);
reg [3:0] d_reg;
always@(*)begin
    case(f)
        2'b00:   d_reg=d0;
        2'b01:   d_reg=d1;
        2'b10:   d_reg=d2;
        2'b11:   d_reg=d3;
        default: d_reg = 4'b0;
    endcase
end
assign d=d_reg;
endmodule