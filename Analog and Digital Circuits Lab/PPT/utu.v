`timescale 1ns / 1ps

module  utu(
        input clk,            //clk100mhz
        input rstn,           //resetn
        
        input [15:0] x,       //sw15-0
        input del,            //btnl
	input ent,            //btnc
	input pre,            //btnu	
        input nxt,            //btnd
        input step,           //btnr
        
        output [15:0] taddr,  //测试端口地址，led15-0 
        input [31:0] tdin,    //测试数据输入
	output [31:0] tdout,  //测试数据输出		
	output twe,	      //测试数据写使能

        output [2:0] flag,    //led16，指示数码管显示的数据类型
        output [7:0] an,      //an7-0
        output [6:0] seg,     //ca-cg
       
        output rst,
        output reg tclk       //dut's clk
    );
	
    reg [15:0] rstn_r;
    
    wire clk_db;                //去抖动计数器时钟
    reg [19:0] cnt_clk_r;       //时钟分频、数码管刷新计数器	
    reg [4:0] cnt_sw_db_r;
    reg [15:0] x_db_r, x_db_1r;
    reg xx_r, xx_1r;
    wire x_p;
    reg [3:0] x_hd_t;
    reg [31:0] tmp_r;           //临时编辑数据

    reg x_p_flag;

    wire [4:0] btn;
    reg [4:0] cnt_btn_db_r;
    reg [4:0] btn_db_r, btn_db_1r;
    wire  pre_p,nxt_p, step_p,ent_p, del_p;

    reg [2:0] seg_sel_r;
    reg [31:0] disp_data_t;
    reg [7:0] an_t;
    reg [3:0] hd_t;
    reg [6:0] seg_t;
    
    reg [15:0] addr_r;               //待测模块地址

    assign rst = rstn_r[15];         //经处理后的复位信号，高电平有效
    assign clk_db = cnt_clk_r[16];   //去抖动计数器时钟763Hz（周期约1.3ms）

    assign taddr[15:0] =  addr_r ;
    assign flag[2:0]= seg_sel_r;
    assign an = an_t;
    assign seg = seg_t;

    assign tdout = tmp_r;      //开关输入至待测模块数据
    assign taddr = addr_r;
    assign twe = ent_p;        //写使能持续一个时钟周期

    assign btn ={pre, nxt, step, ent,del};
	
    assign x_p = xx_r ^ xx_1r;
    assign pre_p = btn_db_r[4] & ~ btn_db_1r[4];
    assign nxt_p = btn_db_r[3] & ~ btn_db_1r[3];
    assign step_p = btn_db_r[2] & ~ btn_db_1r[2];
    assign ent_p = btn_db_r[1] & ~ btn_db_1r[1];
    assign del_p = btn_db_r[0] & ~ btn_db_1r[0];


    ///////////////////////////////////////////////
    //复位处理：异步复位、同步和延迟释放
    ///////////////////////////////////////////////

    always @(posedge clk, negedge rstn) begin
        if (~rstn)
            rstn_r <= 16'hFFFF;
        else
            rstn_r <= {rstn_r[14:0], 1'b0};
    end


    ///////////////////////////////////////////////
    //时钟分频
    ///////////////////////////////////////////////

    always @(posedge clk, posedge rst) begin
        if (rst)
            cnt_clk_r <= 20'h0;
        else
            cnt_clk_r <= cnt_clk_r + 20'h1;
    end


    ///////////////////////////////////////////////
    //开关sw去抖动
    ///////////////////////////////////////////////

    always @(posedge clk_db, posedge rst) begin
        if (rst)
            cnt_sw_db_r <= 5'h0;
        else if ((|(x ^ x_db_r)) & (~ cnt_sw_db_r[4])) 
            cnt_sw_db_r <= cnt_sw_db_r + 5'h1;
        else
            cnt_sw_db_r <= 5'h0;
    end

    always@(posedge clk_db, posedge rst) begin
        if (rst) begin
            x_db_r <= x;
            x_db_1r <= x;
            xx_r <= 1'b0;
        end
        else if (cnt_sw_db_r[4]) begin    //信号稳定约21ms后输出
            x_db_r <= x;
            x_db_1r <= x_db_r;
            xx_r <= ~xx_r;		  //构造x_p信号
        end
    end

    always @(posedge clk, posedge rst) begin
        if (rst)
            xx_1r <= 1'b0;
        else
            xx_1r <= xx_r;
    end


    ///////////////////////////////////////////////
    //开关编辑数据
    ///////////////////////////////////////////////

    always @* begin                //开关输入编码
        case (x_db_r ^ x_db_1r )
            16'h0001:
                x_hd_t = 4'h0;
            16'h0002:
                x_hd_t = 4'h1;
            16'h0004:
                x_hd_t = 4'h2;
            16'h0008:
                x_hd_t = 4'h3;
            16'h0010:
                x_hd_t = 4'h4;
            16'h0020:
                x_hd_t = 4'h5;
            16'h0040:
                x_hd_t = 4'h6;
            16'h0080:
                x_hd_t = 4'h7;
            16'h0100:
                x_hd_t = 4'h8;
            16'h0200:
                x_hd_t = 4'h9;
            16'h0400:
                x_hd_t = 4'hA;
            16'h0800:
                x_hd_t = 4'hB;
            16'h1000:
                x_hd_t = 4'hC;
            16'h2000:
                x_hd_t = 4'hD;
            16'h4000:
                x_hd_t = 4'hE;
            16'h8000:
                x_hd_t = 4'hF;
            default:
                x_hd_t = 4'h0;
        endcase
    end

    always @(posedge clk, posedge rst) begin
        if (rst)
            tmp_r <= 32'h0;
        else if (x_p)
            tmp_r <= {tmp_r[27:0], x_hd_t};      //x_hd_t + tmp_r << 4
        else if (del_p)
            tmp_r <= {{4{1'b0}}, tmp_r[31:4]};   //tmp_r >> 4
        else if (ent_p )                         //数据输入完成清零tmp_r
            tmp_r <= 32'h0;	
        else if ((pre_p | nxt_p) & x_p_flag)
            tmp_r <= 32'h0;		
    end    


    ///////////////////////////////////////////////
    //按钮btn去抖动
    ///////////////////////////////////////////////

    always @(posedge clk_db, posedge rst) begin
        if (rst)
            cnt_btn_db_r <= 5'h0;
        else if ((|(btn ^ btn_db_r)) & (~ cnt_btn_db_r[4]))
            cnt_btn_db_r <= cnt_btn_db_r + 5'h1;
        else
            cnt_btn_db_r <= 5'h0;
    end

    always@(posedge clk_db, posedge rst) begin  
        if (rst)
            btn_db_r <= btn;
        else if (cnt_btn_db_r[4])
            btn_db_r <= btn;
    end

    always @(posedge clk, posedge rst) begin   
        if (rst)
            btn_db_1r <= btn;
        else
            btn_db_1r <= btn_db_r;
    end  
 
   
    ///////////////////////////////////////////////
    //addr输出
    ///////////////////////////////////////////////

    always @(posedge clk, posedge rst) begin
        if (rst) 
            addr_r <= 16'h0000;
		else if (ent_p)
            addr_r <= 16'h0000;			
        else if (pre_p)
		     if (x_p_flag)
				 addr_r <= tmp_r;
			 else addr_r <= addr_r - 1;
		else if (nxt_p) 
		      if (x_p_flag)
				 addr_r <= tmp_r;	
			else addr_r <= addr_r + 1;
    end
	
    always @(posedge clk, posedge rst) begin
        if (rst)
            x_p_flag <= 0;
        else if (x_p)
            x_p_flag <= 1;      
        else if (pre_p| nxt_p)
            x_p_flag <= 0;
    end 
 
 
    ///////////////////////////////////////////////
    //数码管显示数据来源
    ///////////////////////////////////////////////

    always @(posedge clk, posedge rst) begin    //数码管显示数据选择
        if (rst)
            seg_sel_r <= 3'b001;
		else if( pre_p| nxt_p| ent_p)
            seg_sel_r <= 3'b001;                
        else if (x_p | del_p)
            seg_sel_r <= 3'b010;                	
    end 
	
	always @* begin
        case (seg_sel_r)
            3'b001:
                disp_data_t = tdin;             //显示dut输入及输出数据
            3'b010:
                disp_data_t = tmp_r ;	        //显示开关编辑数据			
            default:
                disp_data_t = tdin;
        endcase
    end

	
    ///////////////////////////////////////////////
    //数码管扫描原理
    ///////////////////////////////////////////////

    always @(*) begin                  //数码管扫描
        an_t <= 8'b1111_1111;
        hd_t <= disp_data_t[3:0];
        if (&cnt_clk_r[16:15])         //降低亮度
        case (cnt_clk_r[19:17])        //刷新频率约为95Hz
            3'b000: begin
                an_t <= 8'b1111_1110;
                hd_t <= disp_data_t[3:0];
            end
            3'b001: begin
                an_t <= 8'b1111_1101;
                hd_t <= disp_data_t[7:4];
            end
            3'b010: begin
                an_t <= 8'b1111_1011;
                hd_t <= disp_data_t[11:8];
            end
            3'b011: begin
                an_t <= 8'b1111_0111;
                hd_t <= disp_data_t[15:12];
            end
            3'b100: begin
                an_t <= 8'b1110_1111;
                hd_t <= disp_data_t[19:16];
            end
            3'b101: begin
                an_t <= 8'b1101_1111;
                hd_t <= disp_data_t[23:20];
            end
            3'b110: begin
                an_t <= 8'b1011_1111;
                hd_t <= disp_data_t[27:24];
            end
            3'b111: begin
                an_t <= 8'b0111_1111;
                hd_t <= disp_data_t[31:28];
            end
            default:
                ;
        endcase
    end

    always @ (*) begin    //7段译码
        case(hd_t)
            4'b1111:
                seg_t = 7'b0111000;
            4'b1110:
                seg_t = 7'b0110000;
            4'b1101:
                seg_t = 7'b1000010;
            4'b1100:
                seg_t = 7'b0110001;
            4'b1011:
                seg_t = 7'b1100000;
            4'b1010:
                seg_t = 7'b0001000;
            4'b1001:
                seg_t = 7'b0001100;
            4'b1000:
                seg_t = 7'b0000000;
            4'b0111:
                seg_t = 7'b0001111;
            4'b0110:
                seg_t = 7'b0100000;
            4'b0101:
                seg_t = 7'b0100100;
            4'b0100:
                seg_t = 7'b1001100;
            4'b0011:
                seg_t = 7'b0000110;
            4'b0010:
                seg_t = 7'b0010010;
            4'b0001:
                seg_t = 7'b1001111;
            4'b0000:
                seg_t = 7'b0000001;
            default:
                seg_t = 7'b1111111;
        endcase
    end

	
    ///////////////////////////////////////////////
    //dut控制时钟
    ///////////////////////////////////////////////

    always @(posedge clk, posedge rst) begin
        if (rst)
            tclk <= 1'b0;
        else if (step_p)
            tclk <= 1'b1;
        else 
            tclk <= 1'b0;
    end

endmodule

