`timescale 1ns/1ps
/***************************************************************************
*
* Module: ascii_bram_rom_tb.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall 2024
* Date: 10/14/2024
* Description: 
*
****************************************************************************/
module ascii_bram_rom_tb;

    // Testbench signals
    logic clk, rst, init, re;
    logic [7:0] dout;
    logic rom_end;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // ROM instantiation
    ascii_bram_rom #(
        .FILENAME("fight_song.mem")
    ) uut (
        .clk(clk),
        .rst(rst),
        .init(init),
        .re(re),
        .dout(dout),
        .rom_end(rom_end)
    );

    // Test procedure
    initial begin
        rst = 1;
        init = 0;
        re = 0;
        #10 rst = 0; // Release reset

        // Read ROM contents
        re = 1;
        #100 re = 0;

        // End simulation
        #200 $finish;
    end

endmodule
