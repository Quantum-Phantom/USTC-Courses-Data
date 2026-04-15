`timescale 1ns / 1ps

module TOP (
    input  [ 0 : 0] clk,       // 100MHz 系统时钟
    input  [ 0 : 0] rst,       // 全局复位信号 sw[7]
    input  [ 0 : 0] enable,    // 写入使能按钮
    input  [ 4 : 0] in,        // 5位数据/操作码输入 sw[4:0]
    input  [ 1 : 0] ctrl,      // 2位控制信号 sw[6:5]
    output [ 3 : 0] seg_data,  // 数码管数据段
    output [ 2 : 0] seg_an     // 数码管选择端
);

    wire [31:0] in_ext = {{27{in[4]}}, in};


    reg [4:0]  alu_op;
    reg [31:0] alu_src0;
    reg [31:0] alu_src1;
    reg [31:0] output_data; // 送给数码管的显示数据

    always @(posedge clk) begin
        if (rst) begin
            alu_op      <= 5'b0;
            alu_src0    <= 32'b0;
            alu_src1    <= 32'b0;
            output_data <= 32'b0;
        end 
        else if (enable) begin
            case (ctrl)
                2'b00: alu_op      <= in;        // 操作码 (直接用5位)
                2'b01: alu_src0    <= in_ext;    // 操作数0 (符号扩展为32位)
                2'b10: alu_src1    <= in_ext;    // 操作数1 (符号扩展为32位)
                2'b11: output_data <= alu_res;   // 将计算结果锁存到输出寄存器
            endcase
        end
    end

    wire [31:0] alu_res;
    
    ALU u_alu (
        .alu_src0 (alu_src0),
        .alu_src1 (alu_src1),
        .alu_op   (alu_op),
        .alu_res  (alu_res)
    );

    Segment u_seg (
        .clk         (clk),
        .rst         (rst),
        .output_data (output_data),
        .seg_data    (seg_data),
        .seg_an      (seg_an)
    );

endmodule