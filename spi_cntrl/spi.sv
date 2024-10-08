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
    parameter CLK_FREQUENCY = 100_000_000;  // Sample frequency
    parameter SCLK_FREQUENCY = 500_000;      // Number of signals changed per second

    // Internal signals
    logic [3:0] bit_counter;               // Bit counter for shifting data
    logic [7:0] shift_register;             // Shift register for sending data
    logic [31:0] clk_div_counter;           // Clock division counter
    logic sclk_toggle, enableBitTimer, enableBitCounter; // Signals to toggle SCLK

    typedef enum logic [2:0] {IDLE, START, TRANSFER, DONE} state_t;
    state_t current_state, next_state;

    // Clock division and SCLK generation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div_counter <= 0;
            SPI_SCLK <= 0;
        end else begin
            if (clk_div_counter < (CLK_FREQUENCY / SCLK_FREQUENCY) - 1) begin
                clk_div_counter <= clk_div_counter + 1;
            end else begin
                clk_div_counter <= 0;
                SPI_SCLK <= ~SPI_SCLK; // Toggle SCLK
            end
        end
    end

    // State Machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            busy <= 0;
            done <= 0;
            SPI_CS <= 1; // CS inactive
            bit_counter <= 0;
            shift_register <= 0;
            data_received <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    busy <= 0;
                    done <= 0;
                    SPI_CS <= 1; // CS inactive
                    if (start) begin
                        busy <= 1;
                        SPI_CS <= 0; // CS active
                        shift_register <= data_to_send; // Load data to send
                        bit_counter <= 0; // Reset bit counter
                        next_state <= START;
                    end
                end

                START: begin
                    if (SPI_SCLK) begin // On rising edge of SCLK
                        SPI_MOSI <= shift_register[7]; // Send MSB first
                        data_received[bit_counter] <= SPI_MISO; // Sample MISO
                        shift_register <= {shift_register[6:0], 1'b0}; // Shift left
                        bit_counter <= bit_counter + 1; // Increment bit counter
                        if (bit_counter == 7) begin // After sending all bits
                            next_state <= DONE;
                        end
                    end
                end

                DONE: begin
                    busy <= 0;
                    done <= 1; // Indicate transfer complete
                    SPI_CS <= hold_cs ? 0 : 1; // Manage CS based on hold_cs
                    if (!start) begin
                        current_state <= IDLE; // Return to IDLE state
                    end
                end
            endcase
            current_state <= next_state; // Update current state
        end
    end

endmodule
