module COUNT(
    input            clk,
    input            rst,    // 复位信号,好怪哎，加上复位就不报错了
    output reg [1:0] f
);
    always @(posedge clk) begin
        if (rst)
            f <= 2'b11;      // 复位时设为3
        else if (f > 0)
            f <= f - 1;
        else
            f <= 2'b11;      // 循环计数
    end
endmodule