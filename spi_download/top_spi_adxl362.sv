/***************************************************************************
*
* Module: top_spi_adxl362.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall2024
* Date: 10/14/2024
* Description: Testbench to verify the functionality of top level adxl362
*
****************************************************************************/
module top_spi_adxl362(
    input wire logic CLK100MHZ, 
    input wire logic CPU_RESETN,
    input wire logic [15:0] SW,
    input wire logic BTNL,
    input wire logic BTNR,
    output logic [15:0] LED,
    output logic LED16_B,
    input wire logic ACL_MISO,
    output logic ACL_SCLK, 
    output logic ACL_CSN,
    output logic ACL_MOSI,
    output logic[7:0] AN,
    output logic CA, CB, CC, CD, CE, CF, CG, DP
);

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;
    parameter SEGMENT_DISPLAY_US = 1_000;
    parameter DEBOUNCE_TIME_US = 1_000;
    parameter SCLK_FREQUENCY = 1_000_000;
    parameter DISPLAY_RATE = 2;
    
    // Instantiate SPI and ADXL362 controllers
    wire [7:0] read_data;
    wire busy;
    
    adxl362_controller adxl362_inst (
        .clk(CLK100MHZ),
        .resetn(CPU_RESETN),
        .MISO(ACL_MISO),
        .SCLK(ACL_SCLK),
        .CSN(ACL_CSN),
        .MOSI(ACL_MOSI),
        .busy(busy),
        .read_data(read_data)
    );
    
    // Handle LED display and switches logic
    assign LED[7:0] = SW[7:0];  // Display address on LEDs
    assign LED[15:8] = SW[15:8]; // Display data on LEDs
    assign LED16_B = busy;

    // Read X, Y, Z accelerometer values
    // Display them on 7-segment display
    
endmodule
