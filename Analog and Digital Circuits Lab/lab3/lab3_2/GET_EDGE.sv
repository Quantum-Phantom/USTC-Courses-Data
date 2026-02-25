module GET_Edge(
    input  clk,
    input  rst,
    input  din,
    output dout_pulse
);

    reg [1:0] din_sync;
    reg [1:0] pulse_counter;
    
    always @(posedge clk) begin
        if (rst) begin
            din_sync <= 2'b00;
            pulse_counter <= 2'b00;
        end else begin
            din_sync <= {din_sync[0], din};
            
            // 检测上升沿并启动两周期计数
            if (din_sync == 2'b01)  // 上升沿
                pulse_counter <= 2'b11;  // 二进制11表示持续两周期
            else if (pulse_counter != 2'b00)
                pulse_counter <= pulse_counter - 1'b1;
        end
    end
    
    assign dout_pulse = (pulse_counter != 2'b00);
    
endmodule