`timescale 1ns / 1ps
/***************************************************************************
*
* Module: adxl362_controller.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520, Section 01, Fall2024
* Date: 10/20/2024
* Description: ADXL362 Controller for the accelerometer on the Nexys4 board
*
****************************************************************************/
module adxl362_controller (
    input wire logic clk,                     // Clock
    input wire logic rst,                     // Reset
    input wire logic start,                   // Start a transfer
    input wire logic write,                   // Write operation indicator
    input wire logic [7:0] data_to_send,      // Data to send
    input wire logic [7:0] address,           // Address for data transfer
    input wire logic SPI_MISO,                // SPI MISO signal
    output logic busy,                        // Controller is busy
    output logic done,                        // Transfer done signal
    output logic SPI_SCLK,                    // SCLK output signal
    output logic SPI_MOSI,                    // MOSI output signal
    output logic SPI_CS,                      // CS output signal
    output logic [7:0] data_received          // Data received
);

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;    // Clock frequency
    parameter SCLK_FREQUENCY = 500_000;       // SCLK frequency
    // Internal signals
    logic [7:0] spi_data_to_send;
    logic spi_start;
    logic hold_cs;
    logic spi_done, spi_busy;
    logic [7:0] spi_data_received;                // Clock divider counter for SCLK generation

    // SPI Controller Instance
    spi_controller spi_inst (
        .clk(clk),
        .rst(rst),
        .start(spi_start),  //start a transfer
        .data_to_send(spi_data_to_send), //Data to send to subunit
        .hold_cs(hold_cs), // Hold CS signal based on the ADXL362 controller
        .SPI_MISO(SPI_MISO), //SPI MISO signal
        .busy(spi_busy), //Output Controller is busy
        .done(spi_done), //Output One clock cycle signal indicating that the transfer is done 
        .SPI_SCLK(SPI_SCLK), //Output signals
        .SPI_MOSI(SPI_MOSI), //Output signal
        .SPI_CS(SPI_CS),    //Output signal
        .data_received(spi_data_received) //Output Data receive on the last transfer
    );

   // State Machine
typedef enum logic [2:0] {IDLE, SEND_BYTE_0, SEND_BYTE_1, SEND_BYTE_2} state_t;
state_t current_state, next_state;

// State register
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

// Combinational logic for state machine
  always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (start) next_state = SEND_BYTE_0;  // Start transfer
            end
            SEND_BYTE_0: begin
                if (spi_done) next_state = SEND_BYTE_1;  // Opcode sent, proceed to send address
            end
            SEND_BYTE_1: begin
                if (spi_done) next_state = SEND_BYTE_2;  // Address sent, proceed to send/receive data
            end
            SEND_BYTE_2: begin
                if (spi_done) next_state = IDLE;  // Transfer complete, return to IDLE
            end
            default: begin
                next_state = IDLE;      
            end
        endcase
    end

/***************************************************************************
    * Sequential logic for SPI communication and state machine operation
    * This block manages data transfers, chip select, and busy/done signals.
    ***************************************************************************/
always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            spi_start <= 0;
            hold_cs <= 0;
            busy <= 0;
            done <= 0;
            spi_data_to_send <= 8'b0;
        end else begin
            // Default values for control signals
            spi_start <= 0;  // Deassert spi_start unless set in this cycle
            done <= 0;       // Deassert done unless set in this cycle

            case (current_state)
                IDLE: begin
                    busy <= 0;
                    hold_cs <= 0;
                    if (start) begin
                        busy <= 1;
                        hold_cs <= 1;
                        spi_start <= 1;  // Assert spi_start for one clock cycle
                        spi_data_to_send <= (write) ? 8'h0A : 8'h0B;  // Opcode for read or write
                    end
                end
                SEND_BYTE_0: begin
                    hold_cs <= 1;
                    if (spi_done) begin
                        spi_start <= 1;  // Assert spi_start for one clock cycle
                        spi_data_to_send <= address;  // Send the address
                    end
                end
                SEND_BYTE_1: begin
                    hold_cs <= 1;
                    if (spi_done) begin
                        spi_start <= 1;  // Assert spi_start for one clock cycle
                        spi_data_to_send <= (write) ? data_to_send : 8'h00;  // Send data or dummy byte for read
                    end
                end
                SEND_BYTE_2: begin
                    hold_cs <= 1;
                    if (spi_done) begin
                        if (!write) begin
                            data_received <= spi_data_received;  // Capture received data if reading
                        end
                        hold_cs <= 0;  // Release chip select after last byte
                        done <= 1;     // Indicate transfer completion
                        busy <= 0;     // Clear busy flag
                       end
                end
            default: begin
                spi_start <= 0;
                hold_cs <= 0;
                busy <= 0;
                done <= 0;
                spi_data_to_send <= 8'b0;
            end
            endcase     
        end
    end




endmodule