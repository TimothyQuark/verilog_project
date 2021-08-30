`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.12.2018 12:30:40
// Design Name: 
// Module Name: game_controller
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


module game_controller(
    input clk, // This should be the 60 Hz clock
    input rst, // Reset button
    input cen_b, up_b, left_b, right_b, down_b, // Pushbutton input ports
    input col_detected, // Flag indicating a collision has been detected, meaning that player input is ignored
    input outbounds, // Check if the character is out of bounds, move him back to start of level if true
    input game_win,
    output [10:0] blkpos_x_out,
    output [9:0] blkpos_y_out,
    output [11:0] x_shift, // Max shift is 3360 (+ 1439 = 4799), this prevents the level from looping
    output rst_col_det
    );
    
    reg [10:0] blkpos_x_reg = 10'd695; // Starts in the middle of the screen
    reg [9:0] blkpos_y_reg = 10'd400;
    reg [11:0] x_shift_reg = 11'd10; // Initial x shift used because otherwise we would see end of the map on left of screen
    
    integer movespeed = 6; // Movement speed of Mario
    integer mario_size = 48; // Used for collision detection
    integer min_x_shift = 10; // This is the minimum x_shift we can use before we start seeing the end of the map on the screen
    
    reg [3:0] last_dir; // Stores the last movement direction of Mario. Used for collision.
    // 1 = up, 2 = up right, 3= right, 4 = down right, 5 = down, 6 = down left
    // 7 = left, 0 = up left, 15 = did not move (stationary)
    reg rst_col_reg; // Register that sends the reset collision detection signal
    reg [7:0] jump_counter = 8'd35; // This counter is used to see how long a character jumps. Higher means longer jumps allowed
    reg jump_allowed = 1'b1;
    
    reg grav_tick = 1'b0; // If a clock pulse creates a gravity tick, it will be marked here. If this is true, 
    reg [9:0] prev_ypos; // Saves the y position of mario from the last cycle if mario did not move at all. Used for/by gravity logic.
    reg [11:0] prev_x_shift;
    integer grav_intensity = 5; // Strength of gravity
    reg currently_jumping = 1'b0; // If Mario is currently in the jumping process, then gravity is turned off for this tick
    
    always @(posedge clk, posedge rst)
    begin
    
        begin
            
            rst_col_reg = 1'b0; // Reset this signal at the start of the clock, collision register
            if (jump_counter == 1'b0) jump_allowed = 1'b0; // Disable jumping, jump counter has been used up
            currently_jumping = 1'b0; // Resets every clock cycle, turned on if Mario has successfully jumped
            
            if (outbounds) // Mario has been out of bounds, reset him to the start of the map
            begin
                blkpos_x_reg <= 10'd695;
                blkpos_y_reg <= 10'd400;
                x_shift_reg <= 11'd10;
            end
            
            if (~col_detected) // If no collision has been detected, take user input
            begin
                
                //Note that the order of these nested if statements matters, hence all double inputs are at the top
                if (up_b & left_b & blkpos_y_reg - movespeed > 0 & x_shift_reg - movespeed > min_x_shift)
                begin
                    if (jump_allowed & jump_counter > 0) // If the jump counter is not 0, the player is allowed to jump
                    begin
                        blkpos_y_reg = blkpos_y_reg - movespeed;
                        x_shift_reg = x_shift_reg - movespeed;
                        jump_counter = jump_counter - 1;
                        currently_jumping = 1'b1;
                    end
                    else // The character is only allowed to move to the left, up input is ignored
                    begin
                        x_shift_reg = x_shift_reg - movespeed;
                        jump_allowed = 1'b0;
                    end
                    
                    last_dir = 0;
                end
                else
                    if (up_b & right_b & blkpos_y_reg - movespeed > 0 & x_shift_reg + mario_size + movespeed <= 3360)
                    begin
                        if (jump_allowed & jump_counter > 0)
                        begin
                            blkpos_y_reg = blkpos_y_reg - movespeed;
                            x_shift_reg = x_shift_reg + movespeed;
                            jump_counter = jump_counter - 1;
                            currently_jumping = 1'b1;
                        end
                        else
                        begin
                            x_shift_reg = x_shift_reg + movespeed;
                            jump_allowed = 1'b0;
                        end
                        
                        last_dir = 2;
                    end
                    else
                        if (down_b & left_b & blkpos_y_reg + mario_size + movespeed < 864 & x_shift_reg - movespeed > min_x_shift)
                        begin
                            if (jump_allowed & jump_counter > 0)
                            begin
                                blkpos_y_reg = blkpos_y_reg + movespeed;
                                x_shift_reg = x_shift_reg - movespeed;
                                jump_counter = jump_counter - 1;
                            end
                            else
                            begin
                                x_shift_reg = x_shift_reg - movespeed;
                                jump_allowed = 1'b0;
                            end
                            
                            last_dir = 6;
                        end
                        else
                            if (down_b & right_b & blkpos_y_reg + mario_size + movespeed < 864 & x_shift_reg + mario_size + movespeed < 3360)
                            begin
                                if (jump_allowed & jump_counter > 0)
                                begin
                                    blkpos_y_reg = blkpos_y_reg + movespeed;
                                    x_shift_reg = x_shift_reg + movespeed;
                                    jump_counter = jump_counter - 1;
                                end
                                else
                                begin
                                    x_shift_reg = x_shift_reg + movespeed;
                                    jump_allowed = 1'b0;
                                end
                                last_dir = 4;
                            end
                            else
                                if (up_b & ~right_b & ~left_b & blkpos_y_reg - movespeed > 0) 
                                begin
                                    if (jump_allowed & jump_counter > 0)
                                    begin
                                        blkpos_y_reg <= blkpos_y_reg - movespeed;
                                        jump_counter = jump_counter - 1;
                                        currently_jumping = 1'b1;
                                    end
                                    else
                                    begin
                                        jump_allowed = 1'b0;
                                    end
                                    last_dir = 1;
                                end
                                else
                                    if (left_b & ~down_b & ~up_b & x_shift_reg - movespeed > min_x_shift)
                                    begin
                                        if (jump_allowed & jump_counter > 0) 
                                        begin
                                            x_shift_reg <= x_shift_reg - movespeed;
                                            jump_counter = jump_counter - 1;
                                        end
                                        else
                                        begin
                                            x_shift_reg <= x_shift_reg - movespeed;
                                            jump_allowed = 1'b0;
                                        end
                                        last_dir = 7;
                                    end
                                    else
                                        if(right_b & ~down_b & ~up_b & x_shift_reg + mario_size + movespeed < 3360 )
                                        begin
                                            if (jump_allowed & jump_counter > 0)
                                            begin
                                                x_shift_reg <= x_shift_reg + movespeed;
                                                jump_counter = jump_counter - 1;
                                            end
                                            else
                                            begin
                                                x_shift_reg <= x_shift_reg + movespeed;
                                                jump_allowed = 1'b0;
                                            end
                                            last_dir = 3;
                                        end
                                        else
                                            if (down_b & ~right_b & ~left_b & blkpos_y_reg + mario_size + movespeed < 864)
                                            begin
                                                if (jump_allowed & jump_counter > 0)
                                                begin
                                                    blkpos_y_reg <= blkpos_y_reg + movespeed;
                                                    jump_counter = jump_counter - 1; 
                                                end
                                                else
                                                begin
                                                    blkpos_y_reg <= blkpos_y_reg + movespeed;
                                                    jump_allowed = 1'b0;
                                                end
                                                last_dir = 5;
                                            end
                                            else
                                                if (cen_b) // Used for debugging
                                                begin
                                                    jump_counter = 8'd60;
                                                    jump_allowed = 1'b1;
                                                end
                                                else
                                                    if (~up_b & ~right_b & ~down_b & ~left_b) // No user input, character standing still
                                                    begin
                                                        last_dir = 15;
                                                    end
                
                // Gravity logic. A tick of gravity is applied if we are not currently jumping, and the block has moved from its last location where gravity was
                // forced to revert.
                if (  ~currently_jumping & (prev_ypos != blkpos_y_reg || prev_x_shift != x_shift_reg) )
                begin
                    blkpos_y_reg = blkpos_y_reg + grav_intensity;
                    grav_tick = 1'b1; // A tick of gravity was applied in this clock pulse
                    prev_ypos = 0;
                    prev_x_shift = 0;
                end
                                                    
            end
            // Collision detected on user input. Note this is not the detection itself, but the response to said signal.
                else
                begin
                    // Do the opposite of what the last movement direction was
                    case (last_dir)
                        0: begin 
                            blkpos_y_reg = blkpos_y_reg + movespeed;
                            x_shift_reg = x_shift_reg + movespeed;
                            end
                        1: begin
                            blkpos_y_reg = blkpos_y_reg + movespeed;
                            end
                        2: begin
                            blkpos_y_reg = blkpos_y_reg + movespeed;
                            x_shift_reg = x_shift_reg - movespeed;
                            end
                        3: begin
                            x_shift_reg = x_shift_reg - movespeed;
                            end
                        4: begin
                            blkpos_y_reg = blkpos_y_reg - movespeed;
                            x_shift_reg = x_shift_reg - movespeed;
                        end
                        5: begin
                            blkpos_y_reg = blkpos_y_reg - movespeed;
                        end
                        6: begin
                            blkpos_y_reg = blkpos_y_reg - movespeed;
                            x_shift_reg = x_shift_reg + movespeed;
                        end
                        7: begin
                            x_shift_reg = x_shift_reg + movespeed;
                        end
                        15 : begin
                            // We do nothing.
                        end
                        
                    endcase
                    
                    // A grav tick was applied, but it must be reverted because collision occurred
                    if (grav_tick & last_dir != 1)
                    begin
                        blkpos_y_reg = blkpos_y_reg - grav_intensity;
                        grav_tick = 1'b0; // Reset grav tick after it has been applied
                        prev_ypos = blkpos_y_reg; // We note the current position of the character.
                        prev_x_shift = x_shift_reg;
                    end
                   
                    rst_col_reg = 1'b1; // We have returned to the original position, and now tell drawcon to stop sending the signal
                    jump_allowed = 1'b1; // We are allowed to jump again. Note this enables wall jumping!
                    jump_counter = 8'd35; // Reset the jump counter as well
    
                end
            
    end
    
    if (game_win || rst) // If the game has been won or the reset button pressed, then the player position is reset to start of level
        begin
            blkpos_x_reg <= 10'd695;
            blkpos_y_reg <= 10'd400;
            x_shift_reg <= 11'd10;
        end
        
    end
    
    assign blkpos_x_out = blkpos_x_reg;
    assign blkpos_y_out = blkpos_y_reg;
    assign x_shift = x_shift_reg;
    assign rst_col_det = rst_col_reg;
    

endmodule
