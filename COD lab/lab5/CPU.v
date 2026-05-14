module CPU (
    input  wire        clk,
    input  wire        rst,
    input  wire        global_en,

    output wire [31:0] imem_raddr,
    input  wire [31:0] imem_rdata,

    input  wire [31:0] dmem_rdata,
    output wire        dmem_we,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,

    output wire        commit,
    output wire [31:0] commit_pc,
    output wire [31:0] commit_instr,
    output wire        commit_halt,
    output wire        commit_reg_we,
    output wire [4:0]  commit_reg_wa,
    output wire [31:0] commit_reg_wd,
    output wire        commit_dmem_we,
    output wire [31:0] commit_dmem_wa,
    output wire [31:0] commit_dmem_wd,

    input  wire [4:0]  debug_reg_ra,
    output wire [31:0] debug_reg_rd
);

    localparam [31:0] HALT_INSTR_1 = 32'h0010_0073;
    localparam [31:0] HALT_INSTR_2 = 32'h8000_0000;

// =====================IF 阶段 (Instruction Fetch)
    wire [31:0] pc_if;  //当前指令地址
    wire [31:0] npc;
    wire [31:0] pc_add4_if = pc_if + 32'd4;
    wire        commit_if = 1'b1;  // 这个信号需要经过 IF/ID、ID/EX、EX/MEM、MEM/WB 段间寄存器，最终连接到 commit_reg 上

    assign imem_raddr = pc_if;

    PC u_PC (
        .clk(clk),
        .rst(rst),
        .en(global_en),

        .npc(npc),
        .pc(pc_if)  //当前指令地址
    );

    wire [64:0] if_id_in  = {commit_if, pc_if, imem_rdata};
    wire [64:0] if_id_out;
    wire        flush_if_id = |npc_sel_ex;  //发生跳转(EX阶段跳转选择信号)

    stage_reg #(.WIDTH(65)) REG_IF_ID (
        .clk(clk),
        .rst(rst),
        .en(global_en),
        .flush(flush_if_id),
        .stall(1'b0),

        .data_in(if_id_in),
        .data_out(if_id_out)
    );

    wire        commit_id = if_id_out[64];
    wire [31:0] pc_id     = if_id_out[63:32];
    wire [31:0] inst_id   = if_id_out[31:0];

// ===================ID 阶段 (Instruction Decode)
    wire [4:0]  alu_op_id;
    wire [4:0]  rf_ra0_id;
    wire [4:0]  rf_ra1_id;
    wire [4:0]  rf_wa_id;
    wire [31:0] imm_id;
    wire [31:0] rf_rd0_raw;
    wire [31:0] rf_rd1_raw;
    wire        rf_we_id;
    wire        alu_src0_sel_id;
    wire        alu_src1_sel_id;
    wire [1:0]  rf_wd_sel_id;
    wire [3:0]  br_type_id;
    wire [3:0]  dmem_access_id;

    DECODER u_DECODER (
        .inst(inst_id), //指令码

        .alu_op(alu_op_id), // ALU 的运算模式码
        .imm(imm_id),   // 扩展的立即数

        .rf_ra0(rf_ra0_id),
        .rf_ra1(rf_ra1_id),
        .rf_wa(rf_wa_id),
        .rf_we(rf_we_id),
        .rf_wd_sel(rf_wd_sel_id),   // 写回寄存器数据来源选择: 0-ALU, 1-Mem, 2-PC+4

        .alu_src0_sel(alu_src0_sel_id), //ALU 的操作数来源 寄存器/PC
        .alu_src1_sel(alu_src1_sel_id), //寄存器or立即数

        .br_type(br_type_id),   //分支指令的类型,EX用

        .dmem_access(dmem_access_id)    //访存类型
    );

    wire [31:0] rf_rd0_id = rf_rd0_raw;
    wire [31:0] rf_rd1_id = rf_rd1_raw;

    REG_FILE u_REG_FILE (
        .clk(clk),
        .rf_ra0(rf_ra0_id),
        .rf_ra1(rf_ra1_id),
        .rf_wa(rf_wa_wb),
        .rf_we(rf_we_wb & global_en),
        .rf_wd(rf_wd_wb),

        .rf_rd0(rf_rd0_raw),
        .rf_rd1(rf_rd1_raw),

        .debug_reg_ra(debug_reg_ra),
        .debug_reg_rd(debug_reg_rd)
    );

    wire [183:0] id_ex_in;
    wire [183:0] id_ex_out;

    assign id_ex_in = { //instruction decode
        commit_id,
        pc_id,
        inst_id,

        rf_rd0_id,
        rf_rd1_id,
        imm_id,

        rf_wa_id,
        rf_we_id,
        rf_wd_sel_id,

        alu_op_id,
        alu_src0_sel_id,
        alu_src1_sel_id,

        br_type_id,

        dmem_access_id
    };

    stage_reg #(.WIDTH(184)) REG_ID_EX (
        .clk(clk),
        .rst(rst),
        .en(global_en),
        .flush(flush_if_id),
        .stall(1'b0),

        .data_in(id_ex_in),
        .data_out(id_ex_out)
    );

