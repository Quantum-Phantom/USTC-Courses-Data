module REG_FILE(
    input           clk,
    input [4:0]     rf_ra0,
    input [4:0]     rf_ra1,
    input [4:0]     rf_wa,
    input           rf_we,
    input [31:0]    rf_wd,

    output [31:0]   rf_rd0,
    output [31:0]   rf_rd1,

    input  [4:0]    debug_reg_ra, // PDU 传入的查看地址
    output [31:0]   debug_reg_rd  // 输出给 PDU 查看的数据

    );
    reg [31:0] reg_file[31:0];

    assign rf_rd0=(rf_ra0==5'b0)?32'b0:reg_file[rf_ra0];
    assign rf_rd1=(rf_ra1==5'b0)?32'b0:reg_file[rf_ra1];

    assign debug_reg_rd = (debug_reg_ra == 5'b0) ? 32'b0 : reg_file[debug_reg_ra];
    
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
