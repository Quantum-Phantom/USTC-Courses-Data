module TagVMemory(//BRAM同步读写，不可异步读
    input               clk,
    input               rstn,

    input [7:0]         index,
    input               w_en,//和DataMemory同步，写入数据时同时写入Tag
    input [19:0]        w_tag,//

    output reg [19:0]   tag,//以块为单位读出
    output reg          v//0无效，1有效（有数据写入后就有效了）
    );

    reg        v_mem [0:255];    // 有效位存储器
    reg [19:0] tag_mem [0:255];  // Tag存储器
    
    // 同步读写逻辑
    integer i;
    always @(posedge clk) begin
        if (!rstn) begin
            // 复位：清空所有内容
            for (i = 0; i < 256; i = i + 1) begin
                v_mem[i] <= 1'b0;      // 所有有效位置0
                tag_mem[i] <= 20'b0;   // 所有Tag清零
            end
            tag <= 20'b0;
            v <= 1'b0;
        end
        else begin
            // 同步读：每个时钟周期都读出对应地址的数据
            tag <= tag_mem[index];
            v <= v_mem[index];
            
            // 同步写：写使能时更新存储
            if (w_en) begin
                tag_mem[index] <= w_tag;
                v_mem[index] <= 1'b1;  // 写入后立即有效
            end
        end
    end

endmodule