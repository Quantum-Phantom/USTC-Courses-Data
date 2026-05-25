module PC (
    input                     clk,    
    input                     rst,    
    input                     en,     // 由 PDU 控制是否允许 PC 更新
    input      [31:0]         npc,    // Next PC
    output reg [31:0]         pc      // 当前指令的地址
);

    localparam RESET_ADDR = 32'h0040_0000;  //RV32I起始地址

    always @(posedge clk) begin
        if (rst) begin
            pc <= RESET_ADDR;
        end
        else if (en) begin
            pc <= npc;
        end
    end

endmodule