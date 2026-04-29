module NPC (
    input      [ 1 : 0] npc_sel,    // 选择控制信号
    input      [31 : 0] pc_add4,    // 当前 PC + 4
    input      [31 : 0] pc_offset,  // 分支或 jal 跳转的目标地址 (PC + imm)
    input      [31 : 0] alu_res,    // ALU 计算出的 jalr 原始结果 (rs1 + imm)
    
    output reg [31 : 0] npc         // 下一个周期的 PC 值
);

    // 计算 jalr 特有的跳转目标：将最低位强制置 0
    wire [31 : 0] pc_j = {alu_res[31:1], 1'b0};

    always @(*) begin
        case (npc_sel)
            2'b00:   npc = pc_add4;   // 顺序执行
            2'b01:   npc = pc_offset; // 条件分支跳转 (B-type) 或 无条件跳转 (JAL)
            2'b10:   npc = pc_j;      // 间接跳转 (JALR)
            default: npc = pc_add4;   // 默认保持顺序执行，增强稳定性
        endcase
    end

endmodule