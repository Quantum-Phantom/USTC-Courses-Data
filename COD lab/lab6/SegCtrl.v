module SegCtrl(
    input  wire        rf_we_ex,    //EX寄存器堆写使能
    input  wire [1:0]  rf_wd_sel_ex,    //EX指令写回数据来源
    input  wire [4:0]  rf_wa_ex,    //EX写回目标寄存器
    input  wire [4:0]  rf_ra0_id,
    input  wire [4:0]  rf_ra1_id,
    input  wire [1:0]  npc_sel_ex,  //EX next PC选择信号，不为0时发生跳转

    output wire        stall_pc,    //PC寄存器暂停
    output wire        stall_if_id, //IF/ID段间寄存器暂停
    output wire        flush_if_id, //清空IF/ID 段间寄存器
    output wire        flush_id_ex  //清空ID/EX 段间寄存器
);

    wire load_use = rf_we_ex && //EX段指令会写回寄存器
                    (rf_wd_sel_ex == 2'b01) &&  //写回数据来自内存（load
                    (rf_wa_ex != 5'd0) &&
                    ((rf_wa_ex == rf_ra0_id) || (rf_wa_ex == rf_ra1_id));   //要写回的数据正好是当前要读取的数据

    wire ctrl_hazard = |npc_sel_ex; //npc_sel_ex[1] || npc_sel_ex[0]，不是2'b00就跳转

    assign stall_pc     = load_use && !ctrl_hazard;
    assign stall_if_id  = load_use && !ctrl_hazard;
    assign flush_id_ex  = load_use ? 1'b1 : (ctrl_hazard ? 1'b1 : 1'b0);
    assign flush_if_id  = ctrl_hazard ? 1'b1 : 1'b0;

endmodule
