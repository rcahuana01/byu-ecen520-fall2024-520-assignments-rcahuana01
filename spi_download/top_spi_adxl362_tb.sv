`timescale 1ns / 1ps
/***************************************************************************
*
* Module: top_spi_adxl362_tb.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520, Section 01, Fall 2024
* Date: 10/15/2024
* Description: Testbench for Top-Level ADXL362 SPI Controller
*
****************************************************************************/
module top_spi_adxl362_tb;

    // Parameters (parameterizable testbench)
    parameter CLK_FREQUENCY = 100_000_000;    // System clock frequency (in Hz)
    parameter SEGMENT_DISPLAY_US = 1_000;     // Time to display each digit (in microseconds)
    parameter DEBOUNCE_TIME_US = 1_000;       // Debounce time for buttons (in microseconds)
    parameter SCLK_FREQUENCY = 1_000_000;     // SPI clock frequency (in Hz)
    parameter DISPLAY_RATE = 2;               // Times per second to update display

    // Clock and reset signals
    reg CLK100MHZ;
    reg CPU_RESETN;  // Active low reset

    // Inputs
    reg [15:0] SW;
    reg BTNL;
    reg BTNR;

    // Outputs
    wire [15:0] LED;
    wire LED16_B;
    wire ACL_SCLK;
    wire ACL_CSN;
    wire ACL_MOSI;
    wire [7:0] AN;
    wire CA, CB, CC, CD, CE, CF, CG;
    wire DP;

    // Bidirectional (MISO signal from accelerometer)
    wire ACL_MISO;

    // Instantiate the top-level design
    top_spi_adxl362 #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .SEGMENT_DISPLAY_US(SEGMENT_DISPLAY_US),
        .DEBOUNCE_TIME_US(DEBOUNCE_TIME_US),
        .SCLK_FREQUENCY(SCLK_FREQUENCY),
        .DISPLAY_RATE(DISPLAY_RATE)
    ) spi_top_inst (
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
        .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG),
        .DP(DP)
    );

    // Instantiate the ADXL362 simulation model
    adxl362_model adxl362_model_inst (
        .sclk(ACL_SCLK),
        .mosi(ACL_MOSI),
        .miso(ACL_MISO),
        .cs(ACL_CSN)
    );

    // Clock generation (100 MHz)
    initial begin
        CLK100MHZ = 0;
        forever #(5) CLK100MHZ = ~CLK100MHZ;  // Clock period = 10 ns (100 MHz)
    end

    // Testbench tasks and procedures

    // Task to read a register and verify the expected data
    task automatic read_register(input [7:0] addr, input [7:0] expected_data);
        begin
            // Set the address on switches (lower 8 bits)
            SW[7:0] = addr;
            SW[15:8] = 8'd0;  // Clear data switches
            @(negedge CLK100MHZ);

            // Press the right button to initiate read
            BTNR = 1'b1;
            @(negedge CLK100MHZ);
            BTNR = 1'b0;  // Release button

            // Wait for operation to complete
            wait (LED16_B == 1'b1);  // Wait until busy goes high
            wait (LED16_B == 1'b0);  // Wait until busy goes low

            // Wait a few cycles to allow data capture
            repeat(5) @(negedge CLK100MHZ);

            // Check the last data received
            if (spi_top_inst.last_data_received !== expected_data) begin
                $display("[%0t ns] ERROR: Read from address 0x%02X - Expected 0x%02X, Got 0x%02X", $time, addr, expected_data, spi_top_inst.last_data_received);
            end else begin
                $display("[%0t ns] SUCCESS: Read from address 0x%02X returned 0x%02X as expected", $time, addr, expected_data);
            end
        end
    endtask

    // Task to write a value to a register
    task automatic write_register(input [7:0] addr, input [7:0] data);
        begin
            // Set the address and data on switches
            SW[7:0] = addr;
            SW[15:8] = data;
            @(negedge CLK100MHZ);

            // Press the left button to initiate write
            BTNL = 1'b1;
            @(negedge CLK100MHZ);
            BTNL = 1'b0;  // Release button

            // Wait for operation to complete
            wait (LED16_B == 1'b1);  // Wait until busy goes high
            wait (LED16_B == 1'b0);  // Wait until busy goes low

            $display("[%0t ns] Write operation to address 0x%02X with data 0x%02X completed", $time, addr, data);
        end
    endtask

    // Main testbench sequence
    initial begin
        // Initial values
        CPU_RESETN = 1'b1;  // Deassert reset (active low)
        SW = 16'd0;
        BTNL = 1'b0;
        BTNR = 1'b0;

        // Let the simulation run for a few clock cycles without inputs
        #100;

        // Assert reset
        $display("[%0t ns] Applying reset...", $time);
        CPU_RESETN = 1'b0;  // Assert reset
        #100;               // Hold reset low for some time

        // Add short wait after asserting reset for stabilization (debounce)
        repeat(5) @(negedge CLK100MHZ);

        CPU_RESETN = 1'b1;  // Deassert reset
        $display("[%0t ns] Reset deasserted", $time);

        // Add short wait after deasserting reset for stabilization (debounce)
        repeat(10) @(negedge CLK100MHZ);  // Wait 10 clock cycles for system to stabilize

        // Wait for a few clock cycles
        #100;

        // Read DEVICEID register (0x00), expected 0xAD
        $display("[%0t ns] Reading DEVICEID register (0x00)...", $time);
        read_register(8'h00, 8'hAD);

        // Read PARTID register (0x02), expected 0xF2
        $display("[%0t ns] Reading PARTID register (0x02)...", $time);
        read_register(8'h02, 8'hF2);

        // Read STATUS register (0x0B), expected 0x41
        $display("[%0t ns] Reading STATUS register (0x0B)...", $time);
        read_register(8'h0B, 8'h41);

        // Write 0x52 to register 0x1F (soft reset)
        $display("[%0t ns] Writing 0x52 to register 0x1F (soft reset)...", $time);
        write_register(8'h1F, 8'h52);

        // End of test
        $display("[%0t ns] All tests completed successfully", $time);
        $stop;
    end

endmodule
