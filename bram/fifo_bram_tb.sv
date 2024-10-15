`timescale 1ns/1ps
/***************************************************************************
*
* Module: fifo_bram_tb.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall 2024
* Date: 10/14/2024
* Description: Testbench for the FIFO BRAM for the FPGA
*
****************************************************************************/
module fifo_bram_tb;

    // Testbench signals
    logic clk, rst, we, re;
    logic [7:0] din;
    logic [7:0] dout;
    logic full, empty;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // FIFO instantiation
    fifo_bram uut (
        .clk(clk),
        .rst(rst),
        .we(we),
        .re(re),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    // Test procedure
    initial begin
        rst = 1;
        we = 0;
        re = 0;
        din = 8'h00;
        #10 rst = 0; // Release reset

        // Write data to the FIFO
        we = 1;
        din = 8'h41; // Write 'A'
        #10 din = 8'h42; // Write 'B'
        #10 din = 8'h43; // Write 'C'
        #10 we = 0;

        // Read data from the FIFO
        re = 1;
        #20 re = 0;

        // End simulation
        #50 $finish;
    end

endmodule
