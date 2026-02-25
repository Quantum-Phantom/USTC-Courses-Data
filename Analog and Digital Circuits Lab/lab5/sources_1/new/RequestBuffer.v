module RequestBuffer(
    input           clk,
    input           rstn,

    // CPU流水线接口
    input wire [7:0]    index,      // 地址的index域(addr[11:4])
    input wire [19:0]   tag,        // 虚拟地址转换后paddr形成的tag，来自组合逻辑计算，与index是同拍信号
    input wire [3:0]    offset,     // 地址的offset域(addr[3:0]) 
    input wire [31:0]   wdata,      // 写数据
    input wire [3:0]    wstrb,      // 写字节使能
    input               op,         // 读写操作类型 (1: 写, 0: 读) --- IGNORE ---

    input               write_hit,  //write_hit时阻塞
    input               miss,       //miss时阻塞

    output reg [7:0]    reg_index, 
    output reg [19:0]   reg_tag,   
    output reg [3:0]    reg_offset,
    output reg [31:0]   reg_wdata,
    output reg [3:0]    reg_wstrb,
    output reg          reg_op     
);
    // 计算流水线使能信号：只有在不发生写命中阻塞且不发生缺失阻塞时，才允许存入新请求
    // 在阻塞式 Cache 中，发生 miss 或正在处理写命中时，Request Buffer 必须维持原值
    wire stall = write_hit || miss;

    always @(posedge clk) begin
        if (!rstn) begin
            reg_index  <= 8'd0;
            reg_tag    <= 20'd0;
            reg_offset <= 4'd0;
            reg_wdata  <= 32'd0;
            reg_wstrb  <= 4'd0;
            reg_op     <= 1'b0;
        end 
        else if (!stall) begin
            reg_index  <= index;
            reg_tag    <= tag;    // tag 采样来自转换后的物理地址
            reg_offset <= offset;
            reg_wdata  <= wdata;
            reg_wstrb  <= wstrb;
            reg_op     <= op;     
        end
        // else: stall 为高时，寄存器隐式保持上一个时钟周期的值
    end

endmodule