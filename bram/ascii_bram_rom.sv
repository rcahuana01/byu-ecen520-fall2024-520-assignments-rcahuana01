`timescale 1ns/1ps
/***************************************************************************
*
* Module: ascii_bram_rom.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall 2024
* Date: 10/14/2024
* Description: 
*
****************************************************************************/
module ascii_bram_rom #(
    parameter FILENAME = "fight_song.mem"
) (
    input wire logic clk,
    input wire logic rst,
    input wire logic init,   // Reset read pointer to 0
    input wire logic re,     // Read enable
    output wire logic [7:0] dout, // Data output
    output wire logic rom_end  // Indicates end of ROM
);

    // Inferred ROM memory (8 bits x 4096)
    logic [7:0] rom [0:4095];
    logic [11:0] read_addr;  // Read pointer

    // Load memory from file
    initial begin
        $readmemh(FILENAME, rom);
    end

    // Read pointer logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst || init) begin
            read_addr <= 0;
        end else if (re && !rom_end) begin
            read_addr <= read_addr + 1;
        end
    end

    // Output logic
    assign dout = rom[read_addr];
    assign rom_end = (dout == 8'h00); // End when NULL character is read

endmodule
