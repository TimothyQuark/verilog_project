`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.11.2018 14:54:16
// Design Name: 
// Module Name: main
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

// Our motto for this project:
// Mario is red, Luigi is green, why does Vivado keep being mean

module main(
    input clk, // On board clock
    input main_rst, // Using the reset switch, we can completely reset the game if any weird bugs happens
    input cen_b, // Pushbuttons
    input up_b,
    input left_b,
    input right_b,
    input down_b,
    
    input sw_1, // Switch for changing the colour of Mario, left of board
    
    // Outputs for the 7 segment LED
    output a,b,c,d,e,f,g, 
    output [7:0] an, 

    // Outputs for the VGA
    output [3:0] pix_r,
    output [3:0] pix_g,
    output [3:0] pix_b,
    output hsync,
    output vsync,
    
    // LEDs that show the remaining lives of the player
    output LED_1,
    output LED_2,
    output LED_3
     );
               
     wire [13:0] score; // These wires are connected to the data_holder module, which stores all our important data
     wire [8:0] g_time; // Game time
     wire [1:0] lives; // Remaining lives
     
     wire rst = ~main_rst; // Reset is active low on Nexys FPGAs

     wire [10:0] curr_x; // current pixel x position: 0-1023
     wire [9:0] curr_y; // current pixel y positio: 0-511
         
     wire coin_det_wire; // Flag active when a coin has been detected
     wire pix_clk; // Pixel clock
     wire outbounds_wire; // Flag active when player out of bounds
     wire game_win_wire; // This wire tells us if the player has won the game
     
     // The dataholder module, contains all important game data except for memory  
     data_holder DHOLD ( 
        .rst(rst),
        .clk(clk),
        .pix_clk(pix_clk),
        .coin_det_in(coin_det_wire),
        .outbounds(outbounds_wire),
        .game_win(game_win_wire),
        .score(score),
        .g_time(g_time),
        .lives(lives)
        );
    
    // Logic for assigning the LED values for the different lives.    
    assign LED_1 = (lives == 3);
    assign LED_2 = (lives == 3 || lives == 2);
    assign LED_3 = (lives == 3 || lives == 2 || lives == 1);

     // Interface for the 7 segment display
     seginterface2 SEG1 (
        .clk(clk),
        .score(score),
        .g_time(g_time),
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e),
        .f(f),
        .g(g),
        .an(an)
        );
        
     // VGA Modules and components
          
     clk_wiz_0 clock // This is the pixel clock, which runs at 106.47 MHz.
     (
     .clk_out1(pix_clk),     // Connect the pix_clk wire to the output of the Clock Wizard module
     .clk_in1(clk)       // Connect the on board clock to the input of the Clock Wizard module
     );
     
     wire [3:0] r_in, b_in, g_in; // Connect to these wires to determine the things to be displayed
     
     // Interface that connects to the VGA
     vga_interface V1 (
        .clk(pix_clk),
        .r_in(r_in),
        .g_in(g_in),
        .b_in(b_in),
        .pix_r(pix_r),
        .pix_g(pix_g),
        .pix_b(pix_b),
        .hsync(hsync),
        .vsync(vsync) ,
        .curr_x(curr_x),
        .curr_y(curr_y)
        );
        
        
        wire [10:0] blkpos_x; // Player position on the screen
        wire [9:0] blkpos_y; // The y position tracker has eventually become redundant
        wire col_det_wire; // Wire that transmits if a collision has been detected
        wire rst_col_det_wire; // Sends a confirmation signal that the collision has been detected
        wire [11:0] x_shift_wire; // How far the player has shifted the background level by scrolling
                
        // Drawcon module which determines the colour of each pixel, and also contains collision detection
        drawcon D1 (
            .clk(pix_clk), // Clock only used to access memory. Uses the pix_clk clock
            .rst(rst),
            .blkpos_x(blkpos_x),
            .blkpos_y(blkpos_y),
            .draw_x(curr_x),
            .draw_y(curr_y),
            .x_shift(x_shift_wire),
            .rst_col_det(rst_col_det_wire),
            .col_sw(sw_1),
            .r_out(r_in),
            .g_out(g_in),
            .b_out(b_in),
            .col_detected(col_det_wire),
            .coin_det_out(coin_det_wire),
            .outbounds(outbounds_wire),
            .game_win_out(game_win_wire)
            );
            
    // Logic that gives the slow clock, 60 Hz
    wire slow_clk_out;
    slow_clk clk_60Hz // Note this clock is not actually 60 Hz, it it 7.86432 MHz
    (
    // Clock out ports
    .clk_out1(slow_clk_out),     // output clk_out1
    // Clock in ports
    .clk_in1(clk)
    );      // input clk_in1
              

    reg [20:0] slow_clk_cnt = 1'b0;
    wire rfresh_60Hz_clk; // This is the 60 Hz clock.
    
    // Logic for getting the 60 Hz clock from the slow clock
    always @(posedge slow_clk_out)
        slow_clk_cnt = slow_clk_cnt + 1'b1;
    
    assign rfresh_60Hz_clk = slow_clk_cnt[16]; // This is the same as dividing by 2^17
    
    // Game controller takes user input and moves the player around. Also includes gravity system
    game_controller GC1 (
        .clk(rfresh_60Hz_clk),
        .rst(rst),
        .cen_b(cen_b),
        .up_b(up_b),
        .left_b(left_b),
        .right_b(right_b),
        .down_b(down_b),
        .col_detected(col_det_wire),
        .outbounds(outbounds_wire),
        .game_win(game_win_wire),
        .blkpos_x_out(blkpos_x),
        .blkpos_y_out(blkpos_y),
        .x_shift(x_shift_wire),
        .rst_col_det(rst_col_det_wire)
    );

endmodule
