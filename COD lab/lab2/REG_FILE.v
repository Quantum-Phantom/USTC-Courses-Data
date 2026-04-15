`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/11 13:25:29
// Design Name: 
// Module Name: REG_FILE
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


module REG_FILE(
    input       clk,
    input [4:0] rf_ra0,
    input [4:0] rf_ra1,
    input [4:0] rf_wa,
    input       rf_we,
    input [31:0]rf_wd,

    output [31:0] rf_rd0,
    output [31:0] rf_rd1

    );
    reg [31:0] reg_file[31:0];

    assign rf_rd0=(rf_ra0==5'b0)?32'b0:reg_file[rf_ra0];
    assign rf_rd1=(rf_ra1==5'b0)?32'b0:reg_file[rf_ra1];

    always @(posedge clk) begin
        if(rf_we)begin
            if(rf_wa!=5'b0)begin
                reg_file[rf_wa]<=rf_wd;
            end
        end
    end

    integer i;//初始化
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            reg_file[i] = 32'b0;
        end
    end
    
endmodule
