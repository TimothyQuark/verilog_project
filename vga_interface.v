`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.11.2018 10:49:33
// Design Name: 
// Module Name: vga_interface
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

// This module has become redundant over time, no need for it. Remove when I have
// the time.
module vga_interface(
    input clk, // Remember that this is pix_clk
    input [3:0] r_in,
    input [3:0] g_in,
    input [3:0] b_in,
    
    output [3:0] pix_r,
    output [3:0] pix_g,
    output [3:0] pix_b,
    output hsync,
    output vsync,
    output wire [10:0] curr_x,
    output wire [9:0] curr_y
    );
    
    
    //      Relevant modules for the VGA output
    
    
    vga_out V1 (
        .clk(clk),
        .r_in(r_in),
        .g_in(g_in),
        .b_in(b_in),
        .pix_r(pix_r),
        .pix_b(pix_b),
        .pix_g(pix_g),
        .hsync(hsync),
        .vsync(vsync),
        .curr_x(curr_x),
        .curr_y(curr_y)
        );
   
    

endmodule
