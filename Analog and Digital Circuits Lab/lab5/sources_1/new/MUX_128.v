module MUX_128(
    input [127:0]       r_data1,
    input [127:0]       r_data2,
    input [127:0]       m_data,   // 来自 ReturnBuffer 的数据
    input [3:0]         offset,
    input [1:0]         hit,      // 01: way1 hit, 10: way2 hit, 00: miss

    output reg [31:0]   rdata
);
    reg [127:0] selected_line;

    // 第一级：路选择
    always @(*) begin
        case(hit)
            2'b01:   selected_line = r_data1;
            2'b10:   selected_line = r_data2;
            2'b00:   selected_line = m_data; // 缺失时直接从返回缓冲读取
            default: selected_line = 128'b0;
        endcase
    end

    // 第二级：Bank 选择 (字选择)
    always @(*) begin
        // 使用位选择语法更加简洁：selected_line[offset[3:2]*32 +: 32]
        case(offset[3:2])
            2'b00:   rdata = selected_line[31:0];
            2'b01:   rdata = selected_line[63:32];
            2'b10:   rdata = selected_line[95:64];
            2'b11:   rdata = selected_line[127:96];
            default: rdata = 32'b0;
        endcase
    end 
endmodule