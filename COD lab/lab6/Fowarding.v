module Fowarding(
    input  wire [4:0]  rf_ra0_ex,   //传入EX段的读寄存器地址
    input  wire [4:0]  rf_ra1_ex,

    input  wire [4:0]  rf_wa_mem,   //写目标寄存器
    input  wire [4:0]  rf_wa_wb,
    input  wire        rf_we_mem,   //MEM段的寄存器堆写使能信号
    input  wire        rf_we_wb,    //WB段的寄存器堆写使能信号

    input  wire [31:0] rf_wd_mem,   //寄存器堆的写数据
    input  wire [31:0] rf_wd_wb,

    output wire        rf_rd0_fe,   //前递使能信号
    output wire        rf_rd1_fe,
    output wire [31:0] rf_rd0_fd,   //前递数据信号 read data
    output wire [31:0] rf_rd1_fd
);

    wire forward_a_mem = rf_we_mem && (rf_wa_mem != 5'd0) && (rf_wa_mem == rf_ra0_ex);
    wire forward_a_wb  = rf_we_wb  && (rf_wa_wb  != 5'd0) && (rf_wa_wb  == rf_ra0_ex) && !forward_a_mem;    //mem阶段的数据更新，更应该被使用
    wire forward_b_mem = rf_we_mem && (rf_wa_mem != 5'd0) && (rf_wa_mem == rf_ra1_ex);
    wire forward_b_wb  = rf_we_wb  && (rf_wa_wb  != 5'd0) && (rf_wa_wb  == rf_ra1_ex) && !forward_b_mem;

    assign rf_rd0_fe = forward_a_mem || forward_a_wb;
    assign rf_rd1_fe = forward_b_mem || forward_b_wb;

    assign rf_rd0_fd = forward_a_mem ? rf_wd_mem : rf_wd_wb;    //前递无效时，默认输出rf_wd_wb
    assign rf_rd1_fd = forward_b_mem ? rf_wd_mem : rf_wd_wb;

endmodule
