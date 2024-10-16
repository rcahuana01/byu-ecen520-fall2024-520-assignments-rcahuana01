`timescale 1ns / 1ps
/***************************************************************************
*
* Module: adxl362_controller_tb.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall2024
* Date: 10/20/2024
* Description: Testbench for the ADXL362 Controller for the accelerometer on the Nexys4 board
*
****************************************************************************/
module adxl362_controller_tb;

     // Parameters for clock frequencies
    parameter CLK_FREQUENCY = 100_000_000;
    parameter SCLK_FREQUENCY = 500_000;

    // Testbench signals
    reg clk;
    reg rst;
    reg start;
    reg write;
    reg [7:0] data_to_send;
    reg [7:0] address;
    wire [7:0] data_received;
    wire SPI_SCLK;
    wire SPI_MOSI;
    wire SPI_CS;
    wire SPI_MISO;
    wire busy;
    wire done;

    /***************************************************************************
    * Clock generation
    * Generates a 100 MHz clock (10 ns period) for the testbench.
    ***************************************************************************/
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle clock every 5 ns
    end

    /***************************************************************************
    * Instantiation: ADXL362 Controller
    * The controller manages SPI communication with the ADXL362 accelerometer.
    ***************************************************************************/
    adxl362_controller #(
        .SCLK_FREQUENCY(SCLK_FREQUENCY)
    ) adxl_inst (
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

    /***************************************************************************
    * Instantiation: ADXL362 Model
    * The ADXL362 simulation model acts as the slave device for SPI communication.
    ***************************************************************************/
    adxl362_model model (
        .sclk(SPI_SCLK),
        .mosi(SPI_MOSI),
        .miso(SPI_MISO),
        .cs(SPI_CS)
    );

    /***************************************************************************
    * Testbench process
    * This process simulates reading from and writing to ADXL362 registers,
    * verifying that the controller handles SPI communication correctly.
    ***************************************************************************/
    initial begin
        // Initialize inputs
        rst = 1;
        start = 0;
        write = 0;
        address = 8'h00;
        data_to_send = 8'h00;

        // Reset sequence
        #20 rst = 0;

        // Wait for a few clock cycles
        #20;

        /***************************************************************************
        * Read DEVICEID register (0x00)
        * The test reads the DEVICEID register and verifies the received value.
        ***************************************************************************/
        address = 8'h00;
        write = 0; // Read operation
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge done);
        if (data_received == 8'hAD) begin
            $display("SUCCESS: DEVICEID = 0x%h", data_received);
        end else begin
            $display("ERROR: DEVICEID Expected 0xAD, Got 0x%h", data_received);
        end

        /***************************************************************************
        * Read PARTID register (0x02)
        * The test reads the PARTID register and verifies the received value.
        ***************************************************************************/
        address = 8'h02;
        write = 0; // Read operation
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge done);
        if (data_received == 8'hF2) begin
            $display("SUCCESS: PARTID = 0x%h", data_received);
        end else begin
            $display("ERROR: PARTID Expected 0xF2, Got 0x%h", data_received);
        end

        /***************************************************************************
        * Read STATUS register (0x0B)
        * The test reads the STATUS register and verifies the received value.
        ***************************************************************************/
        address = 8'h0B;
        write = 0; // Read operation
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge done);
        if (data_received == 8'h41) begin
            $display("SUCCESS: STATUS = 0x%h", data_received);
        end else begin
            $display("ERROR: STATUS Expected 0x41, Got 0x%h", data_received);
        end

        /***************************************************************************
        * Write 0x52 to register 0x1F for a soft reset
        * The test writes the reset command to initiate a soft reset.
        ***************************************************************************/
        address = 8'h1F;
        data_to_send = 8'h52;
        write = 1; // Write operation
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge done);
        $display("Soft reset command sent to register 0x%h", address);

        // End simulation
        #100;
        $stop;
    end
endmodule