`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/22 12:30:33
// Design Name: 
// Module Name: MUX_tb
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

module MUX_tb;

    // Inputs
    reg [3:0] a;
    reg [3:0] b;
    reg s;
    
    // Outputs
    wire [3:0] y;
    
    // Instantiate the Unit Under Test (UUT)
    MUX uut (
        .a(a),
        .b(b),
        .s(s),
        .y(y)
    );
    
    initial begin
        // Initialize Inputs
        a = 4'b0000;
        b = 4'b0000;
        s = 0;
        
        // Wait 100 ns for global reset to finish
        #100;
        
        // Test case 1: s=0, select a
        a = 4'b1010;
        b = 4'b0101;
        s = 0;
        #100;
        $display("Test 1: a=%b, b=%b, s=%b -> y=%b", a, b, s, y);
        
        // Test case 2: s=1, select b
        a = 4'b1010;
        b = 4'b0101;
        s = 1;
        #100;
        $display("Test 2: a=%b, b=%b, s=%b -> y=%b", a, b, s, y);
        
        // Test case 3: Different values
        a = 4'b1100;
        b = 4'b0011;
        s = 0;
        #100;
        $display("Test 3: a=%b, b=%b, s=%b -> y=%b", a, b, s, y);
        
        s = 1;
        #100;
        $display("Test 4: a=%b, b=%b, s=%b -> y=%b", a, b, s, y);
        
        // Test case 4: Edge cases
        a = 4'b0000;
        b = 4'b1111;
        s = 0;
        #100;
        $display("Test 5: a=%b, b=%b, s=%b -> y=%b", a, b, s, y);
        
        s = 1;
        #100;
        $display("Test 6: a=%b, b=%b, s=%b -> y=%b", a, b, s, y);
        
        // Finish simulation
        $finish;
    end
    
endmodule
