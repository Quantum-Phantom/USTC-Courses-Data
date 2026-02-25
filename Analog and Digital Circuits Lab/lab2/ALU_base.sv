`timescale 1ns / 1ps
module ALU_base(
    input [11:0]    f,
    input [31:0]    a,b,
    output [31:0]   y
    );
    wire [31:0] add_result; 
    wire [31:0] sub_result;
    wire [31:0] slt_result; //a<b
    wire [31:0] sltu_result;//(unsigned)a<b
    wire [31:0] and_result;//a&b
    wire [31:0] or_result;//a|b
    wire [31:0] orn_result;//~(a|b)按位或非
    wire [31:0] xor_result;//a^b按位异或
    wire [31:0] sll_result; //逻辑左移[4:0] a<<b[4:0](Shift Left Logical Result)
    wire [31:0] srl_result; //逻辑右移[4:0]>>b[4:0](Shift Right Logical Result)
    wire [31:0] sra_result;//算数右移[4:0]>>>b[4:0](Shift Right Arithmetic )
    wire [31:0] b_result;

    assign add_result=a+b;
    assign sub_result=a-b;
    assign slt_result[31:1]=31'b0;
    assign sltu_result[31:1]=31'b0;
    assign slt_result[0]=(a[31]^b[31])?((a[31]>b[31])?1:0):(((a[31]==0&&a[30:0]<b[30:0])||(a[31]==1&&a[30:0]>b[30:0]))?1:0);
    assign sltu_result[0]=(a<b)?1:0;
    assign and_result=a&b;
    assign or_result=a|b;
    assign orn_result=~(a|b);
    assign xor_result=a^b;
    assign sll_result=a<<b[4:0];
    assign srl_result=a>>b[4:0];
    assign sra_result= $signed(a) >>>b[4:0];
    assign b_result=b;

    // multiplex outputs based on function code f
    assign y = ({32{f[0]  }} & add_result)
             | ({32{f[1]  }} & sub_result)
             | ({32{f[2]  }} & slt_result)
             | ({32{f[3]  }} & sltu_result)
             | ({32{f[4]  }} & and_result)
             | ({32{f[5]  }} & or_result)
             | ({32{f[6]  }} & orn_result)
             | ({32{f[7]  }} & xor_result)   
             | ({32{f[8]  }} & sll_result)   
             | ({32{f[9]  }} & srl_result)   
             | ({32{f[10] }} & sra_result)
             | ({32{f[11] }} & b_result);

endmodule