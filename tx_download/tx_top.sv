`timescale 1ns / 1ps
/***************************************************************************
*
* Module: tx_top.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520
* Date: 9/15/2024
* Description: Top-level FPGA design for transmitting data
*
****************************************************************************/
module tx_top(
    input wire logic CLK100MHZ,     // Clock input for the module
    input wire logic CPU_RESETN,    // Active low reset input
    input wire logic [7:0] SW,      // Switches for data input (8 bits to send)
    input wire logic BTNC,          // Control signal to initiate a transmit operation
    output logic [7:0] LED,         // LEDs for debugging, reflecting switch states
    output logic UART_RXD_OUT,      // Transmitter output signal
    output logic LED16_B            // Indicates if transmission is busy
);

    // Parameters
    parameter integer CLK_FREQUENCY = 100_000_000;  // Specify the clock frequency in Hz
    parameter integer BAUD_RATE = 19_200;           // Baud rate for UART transmission
    parameter integer PARITY = 1;                   // Parity type (0=Even, 1=Odd)
    parameter integer DEBOUNCE_TIME_US = 10_000;    // Minimum debounce delay in microseconds (10ms)

    // Internal signals
    logic btnc_debounced, debounce_out1, debounce_out2; // Signals for debouncing the button
    logic [7:0] SW_sync;       // Synchronized version of the switch input
    logic rst, rst1, rst2;     // Internal synchronizer flip-flop signals for reset
    logic tx_busy, tx_out_int, one_press; // Signals for transmission status and output

    // Generate reset signal from active low input
    assign rst = ~CPU_RESETN;

    // Instance of the debouncer module to debounce the button input
    debounce #(.DEBOUNCE_CLKS((CLK_FREQUENCY / 1_000_000) * DEBOUNCE_TIME_US)) debouncer (
        .clk(CLK100MHZ), 
        .rst(rst2), 
        .async_in(BTNC), 
        .debounce_out(btnc_debounced)
    );

    // Instance of the transmitter module for UART transmission
    tx #(.CLK_FREQUENCY(CLK_FREQUENCY), .BAUD_RATE(BAUD_RATE), .PARITY(PARITY)) transmitter (
        .clk(CLK100MHZ),
        .rst(rst2), 
        .send(one_press), 
        .din(SW_sync), 
        .busy(tx_busy), 
        .tx_out(tx_out_int)
    );

    // One-shot detector for button press detection
    always_ff @(posedge CLK100MHZ) begin
        debounce_out1 <= btnc_debounced; // First stage of debouncing
        debounce_out2 <= debounce_out1;   // Second stage of debouncing
    end

    // Generate a one-shot pulse when the button is pressed
    assign one_press = (debounce_out1 & ~debounce_out2); // Detect rising edge of debounced button

    // Synchronizer for switch inputs to ensure stable data
    always_ff @(posedge CLK100MHZ) begin
        if (rst2) 
            SW_sync <= 0; // Reset switch synchronization on reset
        else 
            SW_sync <= SW; // Synchronize switch data
    end

    // Assign the switch values to the LEDs for debugging
    assign LED = SW;

    // Connect the busy signal from the transmitter to an LED indicator
    assign LED16_B = tx_busy;

    // Global reset synchronizer to create a stable reset signal
    always_ff @(posedge CLK100MHZ) begin
        rst1 <= rst; // Capture the active reset signal
        rst2 <= rst1; // Synchronize the reset signal
    end  

    // Assign the output from the transmitter module
    assign UART_RXD_OUT = tx_out_int;

endmodule