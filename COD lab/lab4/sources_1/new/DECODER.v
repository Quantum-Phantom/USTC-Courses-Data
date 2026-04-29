module DECODER (
    input  [31 : 0] inst,

    output reg [ 4 : 0] alu_op,         // ALU 的运算模式码
    output     [31 : 0] imm,            // 扩展的立即数

    output     [ 4 : 0] rf_ra0,
    output     [ 4 : 0] rf_ra1,
    output     [ 4 : 0] rf_wa,
    output     [ 0 : 0] rf_we,
    output     [ 1 : 0] rf_wd_sel,      // 写回选择: 0-ALU, 1-Mem, 2-PC+4

    output     [ 0 : 0] alu_src0_sel,   // 0-reg, 1-pc
    output     [ 0 : 0] alu_src1_sel,   // 0-reg, 1-imm

    output reg [ 3 : 0] dmem_access,    // 传给 SLU 的访存类型
    output reg [ 3 : 0] br_type         // 传给 Branch 模块的类型
);

    // ALU Op Localparams
    localparam OP_ADD  = 5'b00000, OP_SUB  = 5'b00010, OP_SLT  = 5'b00100;
    localparam OP_SLTU = 5'b00101, OP_AND  = 5'b01001, OP_OR   = 5'b01010;
    localparam OP_XOR  = 5'b01011, OP_SLL  = 5'b01110, OP_SRL  = 5'b01111;
    localparam OP_SRA  = 5'b10000;

    // 译码基础信号
    wire [6:0] opcode = inst[6:0];
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];

    // 指令分类判定
    wire is_rtype  = (opcode == 7'b0110011); 
    wire is_itype  = (opcode == 7'b0010011); 
    wire is_lui    = (opcode == 7'b0110111); 
    wire is_auipc  = (opcode == 7'b0010111); 
    wire is_load   = (opcode == 7'b0000011); // lw, lb, lh, lbu, lhu
    wire is_store  = (opcode == 7'b0100011); // sw, sb, sh
    wire is_branch = (opcode == 7'b1100011); // beq, bne,blt,bge,bltu,bgeu
    wire is_jal    = (opcode == 7'b1101111); // jal
    wire is_jalr   = (opcode == 7'b1100111); // jalr

    // 立即数生成 (涵盖所有格式)
    wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
    wire [31:0] imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    wire [31:0] imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}; //branch
    wire [31:0] imm_u = {inst[31:12], 12'b0};   //lui,auipc
    wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};   //jal

    assign imm = is_lui | is_auipc ? imm_u :
                 is_load | is_itype | is_jalr ? imm_i :
                 is_store ? imm_s :
                 is_branch ? imm_b :
                 is_jal ? imm_j : 32'b0;

    // 寄存器接口
    assign rf_ra0 = (is_lui) ? 5'b00000 : inst[19:15];  //rs1
    assign rf_ra1 = inst[24:20];    //rs2,R、S、B-type中rs2位置固定
    assign rf_wa  = inst[11:7];
    assign rf_we  = (is_rtype | is_itype | is_lui | is_auipc | is_load | is_jal | is_jalr);

    //ALU 输入操作数选择
    assign alu_src0_sel = (is_auipc | is_jal | is_branch); // 1时选PC
    assign alu_src1_sel = (is_itype | is_lui | is_auipc | is_load | is_store | is_jal | is_jalr); //1时选imm
    
    // 写回来源选择: 0-ALU结果, 1-存储器读出数据, 2-PC+4(用于跳转链接)
    assign rf_wd_sel = is_load ? 2'b01 : 
                       (is_jal | is_jalr) ? 2'b10 : 2'b00;

    // ALU 操作码控制
    always @(*) begin
        alu_op = OP_ADD; // 默认加法 (适用于 Load/Store 地址计算、LUI、AUIPC、JAL/JALR)
        if (is_rtype) begin
            case (funct3)
                3'b000: alu_op = (funct7[5]) ? OP_SUB : OP_ADD;
                3'b001: alu_op = OP_SLL;
                3'b010: alu_op = OP_SLT;
                3'b011: alu_op = OP_SLTU;
                3'b100: alu_op = OP_XOR;
                3'b101: alu_op = (funct7[5]) ? OP_SRA : OP_SRL;
                3'b110: alu_op = OP_OR;
                3'b111: alu_op = OP_AND;
            endcase
        end
        else if (is_itype) begin
            case (funct3)
                3'b000: alu_op = OP_ADD;
                3'b001: alu_op = OP_SLL;
                3'b010: alu_op = OP_SLT;
                3'b011: alu_op = OP_SLTU;
                3'b100: alu_op = OP_XOR;
                3'b101: alu_op = (funct7[5]) ? OP_SRA : OP_SRL;
                3'b110: alu_op = OP_OR;
                3'b111: alu_op = OP_AND;
            endcase
        end
    end

    // 访存类型 (配合你之前的 SLU 模块编码)
    always @(*) begin
        if (is_load) begin
            case (funct3)
                3'b000: dmem_access = 4'b0001; // LB
                3'b001: dmem_access = 4'b0010; // LH
                3'b010: dmem_access = 4'b0011; // LW
                3'b100: dmem_access = 4'b0100; // LBU
                3'b101: dmem_access = 4'b0101; // LHU
                default: dmem_access = 4'b0000;
            endcase
        end
        else if (is_store) begin
            case (funct3)
                3'b000: dmem_access = 4'b1001; // SB
                3'b001: dmem_access = 4'b1010; // SH
                3'b010: dmem_access = 4'b1011; // SW
                default: dmem_access = 4'b0000;
            endcase
        end
        else dmem_access = 4'b0000;
    end

    // 分支/跳转类型
    always @(*) begin
        if (is_branch) begin
            case (funct3)
                3'b000: br_type = 4'b0001; // BEQ
                3'b001: br_type = 4'b0010; // BNE
                3'b100: br_type = 4'b0011; // BLT
                3'b101: br_type = 4'b0100; // BGE
                3'b110: br_type = 4'b0101; // BLTU
                3'b111: br_type = 4'b0110; // BGEU
                default: br_type = 4'b0000;
            endcase
        end
        else if (is_jal)  br_type = 4'b1000; // JAL
        else if (is_jalr) br_type = 4'b1001; // JALR
        else br_type = 4'b0000;
    end

endmodule