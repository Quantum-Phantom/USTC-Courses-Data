module IfEqual(
    input [19:0]    r_tag,
    input           v,
    input [19:0]    tag,
    output reg      hit
);

always @(*) begin
    if (v && (tag == r_tag))
        hit = 1'b1;
    else
        hit = 1'b0;
end

endmodule