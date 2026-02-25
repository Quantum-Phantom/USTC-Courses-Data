module LRU(//初始是什么都无所谓吧，只有hit后才会出问题
    input           clk,
    input           rstn,    
    input [7:0]     index,
    input [1:0]     hit,
    input           refill_ready,
    input           ms_way,      // 正在重填的那一路
    output          way_select   // 建议替换哪一路 (组合逻辑输出)
);

    reg LRU_mem [0:255]; // 1位表示：0->Way0是LRU, 1->Way1是LRU

    assign way_select = LRU_mem[index];

    // 2. 时序逻辑：更新 LRU 状态
    integer i;
    always @(posedge clk) begin
        if (!rstn) begin
            for (i = 0; i < 256; i = i + 1) begin
                LRU_mem[i] <= 1'b0;
            end
        end
        else
            if (hit == 2'b01) begin
                // 命中 Way 0 (bit 0)，则 Way 1 变成最近最少使用 (LRU)
                LRU_mem[index] <= 1'b1;
            end
            else if (hit == 2'b10) begin
                // 命中 Way 1 (bit 1)，则 Way 0 变成最近最少使用 (LRU)
                LRU_mem[index] <= 1'b0;
            end
            else if (refill_ready) begin
                // 缺失重填完成，比如填入了 Way 0，则下一轮 Way 1 应该是 LRU
                LRU_mem[index] <= ~ms_way;
        end
        // 这里的 else 无需赋值，保持原状即实现了寄存器存储
    end

endmodule