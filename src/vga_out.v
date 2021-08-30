`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.11.2018 13:22:25
// Design Name: 
// Module Name: vga_out
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


module vga_out(
    input clk, // This is the pixel clock, running at 106.47 MHz
    input [3:0] r_in, // Input red intensity
    input [3:0] g_in, // Input green intensity
    input [3:0] b_in, // Input blue intensity
    output [3:0] pix_r, // Output red intensity
    output [3:0] pix_g, // Output green intensity
    output [3:0] pix_b, // Putput blue intensity
    output hsync, // Horizontal sync signal
    output vsync, // Vertical sycn signal
    output [10:0] curr_x, // The current x position of the pixel being drawn on the screen (0 during blanking interval)
    output [9:0] curr_y // The current y position of the pixel being drawn on the screen (0 during blanking interval)
    );
    
    reg [10:0] hcount = 11'd0; // Horizontal counter, 0-1904
    reg [9:0] vcount = 10'd0; // Vertical counter, 0-931
    reg [10:0] c_x = 11'd0; // The current x position of the pixel being drawn on the screen (0 during blanking interval)
    reg [9:0] c_y = 10'd0; // The current y position of the pixel being drawn on the screen (0 during blanking interval)
    
    
    always @ (posedge clk) // Always at the rising edge of the pixel clock, determine what the colour outputs should be
    begin
    
        if (hcount < 11'd1903) // Check if hcount can be incremented
        begin
            hcount <= hcount + 11'd1;
        end
        else // If hcount has reached end of line, reset and check if vcount can be incremented
        begin
                hcount <= 11'd0;
                if (vcount < 10'd931) // The vertical counter is only checked at the end of each line, because it should never be incremented or read otherwise
                    vcount <= vcount + 10'd1;
                else vcount = 10'd0; // End of frame, reset vcount
        end
        
    c_x <= (hcount >= 384 && hcount <= 1823 && vcount >= 31 && vcount <= 930) ? hcount - 10'd384: 1'b0; // If hcount and vcount are within display window, set c_x
    c_y <= (hcount >= 384 && hcount <= 1823 && vcount >= 31 && vcount <= 930) ? vcount - 10'd31 : 1'b0; // If hcount and vcount are within display window, set c_y
    end
    
    
    assign hsync = !(hcount <= 11'd151); // Horizontal sync signal when hcount is lower than 152.
    assign vsync = !(vcount <= 10'd2); // Vertical sync signal when vcount is lower than 3.
    
    
    // Output colour signals are only assigned when hcount and vcount are within the display window
    assign pix_r = (hcount >= 384 && hcount <= 1823 && vcount >= 31 && vcount <= 930) ? r_in: 4'b0 ;
    assign pix_b = (hcount >= 384 && hcount <= 1823 && vcount >= 31 && vcount <= 930) ? b_in: 4'b0 ;
    assign pix_g = (hcount >= 384 && hcount <= 1823 && vcount >= 31 && vcount <= 930) ? g_in: 4'b0 ;
    
    // Assign the c_x and c_y registers to the module outputs.
    assign curr_x = c_x;
    assign curr_y = c_y;
    
endmodule
