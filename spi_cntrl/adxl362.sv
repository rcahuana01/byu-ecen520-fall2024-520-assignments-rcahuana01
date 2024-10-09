`timescale 1ns / 1ps
/***************************************************************************
*
* Module: adxl362.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall2024
* Date: 10/20/2024
* Description: ADXL362 Controller for the accelerometer on the Nexys4 board
*
****************************************************************************/
module adxl362_controller (
    input logic clk,                     // Clock
    input logic rst,                     // Reset
    input logic start,                   // Start a transfer
    input logic write,                   // Write operation indicator
    input logic [7:0] data_to_send,     // Data to send
    input logic [7:0] address,           // Address for data transfer
    input logic SPI_MISO,                // SPI MISO signal
    output logic busy,                   // Controller is busy
    output logic done,                   // Transfer done signal
    output logic SPI_SCLK,               // SCLK output signal
    output logic SPI_MOSI,               // MOSI output signal
    output logic SPI_CS,                 // CS output signal
    output logic [7:0] data_received      // Data received
);

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000; // Clock frequency
    parameter SCLK_FREQUENCY = 500_000;     // SCLK frequency

    // Internal signals
    logic [7:0] command;
    logic [7:0] data_out;
    logic start_transfer;
    logic spi_done;  // Rename to avoid conflict

    // SPI Controller Instance
    spi spi_inst (
        .clk(clk),
        .rst(rst),
        .start(start_transfer),
        .data_to_send(data_out),
        .hold_cs(1'b0), // Control CS signal from the ADXL362 controller
        .SPI_MISO(SPI_MISO),
        .busy(busy),
        .done(spi_done),    // Connect the renamed signal
        .SPI_SCLK(SPI_SCLK),
        .SPI_MOSI(SPI_MOSI),
        .SPI_CS(SPI_CS),
        .data_received(data_received)
    );

    // State Machine
    typedef enum logic [2:0] {IDLE, SEND_CMD, SEND_ADDR, SEND_DATA, READ_DATA} state_t;
    state_t current_state, next_state;

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else 
            current_state <= next_state; // Update current state
    end

    // Combinational logic for state machine
    always_comb begin
        start_transfer = 0; // Reset start_transfer
        next_state = current_state; // Default to current state
        
        case (current_state)
            IDLE: begin
                if (start) begin
                    command = write ? 8'h0A : 8'h0B; // Set command byte
                    data_out = (write ? data_to_send : 8'h00); // Prepare data for write
                    start_transfer = 1; // Start transfer
                    next_state = SEND_CMD; // Move to command state
                end
            end
            
            SEND_CMD: begin
                start_transfer = 0; // End start signal
                next_state = SEND_ADDR; // Move to address state
            end
            
            SEND_ADDR: begin
                data_out = address; // Set address for next transfer
                next_state = (write ? SEND_DATA : READ_DATA); // Decide next state based on write flag
            end
            
            SEND_DATA: begin
                data_out = data_to_send; // Send data for write operation
                next_state = IDLE; // Go back to idle state after transfer
            end
            
            READ_DATA: begin
                // No data to send for read, proceed to idle after the read
                next_state = IDLE;
            end
        endcase
    end

    // Indicate transfer complete based on SPI done signal
    assign done = spi_done; // Connect SPI done to module output

endmodule  
