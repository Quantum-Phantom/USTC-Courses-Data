module SLU (
    input      [31 : 0] addr,          // 访存地址
    input      [ 3 : 0] dmem_access,    // 访存类型 

    input      [31 : 0] rd_in,         // 从存储器读到的原始 32 位数据 (M[aligned_addr])
    input      [31 : 0] wd_in,         // 寄存器准备写入的数据 (x[rs2])

    output reg [31 : 0] rd_out,        // 处理后写回寄存器的数据
    output reg [31 : 0] wd_out         // 处理后写入存储器的 32 位数据
);

    localparam LB  = 4'b0001;   //加载字节
    localparam LH  = 4'b0010; //加载半字
    localparam LW  = 4'b0011; // 有符号加载字
    localparam LBU = 4'b0100;   //无符号加载字节
    localparam LHU = 4'b0101;   // 无符号加载半字
    localparam SB  = 4'b1001;   //存储字节
    localparam SH  = 4'b1010;   //存储半字
    localparam SW  = 4'b1011; // 存储字
    localparam NO_ACCESS = 4'b0000;

    wire [1:0] offset = addr[1:0]; // 判断当前操作的是四个字节的哪部分

    // --- 读操作处理逻辑 (Load) ---
    always @(*) begin
        case (dmem_access)
            LB: begin // 加载字节并符号扩展
                case (offset)
                    2'b00: rd_out = {{24{rd_in[7]}},  rd_in[7:0]};
                    2'b01: rd_out = {{24{rd_in[15]}}, rd_in[15:8]};
                    2'b10: rd_out = {{24{rd_in[23]}}, rd_in[23:16]};
                    2'b11: rd_out = {{24{rd_in[31]}}, rd_in[31:24]};
                endcase
            end
            LBU: begin // 加载字节并零扩展
                case (offset)
                    2'b00: rd_out = {24'b0, rd_in[7:0]};
                    2'b01: rd_out = {24'b0, rd_in[15:8]};
                    2'b10: rd_out = {24'b0, rd_in[23:16]};
                    2'b11: rd_out = {24'b0, rd_in[31:24]};
                endcase
            end
            LH: begin // 加载半字并符号扩展
                if (offset == 2'b00)      rd_out = {{16{rd_in[15]}}, rd_in[15:0]};
                else if (offset == 2'b10) rd_out = {{16{rd_in[31]}}, rd_in[31:16]};
                else                      rd_out = rd_in; // 非对齐访问不做处理
            end
            LHU: begin // 加载半字并零扩展
                if (offset == 2'b00)      rd_out = {16'b0, rd_in[15:0]};
                else if (offset == 2'b10) rd_out = {16'b0, rd_in[31:16]};
                else                      rd_out = rd_in; // 非对齐访问不做处理
            end
            LW: begin // 加载整字
                rd_out = rd_in;
            end
            default: rd_out = rd_in;
        endcase
    end

    // --- 写操作处理逻辑 (Store) ---
    // 原理：读出原字，只修改目标字节/半字，其余位保持 rd_in 的值
    always @(*) begin
        case (dmem_access)
            SB: begin // 存储字节
                case (offset)
                    2'b00: wd_out = {rd_in[31:8],  wd_in[7:0]};
                    2'b01: wd_out = {rd_in[31:16], wd_in[7:0],  rd_in[7:0]};
                    2'b10: wd_out = {rd_in[31:24], wd_in[7:0],  rd_in[15:0]};
                    2'b11: wd_out = {wd_in[7:0],   rd_in[23:0]};
                endcase
            end
            SH: begin // 存储半字
                if (offset == 2'b00)      wd_out = {rd_in[31:16], wd_in[15:0]};
                else if (offset == 2'b10) wd_out = {wd_in[15:0],  rd_in[15:0]};
                else                      wd_out = wd_in; // 非对齐访问不做处理
            end
            SW: begin // 存储整字
                wd_out = wd_in;
            end
            default: wd_out = wd_in;
        endcase
    end

endmodule