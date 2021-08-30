`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.11.2018 15:43:13
// Design Name: 
// Module Name: data_holder
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


module data_holder(
    input rst, // Reset all memory
    input clk, // The FPGA clock
    input pix_clk, // The pixel clock
    input coin_det_in, // Input port that notifies when collision system has detected a coin
    input outbounds, // Input port that notifies when the character has fallen out of bounds, thus a life should be lost
    input game_win, // Input port notifying that the player has reached the end of the level
    output [13:0] score, // Output port that tells us the score. Sent to the double dabbler
    output [8:0] g_time, // Output port that tells us the game time. Sent to the double dabbler
    output [1:0] lives // Output port that tell us how many remaining lives the player has. Sent to the LEDs on the board
    );
    
    
    reg [13:0] scr = 14'd0;  // The game score register
    reg [13:0] old_scr = 14'd0; // Register that holds the old score, used when the score is incremented
    reg [8:0] g_t = 9'd500; // Game time, defaults at 500
    reg [1:0] lvs = 2'd3;   // Player lives, defaults to 3
    reg [1:0] old_lvs; // Register that holds the previous number of lives, used when levels is incremented
    
    // Game time logic components
    reg [28:0] clk_count = 1'b0; // A clock counter that is used to calculate the game time
    wire g_time_clk; // Wire that indicates when the game time should be incremented
        
    reg game_over = 1'b0; // Indicates if the game is over, i.e. all 3 lives have been lost
    reg g_sc_added = 1'b0; // The game win score has been added once, do not add it again until reset has been hit.
        
    assign score = scr;
    assign g_time = g_t;
    assign lives = lvs;
    
    always @(posedge clk)
    begin
        if (!rst)
        begin 
            clk_count <= clk_count + 1'b1; // Increment the clock counter
        end
    end
        
    assign g_time_clk = clk_count[26]; // This determines the speed at which the game time decreases. Changing this changes the game time speed
    
    
    always @(posedge g_time_clk, posedge rst)
    begin
        if (rst) g_t <= 9'd500; // Reset the game time if the reset button has been pressed
        else 
            if (!(g_t == 0 || game_over)) g_t <= g_t - 1'b1; // If game time is 0 or a game over has not been detected, the game time counter is incremented
                    
        old_scr <= scr; // Used to prevent score gaining random amount due to multiple pixels for coin/ memory too slow for pix_clk?
        old_lvs <= lvs; // Same reason as above
        
    end
    
//     Logic for the score
    always @(posedge pix_clk)
    begin
        if (rst) // Resets all the remaining dataholders
        begin
            lvs <= 3;
            scr <= 0;
            game_over <= 1'b0;
            g_sc_added <= 1'b0;
            
        end
        
        else 
        begin
            if (coin_det_in & old_scr == scr) scr <= scr + 10; // Increment the score
            if (game_win & old_scr == scr) // The game has been won, i.e. we have reached the finish line.
            begin
                if (~g_sc_added) // Logic needed due to problems with collision
                    begin
                        scr <= scr + 2 * g_t + 500;
                        g_sc_added <= 1'b1;
                    end
            end
            
            // If out of bounds, increment lives. Additional logic needed due to problems with collision  
            if (outbounds & old_lvs == lvs & lvs > 0) lvs <= lvs - 1; 
            if (lvs == 0 || g_t == 0)
            begin
                game_over = 1'b1;
                if (lvs == 0) scr <= 0;
            end
        end
    end
    
endmodule
