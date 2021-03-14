`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.11.2018 17:34:45
// Design Name: 
// Module Name: doubledabble14bit
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


// This module only works for numbers up 2^14 - 1 = 16383
module doubledabble14bit(
    //input clk,
    input [13:0] bin, // Input binary value, i.e. the value to convert
    output [15:0] bcd // The number converted to binary coded decimal
    );
    
    reg [19:0] bcd_reg; // Stores the binary coded dedcimal
    integer i;    // How many iterations we are going to be doing
    
    always @(bin)
        begin
            bcd_reg = 20'b0; //Set to 0 by default
            
            for ( i = 1'b0 ; i <= 5'd13; i = i + 1'b1)
            begin
                if ( bcd_reg[19:16] >= 4'd5) // 
                    bcd_reg[19:16] = bcd_reg[19:16] + 4'd3;
                if ( bcd_reg[15:12] >= 4'd5)
                    bcd_reg[15:12] = bcd_reg[15:12] + 4'd3;
                if ( bcd_reg[11:8] >= 4'd5)
                    bcd_reg[11:8] = bcd_reg[11:8] + 4'd3;
                if ( bcd_reg[7:4] >= 4'd5)
                    bcd_reg[7:4] = bcd_reg[7:4] + 4'd3;
                if ( bcd_reg[3:0] >= 4'd5)
                    bcd_reg[3:0] = bcd_reg[3:0] + 4'd3;
                    
                bcd_reg = bcd_reg << 1'b1;
                bcd_reg[0] = bin[5'd13 - i];
                
            end
       end
       
      assign bcd = bcd_reg[15:0];   // We discard the ten thousands digit because we cannot show it on the LED display.
      
endmodule



module doubledabble9bit(
    //input clk,
    input [8:0] bin,
    output [11:0] bcd
    );
    
    reg [11:0] bcd_reg; 
    integer i;    // How many iterations we are going to be doing
    
    always @(bin)
        begin
            bcd_reg = 20'b0; //Set to 0 by default
            
            for ( i = 1'b0 ; i <= 5'd8; i = i + 1'b1)
            begin
                if ( bcd_reg[11:8] >= 4'd5)
                    bcd_reg[11:8] = bcd_reg[11:8] + 4'd3;
                if ( bcd_reg[7:4] >= 4'd5)
                    bcd_reg[7:4] = bcd_reg[7:4] + 4'd3;
                if ( bcd_reg[3:0] >= 4'd5)
                    bcd_reg[3:0] = bcd_reg[3:0] + 4'd3;
                    
                bcd_reg = bcd_reg << 1'b1;
                bcd_reg[0] = bin[5'd8 -i];
                
            end
       end
    
    assign bcd = bcd_reg;
    
endmodule
