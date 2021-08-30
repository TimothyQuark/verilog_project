`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.11.2018 18:36:45
// Design Name: 
// Module Name: drawcon
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


module drawcon(
    input clk, // This is the pixel clock
    input rst, // Reset button
    input [10:0] blkpos_x, // x position of player
    input [9:0] blkpos_y, // y position of player
    input [10:0] draw_x, // Current x
    input [9:0] draw_y, // Current y
    input [11:0] x_shift, // How far has Mario moved to the right of the map. Used to determine VGA shift
    input rst_col_det, // Collision has been succesfully detected, turn off signal
    input col_sw, // Color switch, either green or red player
    output [3:0] r_out, // Output red colour, goes to the VGA interface
    output [3:0] g_out, // Output green colour, goes to the VGA interface
    output [3:0] b_out, // Output blue color, goes to the VGA interface
    output col_detected, // Collision detected
    output coin_det_out, // Coin collision detected
    output outbounds, // Character has moved out of bounds, reseting position
    output game_win_out // Player has reached the end of the level
    );
    
    reg [3:0] bg_r, bg_b, bg_g; // The background wires used to draw the pixels
        
    reg [3:0] mario_r, mario_g, mario_b; // The wires used to draw Mario
    reg [11:0] mario_col = 12'b1000_0000_0000; // Mario colour (red)
    reg [11:0] luigi_col = 12'b0000_1000_0000; // Luigi colour (green)
    reg char_col = 1'b0; // 0 = Mario, 1 = Luigi, used to decide which character to use
    
    reg game_win = 1'b0; // Flag set when end of level has been reached
    
    always @(posedge clk)
    begin
        char_col <= col_sw; // Set the character colour based on the current switch settting
    end
    
    
    // If the current pixel being draw is within the player shape, draw the player colour
    always @*
    begin
        if ( draw_x >= blkpos_x & draw_x < blkpos_x + 10'd48 & draw_y >= blkpos_y & draw_y < blkpos_y + 10'd48 )
        begin
            mario_r <= (~char_col) ? mario_col[11:8]: luigi_col[11:8];
            mario_g <= (~char_col) ? mario_col[7:4]: luigi_col[7:4];
            mario_b <= (~char_col) ? mario_col[3:0]: luigi_col[3:0];
        end
        else // Else no colour
        begin
            mario_r = 4'b0000;
            mario_g = 4'b0000;
            mario_b = 4'b0000;
        end
    end

        reg [13:0] address = 1'b0; // The address to call from memory
        reg [11:0] data_in; // If the address data needs to be overwritten, i.e. remove coin
        reg wr = 1'b0; // Write enabled flag
        wire [11:0] dataout; // The output colour data from memory
        
        sram #(.MEMFILE("output_test.mem"))
        g_ram
        (
            .clk(clk), // Remember this is the pix_clk
            .addr(address),
            .write(wr),
            .in_data(data_in),
            .out_data(dataout)        
        );
        
        reg [9:0] next_y = 1'b0; // We have to know the next y line so we know which pixel to draw for x = 0

        // This is logic for drawing pixels on the screen
        always @(posedge clk) // Remember this is the pix_clk
        begin
            
            if (draw_y <= 899 & draw_y >=864) // Draw white border when the game map is not in range
            begin
                bg_r <= 4'b1111;
                bg_g <= 4'b1111;
                bg_b <= 4'b1111; 
            end
            
            if (draw_x == 1439) // Used to calculate x=0 for the next line
            begin
                next_y = draw_y + 1; // The next line y value
                address = next_y / 16 * 300; // Call this address in advance, so that it will be available for the first pixel on the next line
            end
            
            if (draw_y <= 863 & draw_x <=1439 ) // If in range then we draw the map
            begin
                bg_r = dataout[11:8];
                bg_g = dataout[7:4];
                bg_b = dataout[3:0];
                // We calculate the address for the next pixel. Since we read pixels across x axis, means +1 for x calculations.
                address = (draw_y /16) * 300 + (draw_x + x_shift + 1) / 16;
            end
 
        end

    // Decide if we draw either player or the background.
    assign r_out = (mario_r || mario_g || mario_b) ? mario_r : bg_r;
    assign g_out = (mario_r || mario_g || mario_b) ? mario_g : bg_g;
    assign b_out = (mario_r || mario_g || mario_b) ? mario_b : bg_b;
    
    // Logic for collision detection
    
    reg col_det_reg = 1'b0;
    reg coin_det = 1'b0; // If a coin is detected, this will be set to 1.
    reg reset_pos_reg;

    always @(posedge clk)
    begin
    
        coin_det <= 1'b0; // Reset coin detected flag at start of every clock cycle
        reset_pos_reg <= 0; // Reset the position reset flag at start of every clock cycle
        
        if (blkpos_y + 10'd48 >= 864) // Check if the player is out of bounds, i.e. has fallen through the bottom of the map
        begin
            reset_pos_reg <= 1'b1;
        end
        
        // Every full screen check we expect to receive this signal if a collision has been
        // succesfully detected
        if (rst_col_det) col_det_reg <= 1'b0;
        // Check if we are inside the character model
        if (draw_x >= blkpos_x & draw_x < blkpos_x + 10'd48 & draw_y >= blkpos_y & draw_y < blkpos_y + 10'd48)
        begin
            // Check if the pixel is either the sky or coin color
            if (dataout == 12'h2cd || dataout == 12'hdd2)
            begin
                if (dataout == 12'hdd2) // We make the coin disappear, and send coin_det signal
                begin
                    wr <= 1'b1; // The write flag is enabled
                    data_in <= 12'h2cd; // The coin becomes a sky tile once it has been hit
                    coin_det <= 1'b1; // We tell the corresponding reg that it should be on.
                end
            end
            else // All other colours are considered to be non-traversable, so a collision will occur
            begin
                col_det_reg <= 1'b1; // A collision has been detected inside the character, tell game_controller
                
                // We have hit the end pole, game is over
                if (dataout == 12'hf0e)
                begin
                    if (rst) game_win <= 0;
                    else game_win <= 1'b1;
                end
                
            end
        end
                
        wr = 1'b0; // Set to active low as nothing to write anymore
    end
    

    
    assign col_detected = col_det_reg; // Output will tell that a collision has been detected
    assign coin_det_out = coin_det; // If a coin is detected, then we send a signal
    assign outbounds = reset_pos_reg; // If mario out of bounds, then we send a signal
    assign game_win_out = game_win; // Flag telling dataholder the game has been won
    
endmodule


    
