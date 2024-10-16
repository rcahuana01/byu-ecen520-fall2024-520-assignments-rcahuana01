`timescale 1ns / 1ps

/***************************************************************************
*
* Module: top_spi_adxl362_tb.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520, Section 01, Fall 2024
* Date: 10/14/2024
* Description: Testbench for SPI Top-Level ADXL362 Controller
*
****************************************************************************/

module top_spi_adxl362_tb;

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;  // 100 MHz clock
    parameter SCLK_FREQUENCY = 1_000_000;   // 1 MHz SPI clock
    parameter SEGMENT_DISPLAY_US = 1_000;   // Segment display time in microseconds

    // Testbench signals
    logic CLK100MHZ;
    logic CPU_RESETN;
    logic [15:0] SW;
    logic BTNL;
    logic BTNR;
    logic [15:0] LED;
    logic LED16_B;
    logic ACL_MISO;
    logic ACL_SCLK;
    logic ACL_CSN;
    logic ACL_MOSI;
    logic [7:0] AN;
    logic CA, CB, CC, CD, CE, CF, CG;
    logic DP;
    logic [6:0] segments;
    logic [31:0] output_display_val;
    logic new_value;

    // Instance of the top-level design
    top_spi_adxl362 #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .SCLK_FREQUENCY(SCLK_FREQUENCY),
        .SEGMENT_DISPLAY_US(SEGMENT_DISPLAY_US)
    ) dut (
        .CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .SW(SW),
        .BTNL(BTNL),
        .BTNR(BTNR),
        .LED(LED),
        .LED16_B(LED16_B),
        .ACL_MISO(ACL_MISO),
        .ACL_SCLK(ACL_SCLK),
        .ACL_CSN(ACL_CSN),
        .ACL_MOSI(ACL_MOSI),
        .AN(AN),
        .CA(CA),
        .CB(CB),
        .CC(CC),
        .CD(CD),
        .CE(CE),
        .CF(CF),
        .CG(CG),
        .DP(DP)
    );

    // Instance of the ADXL362 simulation model
    adxl362_model adxl362_sim_inst (
        .miso(ACL_MISO),
        .sclk(ACL_SCLK),
        .cs(ACL_CSN),
        .mosi(ACL_MOSI)
    );

    // Clock generation
    initial begin
        CLK100MHZ = 0;
        forever #5 CLK100MHZ = ~CLK100MHZ;  // Generate a clock with 10ns period (100 MHz)
    end

    // Test sequence
    initial begin
        // Initial state
        CPU_RESETN = 0;
        SW = 16'h0000;
        BTNL = 0;
        BTNR = 0;
        ACL_MISO = 0;

        // Wait for a few clock cycles
        #100;

        // Apply reset
        $display("[%0tns] Applying reset...", $time);
        CPU_RESETN = 0;
        repeat (5) @(negedge CLK100MHZ);  // Hold reset for a few cycles
        CPU_RESETN = 1;
        $display("[%0tns] Release reset", $time);

        // Simulate a read from the X-axis register (address 0x08)
        $display("[%0tns] Simulate read from X-axis (0x08)", $time);
        SW = 16'h0008;  // Set the address to 0x08 (X-axis)
        BTNR = 1;       // Trigger the read operation
        @(negedge CLK100MHZ);
        BTNR = 0;       // Clear the read button
        #20;

        // Simulate a read from the Y-axis register (address 0x09)
        $display("[%0tns] Simulate read from Y-axis (0x09)", $time);
        SW = 16'h0009;  // Set the address to 0x09 (Y-axis)
        BTNR = 1;       // Trigger the read operation
        @(negedge CLK100MHZ);
        BTNR = 0;       // Clear the read button
        #20;

        // Simulate a read from the Z-axis register (address 0x0A)
        $display("[%0tns] Simulate read from Z-axis (0x0A)", $time);
        SW = 16'h000A;  // Set the address to 0x0A (Z-axis)
        BTNR = 1;       // Trigger the read operation
        @(negedge CLK100MHZ);
        BTNR = 0;       // Clear the read button
        #20;

        // Simulate writing a value to an ADXL362 register
        $display("[%0tns] Simulate write to ADXL362 register (0x1F)", $time);
        SW = {8'h52, 8'h1F};  // Write 0x52 to address 0x1F
        BTNL = 1;             // Trigger the write operation
        @(negedge CLK100MHZ);
        BTNL = 0;             // Clear the write button
        #20;

        // Display simulated seven-segment display values (dummy data for now)
        $display("[%0tns] Displaying values on the seven-segment display", $time);
        #500;  // Wait a few cycles to simulate display update
        $display("Seven-segment display values: AN=%b, segments={CA=%b, CB=%b, CC=%b, CD=%b, CE=%b, CF=%b, CG=%b}, DP=%b", 
            AN, CA, CB, CC, CD, CE, CF, CG, DP);

        // Finish the simulation
        #100;
        $finish;
    end

endmodule
