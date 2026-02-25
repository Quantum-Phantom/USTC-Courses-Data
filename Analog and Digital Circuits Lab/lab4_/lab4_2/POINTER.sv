`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/26 15:51:30
// Design Name: 
// Module Name: POINTER
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


module POINTER (
    input           clk,
    input           rstn,
    input           inc_front,    // 增加队头指针信号
    input           inc_rear,     // 增加队尾指针信号
    output reg[4:0] front_ptr,     //5位指针 0~16,为了取模运算吧
    output reg[4:0] rear_ptr,      // 
    output          empty,                   // 空状态
    output          full                     // 满状态
);

    localparam DEPTH = 16; // FIFO深度,默认十进制
    reg [4:0] count;

    always @(posedge clk) begin
        if (!rstn) begin
            front_ptr <= 0;//复位时指针归0，第一个数是1吧
            rear_ptr <= 0;
            count <= 0;
        end 
        else begin
            case ({inc_rear, inc_front})
                2'b01: begin  // 只读：队头指针增加，计数器减1
                    front_ptr <= (front_ptr + 1)% DEPTH;
                    count <= count - 1;
                end
                2'b10: begin  // 只写：队尾指针增加，计数器加1
                    rear_ptr <= (rear_ptr + 1) % DEPTH;
                    count <= count + 1;
                end
                2'b11: begin  // 同时读写：两个指针都增加，计数器不变
                    front_ptr <= (front_ptr + 1)% DEPTH;
                    rear_ptr <= (rear_ptr + 1) % DEPTH;
                end
                default:begin
                    front_ptr <= front_ptr;
                    rear_ptr <= rear_ptr;
                    count <= count;
                end
            endcase
        end
    end
    
    // 状态信号输出
    assign empty = (count == 0);
    assign full = (count == 16);  // FIFO深度为16

endmodule
