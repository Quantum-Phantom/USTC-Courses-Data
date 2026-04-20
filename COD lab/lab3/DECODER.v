module DECODER (
    input  [31 : 0] inst,

    output reg  [ 4 : 0]    alu_op, //ALU 的运算模式码
    output      [31 : 0]    imm,    //扩展的立即数
    output      [ 4 : 0]    rf_ra0,
    output      [ 4 : 0]    rf_ra1,
    output      [ 4 : 0]    rf_wa,
    output      [ 0 : 0]    rf_we,
    output      [ 0 : 0]    alu_src0_sel,   //ALU 的源操作数选择信号
    output      [ 0 : 0]    alu_src1_sel    //ALU 的源操作数选择信号
);

    localparam OP_ADD  = 5'b00000;
    localparam OP_SUB  = 5'b00010;
    localparam OP_SLT  = 5'b00100;
    localparam OP_SLTU = 5'b00101;
    localparam OP_AND  = 5'b01001;
    localparam OP_OR   = 5'b01010;
    localparam OP_XOR  = 5'b01011;
    localparam OP_SLL  = 5'b01110;
    localparam OP_SRL  = 5'b01111;
    localparam OP_SRA  = 5'b10000;

    wire [6:0] opcode = inst[6:0];
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];

    wire is_rtype = (opcode == 7'b0110011); // add, sub, and, etc.
    wire is_itype = (opcode == 7'b0010011); // addi, andi, slli, etc.
    wire is_lui   = (opcode == 7'b0110111); // lui加载高20位立即数
    wire is_auipc = (opcode == 7'b0010111); // auipc加载加上pc的高20位立即数

    wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};  //I-type符号位扩展
    wire [31:0] imm_u = {inst[31:12], 12'b0};   //U-type符号位扩展

    assign imm = (is_lui | is_auipc) ? imm_u : imm_i;

    assign rf_ra0 = (is_lui) ? 5'b00000 : inst[19:15];  //rs1
    assign rf_ra1 = inst[24:20];    //rs2
    assign rf_wa  = inst[11:7];     //rd
    
    assign rf_we  = (is_rtype | is_itype | is_lui | is_auipc);

    assign alu_src0_sel = is_auipc; //除auipc选pc的值，默认寄存器值
    assign alu_src1_sel = is_itype | is_lui | is_auipc;

    always @(*) begin
        alu_op = OP_ADD; // 默认设置为加法，适配 lui 和 auipc 的需求

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
                3'b000: alu_op = OP_ADD; // addi
                3'b001: alu_op = OP_SLL; // slli
                3'b010: alu_op = OP_SLT; // slti
                3'b011: alu_op = OP_SLTU; // sltiu
                3'b100: alu_op = OP_XOR; // xori
                3'b101: alu_op = (funct7[5]) ? OP_SRA : OP_SRL; // srli/srai
                3'b110: alu_op = OP_OR;  // ori
                3'b111: alu_op = OP_AND; // andi
            endcase
        end
        // else: lui 和 auipc 会保持默认值 OP_ADD
    end

endmodule