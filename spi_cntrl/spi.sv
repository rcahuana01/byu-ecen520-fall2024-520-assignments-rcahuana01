`timescale 1ns / 1ps
/***************************************************************************
*
* Module: spi.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520
* Date: 9/20/2024
* Description: SPI Design
*
****************************************************************************/
module spi(
    input wire logic clk,                     // Clock
    input wire logic rst,                     // Reset
    input wire logic start,                   // Start a transfer
    input wire logic [7:0] data_to_send,     // Data to send to subunit
    input wire logic hold_cs,                 // Hold CS signal for multi-byte transfers
    input wire logic SPI_MISO,                // SPI MISO signal (input)
    output logic [7:0] data_received,         // Data received on the last transfer
    output logic busy,                        // Controller is busy
    output logic done,                        // Indicates that a new data value has been received
    output logic SPI_SCLK,                    // SCLK output signal
    output logic SPI_MOSI,                    // MOSI output signal
    output logic SPI_CS                       // CS output signal
);

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;     // System clock frequency
    parameter SCLK_FREQUENCY = 500_000;          // Desired SPI clock frequency
    parameter DATA_BITS = 8;                    // Number of data bits

    // Clock division factor
    localparam CLOCK_DIV = CLK_FREQUENCY / SCLK_FREQUENCY;

    // Internal signals
    logic [2:0] bit_counter;                   // Bit counter for shifting data
    logic [7:0] shift_register;                // Shift register for sending data
    logic [31:0] clk_div_counter;              // Clock division counter
    logic enableBitTimer, enableBitCounter;    // Enable signals for timers and counters

    typedef enum logic [2:0] {IDLE, START, TRANSFER, DONE} state_t;
    state_t current_state, next_state;

    // Clock division and SCLK generation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div_counter <= 0;
            SPI_SCLK <= 0;
        end else begin
            if (clk_div_counter < CLOCK_DIV - 1) begin
                clk_div_counter <= clk_div_counter + 1;
            end else begin
                clk_div_counter <= 0;
                SPI_SCLK <= ~SPI_SCLK; // Toggle SCLK
            end
        end
    end

    // State machine for SPI operation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            bit_counter <= 0;
            SPI_CS <= 1;          // CS inactive
            data_received <= 8'b0; // Clear received data
        end else begin
            current_state <= next_state; // Update state
        end
    end

    // Combinational logic for state transitions and outputs
    always_comb begin
        next_state = current_state; // Default to current state
        busy = 0;                   // Default busy signal
        done = 0;                   // Default done signal
        SPI_MOSI = 0;               // Clear MOSI
        SPI_CS = 1;                 // CS inactive

        case (current_state)
            IDLE: begin
                if (start) begin
                    busy = 1;
                    SPI_CS = 0;           // CS active
                    shift_register = data_to_send; // Load data to send
                    bit_counter = 0;      // Reset bit counter
                    next_state = START;   // Move to START state
                end
            end
            START: begin
                busy = 1;
                if (SPI_SCLK) begin // On rising edge of SCLK
                    SPI_MOSI = shift_register[7]; // Send MSB first
                    data_received[bit_counter] = SPI_MISO; // Sample MISO
                    shift_register = {shift_register[6:0], 1'b0}; // Shift left
                    bit_counter = bit_counter + 1; // Increment bit counter

                    if (bit_counter == DATA_BITS - 1) begin
                        next_state = DONE; // Move to DONE state after transferring all bits
                    end
                end
            end
            DONE: begin
                busy = 0;
                done = 1;                 // Indicate transfer complete
                SPI_CS = hold_cs ? 0 : 1; // Manage CS based on hold_cs
                if (!start) begin
                    next_state = IDLE;    // Return to IDLE state
                end
            end
        endcase
    end

endmodule
