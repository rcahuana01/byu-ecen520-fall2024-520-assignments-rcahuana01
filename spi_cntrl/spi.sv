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
    localparam TIMER_RANGE = 15;               // Timer range
    localparam BIT_RANGE = 3;                 // Bit range for counter
    localparam DATA_BITS = 8;                  // Number of data bits
    
    // Internal signals
    logic [7:0] shift_register;           
    logic [BIT_RANGE:0] bitNum;                  
    logic [TIMER_RANGE:0] timer;                  
    logic timer_done, clrTimer, half_timer_done;              
    logic clrBit, incBit, bitDone, bitTimer;  
    logic spi_cs, spi_sclk, spi_mosi;  

    // State definitions
    typedef enum logic [2:0] {IDLE, LOW, HIGH} state_t;
    state_t current_state, next_state;

    // Timer logic block
    always_ff @(posedge clk or posedge rst) begin
        if (rst || clrTimer)
            timer <= 0;                                              
        else
            timer <= timer + 1;                
    end

    // Bit Counter Logic
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
    assign half_timer_done = (timer >= ((CLK_FREQUENCY / SCLK_FREQUENCY) / 2)); 

    assign bitDone = (bitNum == 7);

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
        done = 0;
        spi_cs = 1; // CS inactive
        data_received = 0;
        incBit = 0;
        clrBit = 0;
        case (current_state)
            IDLE: begin
                if (start) begin
                    spi_cs = 0;
                    shift_register = data_to_send;
                    next_state = LOW;
                end
            end

            LOW: begin
                if (half_timer_done) begin // On rising edge of SCLK
                    spi_mosi = shift_register[7 - bitNum];
                    next_state = HIGH;
                    end
                end

            HIGH: begin
                if (timer_done) begin
                    clrTimer = 1;
                    incBit = 1;
                    current_state = LOW; // Return to IDLE state
                end
                else if (timer_done && bitDone) begin
                    current_state = IDLE; // Return to IDLE state
                    done = 1; // Indicate transfer complete
                end
            end
        endcase
    end

    // Assign output signals
    assign spi_cs = hold_cs ? 0 : 1; // Manage CS based on hold_cs
    assign spi_sclk = (current_state == LOW || current_state == HIGH) ? (half_timer_done ? ~spi_sclk : spi_sclk) : 0; // Toggle SCLK
    assign spi_mosi = shift_register[7 - bitNum];

    // State Machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            SPI_SCLK <= 0;
            SPI_MOSI <= 0;
            SPI_CS <= 1;
            shift_register <= 0;
        end
        else begin
            SPI_SCLK <= spi_sclk;
            SPI_MOSI <= spi_mosi;
            SPI_CS <= spi_cs;
            if (half_timer_done) begin
                data_received <= {data_received[6:0], 1'b0}; // Shift left
            end
        end
    end

endmodule
