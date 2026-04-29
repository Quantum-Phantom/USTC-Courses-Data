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
    output              commit, 
    output  [31 : 0]    commit_pc,  
    output  [31 : 0]    commit_instr,   
    output              commit_halt,    
    output              commit_reg_we,  
    output  [ 4 : 0]    commit_reg_wa,
    output  [31 : 0]    commit_reg_wd,
    output              commit_dmem_we, 
    output  [31 : 0]    commit_dmem_wa,
    output  [31 : 0]    commit_dmem_wd,

    input   [ 4 : 0]    debug_reg_ra,   
    output  [31 : 0]    debug_reg_rd    
);

    // --- 信号定义 ---
    wire [31:0] pc_out, npc;
    wire [31:0] inst = imem_rdata;

    // 控制信号
    wire [ 4:0] alu_op;
    wire [ 3:0] br_type;    //branch种类
    wire [ 1:0] rf_wd_sel;  //写回选择
    wire [31:0] imm;
    wire [ 4:0] rf_ra0, rf_ra1, rf_wa;  //寄存器堆的读写地址
    wire        rf_we;
    wire        alu_src0_sel, alu_src1_sel; //ALU操作数选择
    wire        mem_we; // 内部内存写使能信号

    // 数据信号
    wire [31:0] rf_rd0, rf_rd1; //寄存器读
    wire [31:0] alu_src0, alu_src1; //ALU操作数
    wire [31:0] alu_res;   //ALU计算结果
    wire [31:0] rf_wd;  //寄存器写数据
    
    // NPC 相关信号
    wire [ 1:0] npc_sel;
    wire [31:0] pc_add4   = pc_out + 32'd4;
    wire [31:0] pc_offset = pc_out + imm;

    // SLU 处理信号
    wire [ 3 : 0] dmem_access;
    wire [31 : 0] dmem_rd_processed; 
    wire [31 : 0] dmem_wd_processed; 

    // --- 1. 程序计数器 (PC) ---
    assign imem_raddr = pc_out;
    PC u_PC (
        .clk    (clk),
        .rst    (rst),
        .en     (global_en),
        .npc    (npc),

        .pc     (pc_out)
    );

    // --- 2. NPC 选择器 (NPC MUX) ---
    NPC u_NPC (
        .npc_sel    (npc_sel),
        .pc_add4    (pc_add4),
        .pc_offset  (pc_offset),    
        .alu_res    (alu_res), 

        .npc        (npc)
    );

    // --- 3. 指令译码器 (DECODER) ---
    DECODER u_DECODER (
        .inst           (inst),

        .alu_op         (alu_op),
        .imm            (imm),

        .rf_ra0         (rf_ra0),
        .rf_ra1         (rf_ra1),
        .rf_wa          (rf_wa),
        .rf_we          (rf_we),
        .rf_wd_sel      (rf_wd_sel),    //写回选择

        .alu_src0_sel   (alu_src0_sel),
        .alu_src1_sel   (alu_src1_sel),

        .br_type        (br_type),
        .dmem_access    (dmem_access)
    );

    // --- 4. 寄存器堆 (REG_FILE) ---
    wire actual_rf_we = rf_we & global_en;
    REG_FILE u_REG_FILE (
        .clk            (clk),
        .rf_ra0         (rf_ra0),
        .rf_ra1         (rf_ra1),
        .rf_wa          (rf_wa),
        .rf_we          (actual_rf_we),
        .rf_wd          (rf_wd),

        .rf_rd0         (rf_rd0),
        .rf_rd1         (rf_rd1),

        .debug_reg_ra   (debug_reg_ra),
        .debug_reg_rd   (debug_reg_rd)
    );

    // --- 5. ALU 输入选择 MUX ---
    MUX u_MUX_SRC0 (
        .src0   (rf_rd0),
        .src1   (pc_out),
        .sel    (alu_src0_sel),

        .res    (alu_src0)
    );

    MUX u_MUX_SRC1 (
        .src0   (rf_rd1),
        .src1   (imm),
        .sel    (alu_src1_sel),

        .res    (alu_src1)
    );

    // --- 6. 算术逻辑单元 (ALU) ---
    ALU u_ALU (
        .alu_src0       (alu_src0),
        .alu_src1       (alu_src1),
        .alu_op         (alu_op),

        .alu_res        (alu_res)
    );

    // --- 7. 分支判断模块 (BRANCH) ---
    BRANCH u_BRANCH (
        .br_type        (br_type),
        .br_src0        (rf_rd0),
        .br_src1        (rf_rd1),

        .npc_sel        (npc_sel)
    );

    // --- 8. 访存处理单元 (SLU) ---
    SLU u_SLU (
        .addr           (alu_res),  // 访存地址
        .dmem_access    (dmem_access),  //访存类型，字节or半字

        .rd_in          (dmem_rdata),   //从存储器读到的原始 32 位数据
        .wd_in          (rf_rd1),        // 寄存器准备写入的数据 (x[rs2])

        .rd_out         (dmem_rd_processed),    // 处理后写回寄存器
        .wd_out         (dmem_wd_processed) // 处理后写入存储器的 32 位数据
    );

    // 内存接口外部赋值
    assign mem_we = dmem_access[3]; //sw.sh,sb
    assign dmem_we    = mem_we & global_en; // 增加使能门控
    assign dmem_addr  = alu_res;
    assign dmem_wdata = dmem_wd_processed;

    // --- 9. 写回数据选择 (MUX2) ---
    MUX2 u_MUX_WB ( //写回寄存器堆
        .src0   (alu_res),  //00-ALU结果
        .src1   (dmem_rd_processed), // 01-从存储器读到的值(处理后的内存数据)
        .src2   (pc_add4),  //10-jalr,jal
        .src3   (32'b0),
        .sel    (rf_wd_sel),

        .res    (rf_wd)
    );

    // --- 10. Commit / Debug 寄存器更新 ---
    reg [0:0] commit_reg;
    reg [31:0] commit_pc_reg, commit_instr_reg, commit_reg_wd_reg, commit_dmem_wa_reg, commit_dmem_wd_reg;
    reg [0:0] commit_halt_reg, commit_reg_we_reg, commit_dmem_we_reg;
    reg [4:0] commit_reg_wa_reg;

    always @(posedge clk) begin
        if (rst) begin
            commit_reg <= 1'b0;
            commit_pc_reg <= 32'b0;
            commit_instr_reg <= 32'b0;
            commit_halt_reg <= 1'b0;
            commit_reg_we_reg <= 1'b0;
            commit_reg_wa_reg <= 5'b0;
            commit_reg_wd_reg <= 32'b0;
            commit_dmem_we_reg <= 1'b0;
            commit_dmem_wa_reg <= 32'b0;
            commit_dmem_wd_reg <= 32'b0;
        end
        else if (global_en) begin
            commit_reg <= 1'b1;
            commit_pc_reg <= pc_out;
            commit_instr_reg <= inst;
            commit_halt_reg <= (inst == 32'H00100073) || (inst == 32'H80000000); 
            commit_reg_we_reg <= rf_we;
            commit_reg_wa_reg <= rf_wa;
            commit_reg_wd_reg <= rf_wd;      
            commit_dmem_we_reg <= dmem_we;
            commit_dmem_wa_reg <= dmem_addr;
            commit_dmem_wd_reg <= dmem_wdata;
        end
    end

    assign commit = commit_reg;
    assign commit_pc = commit_pc_reg;
    assign commit_instr = commit_instr_reg;
    assign commit_halt = commit_halt_reg;
    assign commit_reg_we = commit_reg_we_reg;
    assign commit_reg_wa = commit_reg_wa_reg;
    assign commit_reg_wd = commit_reg_wd_reg;
    assign commit_dmem_we = commit_dmem_we_reg;
    assign commit_dmem_wa = commit_dmem_wa_reg;
    assign commit_dmem_wd = commit_dmem_wd_reg;

endmodule