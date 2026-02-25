module MissBuffer (//存储写回主存的128位数据和初始地址
    input               clk,
    input               rstn,
    
    input               miss_start,     // 缺失开始信号
    input [127:0]       data1,
    input [127:0]       data2,
    input [19:0]        tag1,       // Way1 读出的旧 Tag
    input [19:0]        tag2,       // Way2 读出的旧 Tag
    input               way, // 建议替换的路,其余上下文来自 Request Buffer
    input [7:0]         index,
    
    output reg [127:0]  wr_data,
    output reg [31:0]   wr_addr,//写请求起始地址
    output reg          reg_way
);
    wire [127:0] data_raw=way ? data2 : data1;
    wire [19:0]  tag_raw=way ? tag2 : tag1;
    wire [31:0] addr_raw={tag_raw, index, 4'b0000};

    // 在缺失启动瞬间锁存所有上下文信息
    always @(posedge clk) begin
        if (!rstn) begin
            reg_way <= 1'b0;
            wr_data <= 128'b0;
            wr_addr <= 32'b0;           
        end 
        else if (miss_start) begin
            reg_way <= way;         // 记录选择了哪一路
            wr_data <= data_raw; // 记录选择路的原始数据
            wr_addr <= addr_raw;
        end
    end
endmodule