`timescale 1ns/1ps
/***************************************************************************
*
* Module: fifo_bram.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall 2024
* Date: 10/14/2024
* Description: 
*
****************************************************************************/
module fifo_bram (
    input wire logic clk,
    input wire logic rst,
    input wire logic we,       // Write enable
    input wire logic re,       // Read enable
    input wire logic [7:0] din, // Data input
    output wire logic [7:0] dout, // Data output
    output wire logic full,    // Full flag
    output wire logic empty    // Empty flag
);

    // Address counters
    logic [15:0] write_addr, read_addr;
    logic [8:0] data_out; // For 9-bit data width (write mode)

    // Full and empty logic
    assign empty = (write_addr == read_addr);
    assign full = (write_addr == (read_addr - 1));

    // Write and read address logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            write_addr <= 0;
            read_addr <= 0;
        end else begin
            if (we && !full) write_addr <= write_addr + 1;
            if (re && !empty) read_addr <= read_addr + 1;
        end
    end

    // RAMB36E1 instantiation
    RAMB36E1 #(
        .READ_WIDTH_B(9),         // 8-bit read width
        .WRITE_WIDTH_A(9),        // 8-bit write width
        .WRITE_MODE_A("READ_FIRST") // Write mode
    ) bram (
        .CLKARDCLK(clk),
        .CLKBWRCLK(clk),
        .ENARDEN(1'b1),           // Always enabled for reading
        .ENBWREN(we),             // Write enable
        .ADDRARDADDR({1'b0, read_addr, 6'b0}), // Read address
        .ADDRBWRADDR({1'b0, write_addr, 6'b0}), // Write address
        .DIADI({24'b0, din}),     // Write data
        .DOADO(),                 // Not used
        .DOBDO({data_out}),       // Read data
        .WEA(we ? 4'b1111 : 4'b0000), // Write enable for 4 bytes
        .REGCEB(1'b1)             // Always enabled
    );

    // Output data (truncated to 8 bits)
    assign dout = data_out[7:0];

endmodule
