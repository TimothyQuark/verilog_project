`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.11.2018 16:55:46
// Design Name: 
// Module Name: seginterface2
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


module seginterface2(
    input clk, // The on board clock
    input [13:0] score, // The binary encoded score, directly from the data holder module
    input [8:0] g_time, // The binary encoded game time, from data holde rmodule
    output a,b,c,d,e,f,g, // Signals for the segment display
    output [7:0] an // The anode signals, used to drive each of the segment LEDs
    );
    
    wire led_clk; // LED clock
    reg [3:0] dig_sel; // The value of the LED we want to update
    
    reg[28:0] clk_count = 11'd0; // Clock counter
    
    always @(posedge clk)
    begin
        clk_count <= clk_count + 1'b1; // Increment the clock counter
    end
    
    assign led_clk = clk_count[16]; // LED clock is much slower than clock counter
    
    reg [7:0] led_strobe = 8'b11111110; // The 0 term controls which segment is active and being changed
    always @(posedge led_clk)
        led_strobe <= {led_strobe[6:0],led_strobe[7]}; // Shift the led_strobe to change the active segment
    assign an = led_strobe; // Physically change the active anode
    
    reg [2:0] led_index = 3'd0; // Which LED do we want to update
    always @(posedge led_clk)
            led_index <= led_index + 1'b1;
            
    wire [3:0] dig7, dig6, dig5, dig4, dig2, dig1, dig0; // The different LED values we store
    wire [3:0] dig3 = 4'hF;
    
    always @*
    case (led_index) // Depending on which LED currently want to check, we assign a value to dig_sel
        3'd0: dig_sel = dig0;
        3'd1: dig_sel = dig1;
        3'd2: dig_sel = dig2;
        3'd3: dig_sel = dig3;
        3'd4: dig_sel = dig4;
        3'd5: dig_sel = dig5;
        3'd6: dig_sel = dig6;
        3'd7: dig_sel = dig7;
        
    endcase

    
    sevenseg M1 (.num(dig_sel), .a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g) ); // Output dig_sel to segments
    doubledabble14bit D1 (.bin(score), .bcd( {dig7, dig6, dig5, dig4}) ); // Convert binary to BCD
    doubledabble9bit D2 (.bin(g_time), .bcd( {dig2, dig1, dig0} ) ); // Convert binary to BCD
    
    
endmodule
