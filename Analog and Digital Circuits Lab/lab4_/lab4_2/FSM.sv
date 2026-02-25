`timescale 1ns / 1ps

module FSM (
    input           clk,
    input           rstn,
    // 外部请求信号
    input           wr_request,    // 写请求（已去抖动和边沿检测）
    input           rd_request,    // 读请求（已去抖动和边沿检测）
    // 状态信号（从POINTER模块来）
    input           empty,         // 空状态
    input           full,          // 满状态
    // 控制信号输出
    output reg      wr_en,         // 寄存器堆写使能
    output reg      inc_front,     // 增加队头指针信号
    output reg      inc_rear       // 增加队尾指针信号
    // 数据输出
);

    // 内部状态定义
    reg [1:0] current_state, next_state;
    localparam IDLE        = 2'b00;
    localparam WRITE_ONLY  = 2'b01;
    localparam READ_ONLY   = 2'b10;
    localparam READ_WRITE  = 2'b11;
    
    // 状态寄存器
    always @(posedge clk) begin
        if (!rstn) begin
            current_state <= IDLE;
        end 
        else begin
            current_state <= next_state;
        end
    end
    
    // 下一状态逻辑 - 支持连续操作
    always @(*) begin
        next_state = current_state;  // 默认保持当前状态
        
        case (current_state)
            IDLE: begin
                if (wr_request && rd_request) begin
                    next_state = READ_WRITE;
                end 
                else if (wr_request && !full) begin
                    next_state = WRITE_ONLY;
                end 
                else if (rd_request && !empty) begin
                    next_state = READ_ONLY;
                end 
                else begin
                    next_state = IDLE;
                end
            end
            
            WRITE_ONLY: begin
                if (wr_request && rd_request) begin
                    next_state = READ_WRITE;
                end 
                else if (rd_request && !empty) begin
                    next_state = READ_WRITE;
                end 
                else if (wr_request && !full) begin
                    next_state = WRITE_ONLY;  // 继续写操作
                end 
                else begin
                    next_state = IDLE;  // 没有请求时返回IDLE
                end
            end
            
            READ_ONLY: begin
                if (wr_request && rd_request) begin
                    next_state = READ_WRITE;
                end 
                else if (wr_request && !full) begin
                    next_state = WRITE_ONLY;
                end 
                else if (rd_request && !empty) begin
                    next_state = READ_ONLY;  // 继续读操作
                end 
                else begin
                    next_state = IDLE;  // 没有请求时返回IDLE
                end
            end
            
            READ_WRITE: begin
                if (wr_request && rd_request) begin
                    next_state = READ_WRITE;  // 继续同时读写
                end 
                else if (wr_request && !full) begin
                    next_state = WRITE_ONLY;  // 转为只写
                end 
                else if (rd_request && !empty) begin
                    next_state = READ_ONLY;   // 转为只读
                end 
                else begin
                    next_state = IDLE;        // 没有请求时返回IDLE
                end
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 输出逻辑和控制信号生成
    always @(posedge clk) begin
        if (!rstn) begin
            wr_en <= 1'b0;
            inc_front <= 1'b0;
            inc_rear <= 1'b0;
        end 
        else begin
            // 默认值
            wr_en <= 1'b0;
            inc_front <= 1'b0;
            inc_rear <= 1'b0;
            
            case (next_state)
                IDLE: ;
                
                WRITE_ONLY: begin
                    if (!full) begin
                        wr_en <= 1'b1;      // 使能寄存器堆写入
                        inc_rear <= 1'b1;  // 增加队尾指针
                    end
                end
                
                READ_ONLY: begin
                    if (!empty) begin
                        inc_front <= 1'b1; // 增加队头指针
                    end
                end
                
                READ_WRITE: begin
                    if (!empty) begin
                        inc_front <= 1'b1;    // 增加队头指针
                    end
    
                // 总是允许写入（满足实验要求的满队列特殊处理）
                    wr_en <= 1'b1;           // 写入新数据
                    inc_rear <= 1'b1;        // 增加队尾指针
                end                  
                default: ;  // 保持默认值
            endcase
            
            // 数据输出寄存器（在rd_en有效时更新）
            // 注意：实际数据来自寄存器堆，需要在顶层模块中连接
        end
    end

endmodule