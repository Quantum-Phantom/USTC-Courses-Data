`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/03 11:11:18
// Design Name: 
// Module Name: BUBBLE
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


module BUBBLE (
    input  wire        clk,        // 时钟信号
    input  wire        rst_n,      // 复位信号（低有效）- 同步复位
    input  wire        start,      // 启动信号
    output reg         done,       // 完成标志
    output reg  [15:0] round_count,      // 时钟周期计数
    
    // BRAM接口
    output wire [9:0]  bram_addr,  // BRAM地址
    output wire        bram_we,    // BRAM写使能
    output wire [31:0] bram_din,   // BRAM写入数据
    input  wire [31:0] bram_dout   // BRAM读出数据
);

localparam [3:0] 
    INIT        = 4'd0,
    RDA         = 4'd1,
    RDB         = 4'd2,
    CMP         = 4'd3,
    SWAP_STA    = 4'd4,
    SWAP_STB    = 4'd5,
    CHECK_ROUND = 4'd6,
    NEW_ROUND   = 4'd7,  // 新增：新轮次开始
    DONE        = 4'd8;

// 内部寄存器
reg [3:0]  current_state, next_state;
reg [9:0]  pointer_p;      // 内存地址指针
reg        flag_s;         // 交换标志
reg [31:0] reg_a, reg_b;   // 数据寄存器A和B
reg [9:0]  n_minus_1;      // N-1计算值

// 状态寄存器 - 同步复位
always @(posedge clk) begin
    if (!rst_n)
        current_state <= INIT;
    else
        current_state <= next_state;
end

// 下一状态逻辑
always @(*) begin
    case (current_state)
        INIT: begin
            if (start)
                next_state = RDA;  // 启动排序，进入初始轮次
            else
                next_state = INIT;
        end        
        RDA:         next_state = RDB;
        RDB:         next_state = CMP;
        CMP: begin
            if (reg_a > reg_b)            // 使用寄存器值的组合比较结果决定下一状态，避免对延迟的
                next_state = CHECK_ROUND;  // 顺序正确，不交换
            else
                next_state = SWAP_STA;   // 需要交换
        end
        SWAP_STA:    next_state = SWAP_STB;
        SWAP_STB:    next_state = CHECK_ROUND;
        CHECK_ROUND: begin
            if (pointer_p >= n_minus_1) begin//
                if (flag_s && (n_minus_1 > 1))  // 若n_minus_1=1，说明当前周期只剩2个数，以完成排序，可以结束
                    next_state = NEW_ROUND;
                else
                    next_state = DONE;  // 排序完成
            end 
            else begin
                next_state = RDA;  // 继续当前轮
            end
        end
        NEW_ROUND:   next_state = RDA;  // 新轮次开始，直接进入RDA
        DONE:        next_state = DONE;
        default:     next_state = INIT;
    endcase
end

// 数据路径控制 - 同步复位
always @(posedge clk) begin
    if (!rst_n) begin
        pointer_p    <= 10'd0;
        flag_s       <= 1'b0;
        reg_a        <= 32'd0;
        reg_b        <= 32'd0;
        round_count  <= 10'd0;
        n_minus_1    <= 10'd1023;
        done         <= 1'b0;
    end 
    else begin
        case (current_state)
            INIT: begin
                // 复位所有信号
                pointer_p   <= 10'd0;
                flag_s      <= 1'b0;
                reg_a       <= 32'd0;
                reg_b       <= 32'd0;
                round_count <= 10'd0;
                n_minus_1   <= 10'd1023;
                done        <= 1'b0;
            end
            
            RDA: begin
                reg_a <= bram_dout;     // 读取M[P]到A
                pointer_p <= pointer_p + 1;  // P = P + 1
            end
            
            RDB: begin
                reg_b <= bram_dout;     // 读取M[P]到B
            end
            
            CMP: begin
                // 比较结果在组合次态逻辑中直接使用 reg_a < reg_b。
            end
            
            SWAP_STA: begin
                // M[P] = A 在组合逻辑中处理
                pointer_p <= pointer_p - 1;  // P = P - 1
                flag_s <= 1'b1;              // S = 1
            end
            
            SWAP_STB: begin
                // M[P] = B 在组合逻辑中处理
                pointer_p <= pointer_p + 1;  // P = P + 1
            end
                        
            CHECK_ROUND: begin
                if (pointer_p >= n_minus_1) begin
                    // 完成一轮排序
                    pointer_p <= 10'd0;
                    round_count <= round_count + 1;

                    if (n_minus_1> 1) begin//n_minus_1 - 1>1,当前周期结束后还剩至少两个数,还需要排序
                        n_minus_1 <= n_minus_1 - 1;
                    end
                    flag_s <= 1'b0;  // 重置交换标志
                end
            end
            
            NEW_ROUND: begin
                // 新轮次开始，只重置指针和交换标志
                pointer_p <= 10'd0;
                flag_s <= 1'b0;
            end
            
            DONE: 
                done <= 1'b1;
        endcase
    end
end

// BRAM接口控制
assign bram_addr = pointer_p;
assign bram_we = ((current_state == SWAP_STA) || (current_state == SWAP_STB)) ? 1'b1 : 1'b0;
assign bram_din = (current_state == SWAP_STA) ? reg_a : 
                  (current_state == SWAP_STB) ? reg_b : 32'd0;

endmodule