`timescale 1ns / 1ps
/***************************************************************************
*
* Module: top_spi_adxl362.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520, Section 01, Fall 2024
* Date: 10/14/2024
* Description: SPI Top-Level Design
*
****************************************************************************/
module top_spi_adxl362(
    input wire logic CLK100MHZ,              // 100 MHz clock input
    input wire logic CPU_RESETN,             // Active-low reset signal
    input wire logic [15:0] SW,              // Switches for address and data
    input wire logic BTNL,                    // Button for write operation
    input wire logic BTNR,                    // Button for read operation
    output logic [15:0] LED,                 // LEDs displaying switches
    output logic LED16_B,                     // LED showing busy signal
    input wire logic ACL_MISO,                // ADXL362 SPI MISO
    output logic ACL_SCLK,                    // ADXL362 SPI SCLK
    output logic ACL_CSN,                     // ADXL362 SPI CSN
    output logic ACL_MOSI,                    // ADXL362 SPI MOSI
    output logic [7:0] AN,                    // Seven-segment anode signals
    output logic CA, CB, CC, CD, CE, CF, CG,  // Seven-segment cathode signals
    output logic DP                            // Seven-segment decimal point
);

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;   // Clock frequency in Hz
    parameter SEGMENT_DISPLAY_US = 1_000;     // Time to display each digit in microseconds (1 ms)
    parameter DEBOUNCE_TIME_US = 1_000;       // Minimum debounce delay in microseconds (1 us)
    parameter SCLK_FREQUENCY = 1_000_000;     // ADXL SPI SCLK rate in Hz
    parameter DISPLAY_RATE = 2;                // Update rate for displaying values (2 times a second)

    // Internal signals
    logic clk, rst, adxl362_write, adxl362_start, adxl362_done, adxl362_busy;  // Control signals for operation
    logic [7:0] adxl362_data_to_send, address, adxl362_data_received;  // Data for SPI communication
    logic [7:0] x_axis, y_axis, z_axis;  // Accelerometer readings
    logic [7:0] rx_registers[3:0];        // Data registers for X, Y, Z
    logic start_read, start_write;
    logic [31:0] segment_clock_divider;
    logic [7:0] display_val[7:0];

    // Assign reset and clock
    assign clk = CLK100MHZ;                // Assign input clock
    assign rst = ~CPU_RESETN;              // Active-low reset signal
    assign LED[15:0] = SW[15:0];           // Display upper 8 switches on LEDs

    // Instantiate ADXL362 Controller
    adxl362_controller adxl362_inst (
        .clk(clk),                            
        .rst(rst),                            
        .start(start_read),                     
        .write(adxl362_write),                 
        .data_to_send(adxl362_data_to_send),   
        .address(SW[7:0]),                     // Address set by lower 8 switches
        .SPI_MISO(ACL_MISO),                    
        .busy(adxl362_busy),                    // Busy signal output to LED16_B
        .done(adxl362_done),                    
        .SPI_SCLK(ACL_SCLK),                    
        .SPI_MOSI(ACL_MOSI),                    
        .SPI_CS(ACL_CSN),                      
        .data_received(adxl362_data_received)    
    );

    // Debounce and control logic for buttons
    debounce #(.DEBOUNCE_CLKS((CLK_FREQUENCY / 1_000_000) * DEBOUNCE_TIME_US)) btnl_debounce (
        .clk(clk),
        .rst(rst),
        .async_in(BTNL),
        .debounce_out(start_write)  // Debounced output for left button
    );

    debounce #(.DEBOUNCE_CLKS((CLK_FREQUENCY / 1_000_000) * DEBOUNCE_TIME_US)) btnr_debounce (
        .clk(clk),
        .rst(rst),
        .async_in(BTNR),
        .debounce_out(start_read)  // Debounced output for right button
    );

    // Control logic for starting read/write operations
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            adxl362_start <= 0;              // Reset start signal
            adxl362_write <= 0;              // Reset write signal
        end else begin
            adxl362_start <= 0;  // Default to 0
            adxl362_write <= 0;  // Default to 0

            if (start_write) begin
                adxl362_start <= 1;  
                adxl362_write <= 1;  
                adxl362_data_to_send <= SW[15:8];  // Data for write operation
            end else if (start_read) begin
                adxl362_start <= 1;  
                adxl362_write <= 0;  // Clear write flag for read
            end else if (adxl362_done) begin
                adxl362_start <= 0;  // Clear start signal when done
            end
        end
    end

    // Store received data in the respective registers
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_registers[0] <= 0; // Reset X-Axis register
            rx_registers[1] <= 0; // Reset Y-Axis register
            rx_registers[2] <= 0; // Reset Z-Axis register
            rx_registers[3] <= 0; // Reset unused register
        end else if (adxl362_done && !adxl362_write) begin
            // Store received data based on address
            case (SW[7:0])
                8'h08: rx_registers[0] <= adxl362_data_received; // X-Axis
                8'h09: rx_registers[1] <= adxl362_data_received; // Y-Axis
                8'h0A: rx_registers[2] <= adxl362_data_received; // Z-Axis
            endcase
        end
    end

    // Clock divider for Seven-Segment Display
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            segment_clock_divider <= 0;
        end else if (segment_clock_divider == (CLK_FREQUENCY / 1_000_000) * SEGMENT_DISPLAY_US) begin
            segment_clock_divider <= 0;
        end else begin
            segment_clock_divider <= segment_clock_divider + 1;
        end
    end

    // Update the Seven-Segment Display based on clock divider
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            display_val[0] <= 0;
            display_val[1] <= 0;
            display_val[2] <= rx_registers[0]; // X-Axis High nibble
            display_val[3] <= rx_registers[0]; // X-Axis Low nibble
            display_val[4] <= rx_registers[1]; // Y-Axis High nibble
            display_val[5] <= rx_registers[1]; // Y-Axis Low nibble
            display_val[6] <= rx_registers[2]; // Z-Axis High nibble
            display_val[7] <= rx_registers[2]; // Z-Axis Low nibble
        end else if (segment_clock_divider == 0) begin
            display_val[0] <= display_val[0];  // Keep display value for proper multiplexing
            // Cycle through display values for each digit (update if necessary)
        end
    end

    // Instantiate Seven-Segment Display Controller
    ssd #(
        .CLK_FREQUENCY(CLK_FREQUENCY),          // Pass clock frequency
        .MIN_SEGMENT_DISPLAY_US(SEGMENT_DISPLAY_US) // Pass segment display timing
    ) display_controller (
        .clk(CLK100MHZ),                        // Use the main clock for display
        .rst(rst),                              // Reset signal
        .display_val({rx_registers[2], rx_registers[1], rx_registers[0], 8'b0}*10000), // Display last read values
        .dp(8'b00000000),                       // Disable decimal point
        .blank(1'b0),                           // Do not blank display
        .segments({CA, CB, CC, CD, CE, CF, CG}), // Cathode signals for display
        .dp_out(DP),                            // Output for decimal point
        .an_out(AN)                             // Output for anode signals
    );

endmodule
