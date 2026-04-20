module CPU (
    input               clk,
    input               rst,

    input               global_en,  //来自PDU的控制信号

    //instruction memory指令存储器接口
    output  [31 : 0]    imem_raddr, //IM,pc值
    input   [31 : 0]    imem_rdata, //inst

    //数据存储器接口（用于lw/sw)
    input   [31 : 0]    dmem_rdata,
    output              dmem_we,
    output  [31 : 0]    dmem_addr,
    output  [31 : 0]    dmem_wdata,

    //Debug / Commit 信号
    output              commit, //指令提交标志
    output  [31 : 0]    commit_pc,  //当前指令的 PC
    output  [31 : 0]    commit_instr,   //当前指令的内容
    output              commit_halt,    //停机标志指令是0x80000000
    output              commit_reg_we,  //寄存器堆写使能
    output  [ 4 : 0]    commit_reg_wa,
    output  [31 : 0]    commit_reg_wd,
    output              commit_dmem_we, //内存写使能状态
    output  [31 : 0]    commit_dmem_wa,
    output  [31 : 0]    commit_dmem_wd,

    input   [ 4 : 0]    debug_reg_ra,   // TODO
    output  [31 : 0]    debug_reg_rd    // TODO
);

    wire [31:0] pc_out, npc;
    wire [31:0] inst = imem_rdata; // 指令直接来自框架接口

    wire [ 4:0] alu_op;
    wire [31:0] imm;
    wire [ 4:0] rf_ra0, rf_ra1, rf_wa;
    wire        rf_we;
    wire        alu_src0_sel, alu_src1_sel;

    wire [31:0] rf_rd0, rf_rd1;
    wire [31:0] alu_src0, alu_src1;
    wire [31:0] alu_res;

    // 暂不使用数据存储器(DMEM)，全赋0
    assign dmem_we    = 1'b0;
    assign dmem_addr  = 32'h0;
    assign dmem_wdata = 32'h0;

    assign npc = pc_out + 32'd4;    // 单周期目前直接 PC+4
    assign imem_raddr = pc_out;     // 将 PC 连到指令存储器取指
    PC u_PC (
        .clk    (clk),
        .rst    (rst),
        .en     (global_en),        // 接入全局使能控制停启
        .npc    (npc),
        .pc     (pc_out)
    );

    DECODER u_DECODER (
        .inst           (inst),

        .alu_op         (alu_op),
        .imm            (imm),
        .rf_ra0         (rf_ra0),
        .rf_ra1         (rf_ra1),
        .rf_wa          (rf_wa),
        .rf_we          (rf_we),
        .alu_src0_sel   (alu_src0_sel),
        .alu_src1_sel   (alu_src1_sel)
    );

    wire actual_rf_we = rf_we & global_en; //防止 PDU 暂停时错误写入
    REG_FILE u_REG_FILE (
        .clk            (clk),
        .rf_ra0         (rf_ra0),
        .rf_ra1         (rf_ra1),
        .rf_wa          (rf_wa),
        .rf_we          (actual_rf_we), // 使用带门控的写使能
        .rf_wd          (alu_res),      // 写回数据直接来自 ALU

        .rf_rd0         (rf_rd0),
        .rf_rd1         (rf_rd1),

        .debug_reg_ra   (debug_reg_ra), // 接入 PDU 调试接口
        .debug_reg_rd   (debug_reg_rd)
    );

    MUX u_MUX0 (    //rs1 VS pc
        .src0   (rf_rd0),
        .src1   (pc_out),
        .sel    (alu_src0_sel),
        .res    (alu_src0)
    );

    MUX u_MUX1 (    //rs2 vs imm
        .src0   (rf_rd1),
        .src1   (imm),
        .sel    (alu_src1_sel),
        .res    (alu_src1)
    );

    ALU u_ALU (
        .alu_src0       (alu_src0),
        .alu_src1       (alu_src1),
        .alu_op         (alu_op),
        .alu_res        (alu_res)
    );

    // Commit
    reg  [ 0 : 0]   commit_reg          ;
    reg  [31 : 0]   commit_pc_reg       ;
    reg  [31 : 0]   commit_instr_reg    ;
    reg  [ 0 : 0]   commit_halt_reg     ;
    reg  [ 0 : 0]   commit_reg_we_reg   ;
    reg  [ 4 : 0]   commit_reg_wa_reg   ;
    reg  [31 : 0]   commit_reg_wd_reg   ;
    reg  [ 0 : 0]   commit_dmem_we_reg  ;
    reg  [31 : 0]   commit_dmem_wa_reg  ;
    reg  [31 : 0]   commit_dmem_wd_reg  ;

    always @(posedge clk) begin
        if (rst) begin
            commit_reg          <= 1'B0;
            commit_pc_reg       <= 32'H0;
            commit_instr_reg    <= 32'H0;
            commit_halt_reg     <= 1'B0;
            commit_reg_we_reg   <= 1'B0;
            commit_reg_wa_reg   <= 5'H0;
            commit_reg_wd_reg   <= 32'H0;
            commit_dmem_we_reg  <= 1'B0;
            commit_dmem_wa_reg  <= 32'H0;
            commit_dmem_wd_reg  <= 32'H0;
        end
        else if (global_en) begin
            commit_reg          <= 1'B1;
            commit_pc_reg       <= pc_out;   // TODO
            commit_instr_reg    <= inst;   // TODO
            commit_halt_reg     <= (inst == 32'H00100073);   // TODO
            commit_reg_we_reg   <= rf_we;   // TODO
            commit_reg_wa_reg   <= rf_wa;   // TODO
            commit_reg_wd_reg   <= alu_res;   // TODO
            commit_dmem_we_reg  <= 1'b0;   // TODO
            commit_dmem_wa_reg  <= 32'h0;   // TODO
            commit_dmem_wd_reg  <= 32'h0;   // TODO
        end
    end

    assign commit           = commit_reg;
    assign commit_pc        = commit_pc_reg;
    assign commit_instr     = commit_instr_reg;
    assign commit_halt      = commit_halt_reg;
    assign commit_reg_we    = commit_reg_we_reg;
    assign commit_reg_wa    = commit_reg_wa_reg;
    assign commit_reg_wd    = commit_reg_wd_reg;
    assign commit_dmem_we   = commit_dmem_we_reg;
    assign commit_dmem_wa   = commit_dmem_wa_reg;
    assign commit_dmem_wd   = commit_dmem_wd_reg;

endmodule