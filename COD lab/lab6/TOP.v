module cpu (
    input  wire        clk,          // 接入 PDU 提供的 cpu_clk
    input  wire        rst,          // 复位信号
    
    input  wire [ 4:0] debug_reg_ra, // PDU 想要查看的寄存器地址
    output wire [31:0] debug_reg_rd, // 输出给 PDU 的寄存器数值
    output wire [31:0] cur_pc        // 输出给 PDU 的当前 PC 值
);

    // --- 内部连线声明 ---
    wire [31:0] pc_out;
    wire [31:0] npc;
    wire [31:0] inst;
    
    // 译码器输出信号
    wire [ 4:0] alu_op;
    wire [31:0] imm;
    wire [ 4:0] rf_ra0, rf_ra1, rf_wa;
    wire        rf_we;
    wire        alu_src0_sel, alu_src1_sel;
    
    wire [31:0] rf_rd0, rf_rd1; //寄存器堆输出
    wire [31:0] alu_src0, alu_src1; // MUX 输出
    wire [31:0] alu_res;    // ALU 输出

    PC pc_u (
        .clk(clk),
        .rst(rst),
        .en(1'b1),      // 在简单单周期中始终使能，PDU 会通过控制 clk 来暂停 CPU
        .npc(npc),
        .pc(pc_out)
    );
    
    assign cur_pc = pc_out; // 连至输出供调试
    assign npc = pc_out + 32'd4;    //下一条指令地址

    // --- 3. 指令存储器 (IM) ---
    // 注意：这里需要根据你实验提供的 IM IP核或模块名进行修改
    // 通常 IM 是只读的，输入地址，异步或同步输出指令
    lab1_1 im_u (
        .a(pc_out[5:2]), // IM有16个存储单元
        .spo(inst)        // 输出指令 inst
    );

    DECODE decoder_u (
        .inst(inst),

        .alu_op(alu_op),
        .imm(imm),
        .rf_ra0(rf_ra0),
        .rf_ra1(rf_ra1),
        .rf_wa(rf_wa),
        .rf_we(rf_we),
        .alu_src0_sel(alu_src0_sel),
        .alu_src1_sel(alu_src1_sel)
    );

    REG_FILE rf_u (
        .clk(clk),
        .rf_ra0(rf_ra0),
        .rf_ra1(rf_ra1),
        .rf_wa(rf_wa),
        .rf_we(rf_we),
        .rf_wd(alu_res),    // 写回数据来自 ALU 结果

        .rf_rd0(rf_rd0),
        .rf_rd1(rf_rd1),
        .debug_reg_ra(debug_reg_ra), // 接入 PDU 接口
        .debug_reg_rd(debug_reg_rd)
    );

    assign alu_src0 = alu_src0_sel ? pc_out : rf_rd0;   //0-rs1 1-aupic
    assign alu_src1 = alu_src1_sel ? imm : rf_rd1;

    alu alu_u (
        .a(alu_src0),
        .b(alu_src1),
        .op(alu_op),
        .res(alu_res)
    );

endmodule