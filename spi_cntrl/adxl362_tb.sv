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

    // Instantiate the DUT
    adxl362 #(
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

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // SPI_MISO signal generation based on address
    initial begin
        // Initialize signals
        rst = 0;
        start = 0;
        write = 0;
        address = 8'h00;
        data_to_send = 8'h00;

        // Reset sequence
        #10;
        rst = 1; // Release reset
        #20;
        rst = 0; // Assert reset

        // Wait for a few clock cycles
        #20;

        // Start read sequence for DEVICEID (address 0x00)
        address = 8'h00; // DEVICEID address
        start = 1;
        write = 0; // Read operation
        #10; // Wait for a clock edge
        start = 0;

        wait(done); // Wait until done signal is asserted
        #5; // Allow time for data to settle
        if (data_received !== 8'hAD) 
            $fatal("Error: DEVICEID read failed");

        // Read PARTID (address 0x02)
        address = 8'h02; // PARTID address
        start = 1;
        write = 0; // Read operation
        #10;
        start = 0;
        wait(done);
        #5; // Allow time for data to settle
        if (data_received !== 8'hF2) 
            $fatal("Error: PARTID read failed");

        // Read status register (address 0x0B)
        address = 8'h0B; // Status register address
        start = 1;
        write = 0; // Read operation
        #10;
        start = 0;
        wait(done);
        #5; // Allow time for data to settle
        if (data_received !== 8'h41) 
            $fatal("Error: Status register read failed");

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

    // Generate SPI_MISO output based on the address read
    always_comb begin
        // Drive SPI_MISO based on the address when CS is low
        if (SPI_CS == 0) begin
            case (address)
                8'h00: SPI_MISO = 8'hAD;  // Simulate DEVICEID response
                8'h02: SPI_MISO = 8'hF2;  // Simulate PARTID response
                8'h0B: SPI_MISO = 8'h41;  // Simulate Status register response
                default: SPI_MISO = 8'h00; // Default response for unknown addresses
            endcase
        end else begin
            SPI_MISO = 1'bZ; // High-Z when CS is inactive
        end
    end

endmodule
