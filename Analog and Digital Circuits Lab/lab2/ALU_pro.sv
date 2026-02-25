`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/28 20:15:15
// Design Name: 
// Module Name: ALU_pro
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU_pro(
    input [11:0]    f,
    input [31:0]    a,b,
    output [31:0]   y
    );
    wire [31:0] add_sub_result; 
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

    wire [31:0] adder_a;
    wire [31:0] adder_b;
    wire        adder_cin;//“取反加一”中的加一
    wire [31:0] adder_result;
    wire        adder_cout;//防溢出吧,加法表示进位减法表示借位，无符号数相减的话为1就是大于

    //加减比大小
    assign adder_a=a;
    assign adder_b=(f[1]|f[2]|f[3])?~b:b;//如果是sub/slt/sltu就取反
    assign adder_cin=(f[1]|f[2]|f[3])?1'b1:1'b0;//如果是sub/slt/sltu就取反后加一
    assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;// 计算加/减法，结果为 33 位：最高位为进位/借位，低 32 位为结果
    assign add_sub_result=adder_result;

    //有符号数a<b
    assign slt_result[31:1] = 31'b0;
    assign slt_result[0] = (a[31] & ~b[31])// 有符号比较：若 a 符号为 1 且 b 符号为 0，则 a<b；
                         | ((a[31] == b[31]) & adder_result[31]);// 若 a 和 b 同号，则通过 (a-b) 的符号位判断（adder_result[31]==1 表示 a-b 为负，即 a<b）
    
    //无符号数a<b
    assign sltu_result[31:1]=31'b0;
    assign sltu_result[0]=~adder_cout;

    //按位运算
    assign and_result=a&b;
    assign or_result=a|b;
    assign orn_result=~(a|b);
    assign xor_result=a^b;

    //移位运算
    assign sll_result = a << b[4:0];
    assign srl_result = a >> b[4:0];

    // 算术右移：对 a 进行有符号扩展后算术右移 算数位移必须要有符号数
    assign sra_result = $signed(a) >>> b[4:0];

    assign b_result=b;

    assign y = ({32{f[0]|f[1]  }} & add_sub_result)
             | ({32{f[2]       }} & slt_result)
             | ({32{f[3]       }} & sltu_result)
             | ({32{f[4]       }} & and_result)
             | ({32{f[5]       }} & or_result)
             | ({32{f[6]       }} & orn_result)
             | ({32{f[7]       }} & xor_result)   
             | ({32{f[8]       }} & sll_result)   
             | ({32{f[9]       }} & srl_result)   
             | ({32{f[10]      }} & sra_result)
             | ({32{f[11]      }} & b_result);
endmodule
