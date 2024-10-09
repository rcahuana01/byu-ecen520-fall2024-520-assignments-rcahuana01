`timescale 1ns / 1ps
/***************************************************************************
*
* Module: spi.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520
* Date: 9/20/2024
* Description: SPI Controller Design
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
    localparam TIMER_RANGE = 15;              // Timer range
    localparam BIT_RANGE = 3;                 // Bit range for counter
    localparam DATA_BITS = 8;                 // Number of data bits
    
    // Internal signals        
    logic [BIT_RANGE:0] bitNum;                  
    logic [TIMER_RANGE:0] timer;                  
    logic timer_done, clrTimer, half_timer_done;              
    logic clrBit, incBit, bitDone;  
    logic spi_sclk, spi_mosi;  

    // State definitions
    typedef enum logic [2:0] {IDLE, LOW, HIGH} state_t;
    state_t current_state, next_state;

    // Bit timer
    always_ff @(posedge clk or posedge rst) begin
        if (rst || clrTimer) 
            timer <= 0;
        else if (timer_done)
            timer <= 0;  // Reset timer on done
        else
            timer <= timer + 1;
    end

    // Bit counter
    always_ff @(posedge clk or posedge rst) begin
        if (rst || clrBit)
            bitNum <= 0;
        else if (incBit)
            bitNum <= bitNum + 1;
    end

    // Assign busy state
    assign busy = (current_state != IDLE);

    // Timer logic
    assign timer_done = (timer >= (CLK_FREQUENCY / SCLK_FREQUENCY)); 
    assign half_timer_done = (timer == ((CLK_FREQUENCY / SCLK_FREQUENCY) / 2)); 
    assign bitDone = (bitNum == (DATA_BITS - 1));

    // State Machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else 
            current_state <= next_state; // Update current state
    end

    // Combinational logic    
    always_comb begin
        next_state = current_state;
        done = 0; // Reset done signal
        incBit = 0; // Reset increment bit signal
        clrTimer = 0; // Reset clear timer signal

        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = LOW;
                end
            end

            LOW: begin
                if (half_timer_done) begin // Move to HIGH state
                    next_state = HIGH;
                end
            end

            HIGH: begin
                if (timer_done) begin
                    clrTimer = 1; // Clear timer
                    incBit = 1; // Increment bit count
                    if (bitDone) begin
                        next_state = IDLE; // Go to IDLE
                        done = 1; // Indicate transfer complete
                    end else begin
                        next_state = LOW; // Continue transfer
                    end
                end
            end
        endcase
    end

    // Assign output signals
    assign spi_sclk = (current_state == HIGH);
    assign spi_mosi = data_to_send[7 - bitNum];

    // Output signal assignment and data reception
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            SPI_SCLK <= 0;
            SPI_MOSI <= 0;
            SPI_CS <= 1;
            data_received <= 0;
        end else begin
            SPI_SCLK <= spi_sclk;
            SPI_MOSI <= spi_mosi;

            // Manage CS based on hold_cs and current state
            SPI_CS <= hold_cs ? 0 : (current_state == IDLE ? 1 : 0);

            if (half_timer_done) begin
                data_received <= {data_received[6:0], SPI_MISO}; // Shift left
            end
        end
    end

    // Debugging output
    always_ff @(posedge clk) begin
        $display("Time: %0t | Timer: %0d | Half Timer Done: %b | Timer Done: %b | Current State: %s | Start: %b | CS: %b | SCLK: %b | MOSI: %b | Received: %h | Done: %b", 
                 $time, timer, half_timer_done, timer_done, current_state, start, SPI_CS, SPI_SCLK, SPI_MOSI, data_received, done);
    end

endmodule
