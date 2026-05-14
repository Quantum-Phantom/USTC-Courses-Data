module BRANCH (
    input      [ 3 : 0] br_type,   // 由 DECODER 生成的分支/跳转类型
    input      [31 : 0] br_src0,    // 寄存器 rs1 的值
    input      [31 : 0] br_src1,    // 寄存器 rs2 的值
    output reg [ 1 : 0] npc_sel    // 0: PC+4, 1: Branch/Jal Target, 2: Jalr Target
);

    // 对应 DECODER 中定义的编码 (请务必保持一致)
    localparam NO_BR = 4'b0000;
    localparam BEQ   = 4'b0001;
    localparam BNE   = 4'b0010;
    localparam BLT   = 4'b0011;
    localparam BGE   = 4'b0100;
    localparam BLTU  = 4'b0101;
    localparam BGEU  = 4'b0110;
    localparam JAL   = 4'b1000;
    localparam JALR  = 4'b1001;

    // 为了方便有符号比较，将输入转换为有符号类型
    wire signed [31:0] s_src0 = br_src0;
    wire signed [31:0] s_src1 = br_src1;

    always @(*) begin
        // 默认不跳转，执行顺序执行 (PC + 4)
        npc_sel = 2'b00; 

        case (br_type)
            BEQ:  if (br_src0 == br_src1) npc_sel = 2'b01;
            BNE:  if (br_src0 != br_src1) npc_sel = 2'b01;
            
            // 有符号比较
            BLT:  if (s_src0  <  s_src1)  npc_sel = 2'b01;
            BGE:  if (s_src0  >= s_src1)  npc_sel = 2'b01;
            
            // 无符号比较
            BLTU: if (br_src0 <  br_src1) npc_sel = 2'b01;
            BGEU: if (br_src0 >= br_src1) npc_sel = 2'b01;

            // 无条件跳转 (J-type)
            JAL:  npc_sel = 2'b01; // 跳转到 PC + imm
            JALR: npc_sel = 2'b10; // 跳转到 rs1 + imm (通常 npc_sel=2 对应单独的路径)

            default: npc_sel = 2'b00;
        endcase
    end

endmodule