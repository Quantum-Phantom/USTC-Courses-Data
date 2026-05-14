module stage_reg #(
    parameter WIDTH = 32
)(
    input  wire              clk,    // 时钟
    input  wire              rst,    // 同步清空（复位）
    input  wire              en,     // 全局使能 (连接到 global_en)
    input  wire              flush,  // 流水线清空 (同步清空)
    input  wire              stall,  // 流水线停驻 (保持原值)
    input  wire [WIDTH-1:0]  data_in,
    output reg  [WIDTH-1:0]  data_out
);

    always @(posedge clk) begin
        if (rst) begin
            data_out <= {WIDTH{1'b0}};
        end
        else if (en) begin
            if (flush) begin
                data_out <= {WIDTH{1'b0}}; //nop 指令
            end
            else if (stall) begin
                data_out <= data_out;   // stall 为高电平时，输出保持不变
            end
            else begin
                data_out <= data_in;
            end
        end
    end

endmodule