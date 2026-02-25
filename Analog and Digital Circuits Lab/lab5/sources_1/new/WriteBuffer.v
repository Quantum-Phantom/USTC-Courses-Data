module WriteBuffer(
    input               clk,
    input               rstn,

    input [3:0]         wstrb,      // 写字节使能：[3]对应高字节 ... [0]对应低字节
    input               wbuffer_en, // 由 FSM 的 write_hit 信号驱动
    input [7:0]         index,      // 写入的索引
    input [31:0]        wdata,      // 待写入的新数据 (32位)
    input [3:0]         offset,     // 块内偏移，用于确定 bank

    input               way,        // 命中哪一路：0-way0, 1-way1
    input [127:0]       data1,      // Way0 读出的 128 位原始数据
    input [127:0]       data2,      // Way1 读出的 128 位原始数据

    output reg [7:0]    reg_index,  // 寄存后的 index
    output reg [127:0]  reg_wdata,  // 合并后的 128 位数据
    output reg          reg_way,    // 寄存后的 way
    output reg          reg_wen     // 写使能信号
);

    // 1. 根据命中的路选择原始数据
    wire [127:0] data_raw;
    assign data_raw = way ? data2 : data1;

    // 2. 将 128 位数据拆分为 4 个 Bank
    wire [31:0] d [3:0];
    assign d[0] = data_raw[31:0];
    assign d[1] = data_raw[63:32];
    assign d[2] = data_raw[95:64];
    assign d[3] = data_raw[127:96];

    // ---------------------------------------------------------
    // 3. 新增：根据 wstrb 生成“字节掩码合并后的 32 位数据”
    // ---------------------------------------------------------
    wire [31:0] target_bank_old;
    assign target_bank_old = d[offset[3:2]]; // 获取目标位置当前的旧数据

    wire [31:0] merged_bank_data;
    assign merged_bank_data[ 7: 0] = wstrb[0] ? wdata[ 7: 0] : target_bank_old[ 7: 0];
    assign merged_bank_data[15: 8] = wstrb[1] ? wdata[15: 8] : target_bank_old[15: 8];
    assign merged_bank_data[23:16] = wstrb[2] ? wdata[23:16] : target_bank_old[23:16];
    assign merged_bank_data[31:24] = wstrb[3] ? wdata[31:24] : target_bank_old[31:24];

    // 4. 组合逻辑：将合并后的 32 位数据嵌入 128 位行中
    reg [127:0] ddata;
    always @(*) begin
        case(offset[3:2])
            2'b00: ddata = {d[3], d[2], d[1], merged_bank_data};
            2'b01: ddata = {d[3], d[2], merged_bank_data, d[0]};
            2'b10: ddata = {d[3], merged_bank_data, d[1], d[0]};
            2'b11: ddata = {merged_bank_data, d[2], d[1], d[0]};
            default: ddata = data_raw;
        endcase
    end

    // 5. 时序逻辑：锁存信息
    always @(posedge clk) begin
        if(!rstn) begin
            reg_index <= 8'b0;
            reg_wdata <= 128'b0;
            reg_way   <= 1'b0;
            reg_wen   <= 1'b0;
        end
        else if(wbuffer_en) begin
            reg_index <= index;
            reg_wdata <= ddata;     // 此时 ddata 已经处理好了 wstrb 逻辑
            reg_way   <= way;
            reg_wen   <= 1'b1;
        end
        else begin
            reg_wen   <= 1'b0;
        end
    end
endmodule