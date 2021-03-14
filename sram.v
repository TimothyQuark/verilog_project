`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.11.2018 15:51:00
// Design Name: 
// Module Name: sram
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

// ADDR-WIDTH = 300px * 54 px < 2^14
// Data Width = 12 bits
// Depth = 300 * 54

module sram #(parameter ADDR_WIDTH=14, DATA_WIDTH=12, DEPTH=300*54, MEMFILE="")
    (
    input clk, // Pixel clock
    input [ADDR_WIDTH-1:0] addr, // Address to be called
    input write, // Flag that states if address is to be written to
    input [DATA_WIDTH-1:0] in_data, // Write data
    output reg [DATA_WIDTH-1:0] out_data // Output data from address
    );
    
    reg [DATA_WIDTH-1:0] memory_array [0:DEPTH-1];
    
    initial
    begin
        if (MEMFILE > 0)
        begin
            $display("Loading memory init file " + MEMFILE + " into array.");
            $readmemh(MEMFILE, memory_array);
        end
    end
    
    always @(posedge clk)
    begin
        if (write) memory_array[addr] <= in_data; // Write data if flag active
        else out_data <= memory_array[addr]; // Else output address data
    end
        
endmodule