// ====================EX 阶段 (Execute)
    wire        commit_ex;
    wire [31:0] pc_ex;
    wire [31:0] inst_ex;
    wire [31:0] rf_rd0_ex;
    wire [31:0] rf_rd1_ex;
    wire [31:0] imm_ex;
    wire [4:0]  rf_wa_ex;
    wire [4:0]  alu_op_ex;
    wire        rf_we_ex;
    wire        alu_src0_sel_ex;
    wire        alu_src1_sel_ex;
    wire [1:0]  rf_wd_sel_ex;
    wire [1:0]  npc_sel_ex;
    wire [3:0]  br_type_ex;
    wire [3:0]  dmem_access_ex;

    assign {
        commit_ex,
        pc_ex,
        inst_ex,

        rf_rd0_ex,
        rf_rd1_ex,
        imm_ex,
        rf_wa_ex,
        rf_we_ex,
        rf_wd_sel_ex,

        alu_op_ex,
        alu_src0_sel_ex,
        alu_src1_sel_ex,

        br_type_ex,
        dmem_access_ex
    } = id_ex_out;

    wire [31:0] alu_src0_ex = alu_src0_sel_ex ? pc_ex : rf_rd0_ex;
    wire [31:0] alu_src1_ex = alu_src1_sel_ex ? imm_ex : rf_rd1_ex;
    wire [31:0] alu_res_ex;

    ALU u_ALU (
        .alu_src0(alu_src0_ex),
        .alu_src1(alu_src1_ex),
        .alu_op(alu_op_ex),

        .alu_res(alu_res_ex)    //ALU计算结果
    );

    BRANCH u_BRANCH (
        .br_type(br_type_ex),
        .br_src0(rf_rd0_ex),
        .br_src1(rf_rd1_ex),
        .npc_sel(npc_sel_ex)
    );

    NPC u_NPC (
        .npc_sel(npc_sel_ex),
        .pc_add4(pc_add4_if),
        .pc_offset(pc_ex + imm_ex),
        .alu_res(alu_res_ex),

        .npc(npc)
    );

    wire [140:0] ex_mem_in;
    wire [140:0] ex_mem_out;

    assign ex_mem_in = {
        commit_ex,
        pc_ex,
        inst_ex,

        alu_res_ex,

        rf_rd1_ex,
        rf_wa_ex,
        rf_we_ex,
        rf_wd_sel_ex,
        dmem_access_ex
    };

    stage_reg #(.WIDTH(141)) REG_EX_MEM (
        .clk(clk),
        .rst(rst),
        .en(global_en),
        .flush(1'b0),
        .stall(1'b0),
        .data_in(ex_mem_in),
        .data_out(ex_mem_out)
    );

//=======================MEM 阶段 (Memory Access)
    wire        commit_mem;
    wire [31:0] pc_mem;
    wire [31:0] inst_mem;
    wire [31:0] alu_res_mem;
    wire [31:0] rf_rd1_mem;
    wire [4:0]  rf_wa_mem;
    wire        rf_we_mem;
    wire [1:0]  rf_wd_sel_mem;
    wire [3:0]  dmem_access_mem;

    assign {
        commit_mem,
        pc_mem,
        inst_mem,
        alu_res_mem,
        rf_rd1_mem,
        rf_wa_mem,
        rf_we_mem,
        rf_wd_sel_mem,
        dmem_access_mem
    } = ex_mem_out;

    wire [31:0] dmem_rd_mem;
    wire [31:0] dmem_wd_proc;

    SLU u_SLU (
        .addr(alu_res_mem),
        .dmem_access(dmem_access_mem),
        .rd_in(dmem_rdata),
        .wd_in(rf_rd1_mem),

        .rd_out(dmem_rd_mem),
        .wd_out(dmem_wd_proc)
    );

    assign dmem_we   = dmem_access_mem[3] & global_en;
    assign dmem_addr = alu_res_mem;
    assign dmem_wdata = dmem_wd_proc;

    wire [201:0] mem_wb_in;
    wire [201:0] mem_wb_out;

    assign mem_wb_in = {
        commit_mem,
        pc_mem,
        inst_mem,
        alu_res_mem,
        dmem_rd_mem,
        rf_wa_mem,
        rf_we_mem,
        rf_wd_sel_mem,
        dmem_we,
        dmem_addr,
        dmem_wd_proc
    };

    stage_reg #(.WIDTH(202)) REG_MEM_WB (
        .clk(clk),
        .rst(rst),
        .en(global_en),
        .flush(1'b0),
        .stall(1'b0),
        .data_in(mem_wb_in),
        .data_out(mem_wb_out)
    );

// ============================WB 阶段 (Write Back) & Commit
    wire        commit_wb;
    wire [31:0] pc_wb;
    wire [31:0] inst_wb;
    wire [31:0] alu_res_wb;
    wire [31:0] dmem_rd_wb;
    wire [4:0]  rf_wa_wb;
    wire        rf_we_wb;
    wire [1:0]  rf_wd_sel_wb;
    wire        dmem_we_wb;
    wire [31:0] dmem_wa_wb;
    wire [31:0] dmem_wd_wb;

    assign {
        commit_wb,
        pc_wb,
        inst_wb,
        alu_res_wb,
        dmem_rd_wb,
        rf_wa_wb,
        rf_we_wb,
        rf_wd_sel_wb,
        dmem_we_wb,
        dmem_wa_wb,
        dmem_wd_wb
    } = mem_wb_out;

    wire [31:0] rf_wd_wb;

    reg         commit_reg;
    reg [31:0]  commit_pc_reg;
    reg [31:0]  commit_inst_reg;
    reg         commit_halt_reg;
    reg         commit_reg_we_reg;
    reg [4:0]   commit_reg_wa_reg;
    reg [31:0]  commit_reg_wd_reg;
    reg         commit_dmem_we_reg;
    reg [31:0]  commit_dmem_wa_reg;
    reg [31:0]  commit_dmem_wd_reg;

    MUX2 u_MUX_WB (
        .src0(alu_res_wb),
        .src1(dmem_rd_wb),
        .src2(pc_wb + 32'd4),
        .src3(32'd0),
        .sel(rf_wd_sel_wb),
        .res(rf_wd_wb)
    );

    always @(posedge clk) begin
        if (rst) begin
            commit_reg          <= 1'H0;
            commit_pc_reg       <= 32'H0;
            commit_inst_reg     <= 32'H0;
            commit_halt_reg     <= 1'H0;
            commit_reg_we_reg   <= 1'H0;
            commit_reg_wa_reg   <= 5'H0;
            commit_reg_wd_reg   <= 32'H0;
            commit_dmem_we_reg  <= 1'H0;
            commit_dmem_wa_reg  <= 32'H0;
            commit_dmem_wd_reg  <= 32'H0;
        end
        else if (global_en) begin
            // 这里右侧的信号都是 MEM/WB 段间寄存器的输出
            commit_reg          <= commit_wb;
            commit_pc_reg       <= pc_wb;
            commit_inst_reg     <= inst_wb;
            commit_halt_reg     <= (inst_wb == HALT_INSTR_1) || (inst_wb == HALT_INSTR_2);
            commit_reg_we_reg   <= rf_we_wb;
            commit_reg_wa_reg   <= rf_wa_wb;
            commit_reg_wd_reg   <= rf_wd_wb;
            commit_dmem_we_reg  <= dmem_we_wb;
            commit_dmem_wa_reg  <= dmem_wa_wb;
            commit_dmem_wd_reg  <= dmem_wd_wb;
        end
    end
    
    assign commit               = commit_reg;
    assign commit_pc            = commit_pc_reg;
    assign commit_instr         = commit_inst_reg;
    assign commit_halt          = commit_halt_reg;
    assign commit_reg_we        = commit_reg_we_reg;
    assign commit_reg_wa        = commit_reg_wa_reg;
    assign commit_reg_wd        = commit_reg_wd_reg;
    assign commit_dmem_we       = commit_dmem_we_reg;
    assign commit_dmem_wa       = commit_dmem_wa_reg;
    assign commit_dmem_wd       = commit_dmem_wd_reg;

endmodule
