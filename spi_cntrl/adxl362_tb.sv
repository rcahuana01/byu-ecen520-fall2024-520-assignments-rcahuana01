`timescale 1ns / 1ps
/***************************************************************************
*
* Module: adxl362_tb.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall2024
* Date: 10/20/2024
* Description: Testbench for the ADXL362 Controller
*
****************************************************************************/

module adxl362_tb #(parameter CLK_FREQUENCY = 100_000_000,
                    parameter SCLK_FREQUENCY = 500_000) ();

    // Declare signals for the testbench
    logic clk;
    logic rst;
    logic start;
    logic write;
    logic [7:0] data_to_send;
    logic [7:0] address;
    logic SPI_MISO;
    logic busy;
    logic done;
    logic SPI_SCLK;
    logic SPI_MOSI;
    logic SPI_CS;
    logic [7:0] data_received;

    // Instantiate the DUT (Device Under Test)
    adxl362_controller #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .SCLK_FREQUENCY(SCLK_FREQUENCY)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .write(write),
        .data_to_send(data_to_send),
        .address(address),
        .SPI_MISO(SPI_MISO),
        .busy(busy),
        .done(done),
        .SPI_SCLK(SPI_SCLK),
        .SPI_MOSI(SPI_MOSI),
        .SPI_CS(SPI_CS),
        .data_received(data_received)
    );

    // Simulation model for ADXL362 (stub for testing)
    // You should replace this with a complete model that responds correctly
    // to the SPI communication.
    initial begin
        // Initialize signals
        SPI_MISO = 1; // Default MISO high
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Test vector generation
    initial begin
        // Execute the simulation for a few clock cycles without setting any inputs
        #10;

        // Reset sequence
        rst = 0; // Active low reset
        #10;
        rst = 1;

        // Wait for a few clock cycles
        #20;

        // Start read sequence for DEVICEID (address 0x0)
        address = 8'h00; // DEVICEID address
        start = 1;
        write = 0; // Read operation
        #10; // Hold start for a clock cycle
        start = 0;
        wait(done); // Wait until done signal is asserted
        assert(data_received == 8'hAD) else $fatal("Error: DEVICEID read failed");

        // Read PARTID (address 0x02)
        address = 8'h02; // PARTID address
        start = 1;
        write = 0; // Read operation
        #10; 
        start = 0;
        wait(done);
        assert(data_received == 8'hF2) else $fatal("Error: PARTID read failed");

        // Read status register (address 0x0B)
        address = 8'h0B; // Status register address
        start = 1;
        write = 0; // Read operation
        #10; 
        start = 0;
        wait(done);
        assert(data_received == 8'h41) else $fatal("Error: Status register read failed");

        // Write to register 0x1F for soft reset
        address = 8'h1F; // Soft reset register
        data_to_send = 8'h52; // Data to write
        start = 1;
        write = 1; // Write operation
        #10; 
        start = 0;
        wait(done);

        // Finish simulation
        $finish;
    end

endmodule
