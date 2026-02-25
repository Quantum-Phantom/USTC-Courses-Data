`timescale 1ns / 1ps

module FSM (
    input               clk,
    input               rstn,

    // 来自 Request Buffer 的控制信号
    input               valid,          // CPU 请求有效
    input               op,             // 1: WRITE, 0: READ
    input [1:0]         hit,            // 01:way1  10:way2
    input               select_valid,   // 选择的替换路有效

    // 来自 AXI 总线接口的握手信号
    input               wr_rdy,         // AXI 写就绪
    input               rd_rdy,         // AXI 读就绪
    input               refill_ready,   // 重填数据准备好
    output reg          wr_req,
    output reg          rd_req,

    // 输出信号
    output reg          write_hit,      // 写命中阻塞信号
    output reg          miss,           // 缺失处理阻塞信号
    output reg          addr_ok,        //Cache 已准备好接收 CPU 发送的新地址请求
    output reg          data_ok,        //Cache 已完成当前请求的数据交互
    output reg          miss_start
);

    // 状态定义 
    localparam IDLE      = 6'b000001;
    localparam LOOKUP    = 6'b000010;
    localparam WRITE_HIT = 6'b000100;
    localparam MISS      = 6'b001000;
    localparam REPLACE   = 6'b010000;
    localparam REFILL    = 6'b100000;

    reg [5:0] current_state;
    reg [5:0] next_state;
    reg       ready_seen; // 用于记录在 REFILL 状态下是否已经捕捉到了那一个脉冲

    always @(posedge clk) begin
        if (!rstn) begin
            current_state <= IDLE;
            ready_seen    <= 1'b0;
        end else begin
            current_state <= next_state;
            // 记录脉冲捕捉状态
            if (current_state == REFILL && refill_ready)
                ready_seen <= 1'b1;
            else if (current_state == IDLE)
                ready_seen <= 1'b0;
        end
    end

    // 2. 合并后的次态计算与输出控制 (组合逻辑)
    always @(*) begin
        // --- 设置默认值，防止产生锁存器 (Latch) ---
        next_state = current_state;
        miss       = 1'b0;
        write_hit  = 1'b0;
        addr_ok    = 1'b0;  //除非在某个状态下显式地将它设为 1，否则默认为 0
        data_ok    = 1'b0;
        miss_start = 1'b0;
        wr_req     = 1'b0;
        rd_req     = 1'b0;

        case (current_state)
            IDLE: begin
                addr_ok = 1'b1; // IDLE 状态随时准备接收新请求
                if (valid) begin
                    next_state = LOOKUP;
                end
            end
            LOOKUP: begin
                if (hit == 2'b01 || hit == 2'b10) begin // 命中
                    if (op) begin
                        next_state = WRITE_HIT;
                        write_hit  = 1'b1;
                    end 
                    else begin
                        data_ok = 1'b1;   // 读命中直接给数据确认
                        addr_ok = 1'b1;   // 允许下一条指令进入
                        if (valid) begin
                            next_state = LOOKUP; // 连续命中读
                        end 
                        else begin
                            next_state = IDLE;
                        end
                    end
                end 
                else begin // 缺失
                    next_state = MISS;
                    miss       = 1'b1;
                    miss_start = 1'b1;
                end
            end

            WRITE_HIT: begin
                next_state = IDLE;
                data_ok    = 1'b1;
            end

            MISS: begin
                miss = 1'b1;
                if (wr_rdy) //不管是否要写回，都转移到 REPLACE 状态
                    next_state = REPLACE;
                else
                    next_state = MISS;
            end

            REPLACE: begin
                miss   = 1'b1;
                if(select_valid)//确保替换路有效的时候再写回内存，否则不用
                    wr_req = 1'b1; // 向 AXI 发起写回请求
                if (rd_rdy)begin
                    next_state = REFILL;
                    rd_req     = 1'b1; // 向 AXI 发起读请求
                end
                else
                    next_state = REPLACE;
            end

            REFILL: begin
                miss   = 1'b1;
                if (ready_seen && !refill_ready) begin//refill_ready为高后空转一个周期，等数据进入WBUFFER
                    next_state = IDLE;
                    data_ok    = 1'b1; // 在跳回 IDLE 的同时确认数据有效
                end
                else begin
                    next_state = REFILL;
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule