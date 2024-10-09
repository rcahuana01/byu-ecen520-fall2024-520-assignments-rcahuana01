/***************************************************************************
*
* Module: adxl362_tb.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall2024
* Date: 10/09/2024
* Description: Testbench to verify the functionality of the accelerometer on the Nexys4 board
*
****************************************************************************/
module adxl362_tb;

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;
    parameter SCLK_FREQUENCY = 500_000;

    // Signals
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

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Adjust clock period based on CLK_FREQUENCY
    end

    // Instantiate the ADXL362 controller
    adxl362_controller adxl_controller (
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

    // Test sequence
    initial begin
        // Initialize signals
        rst = 1;
        start = 0;
        write = 0;
        address = 8'h00; // Default address
        data_to_send = 8'h00; // Default data

        // Reset the controller
        #10 rst = 0;
        #10 rst = 1;

        // Read DEVICEID
        address = 8'h00; // DEVICEID register
        start = 1;
        #10 start = 0;
        wait(done);
        $display("DEVICEID: %h", data_received);

        // Read PARTID
        address = 8'h02; // PARTID register
        start = 1;
        #10 start = 0;
        wait(done);
        $display("PARTID: %h", data_received);

        // Read Status register
        address = 8'h0B; // Status register
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Status Register: %h", data_received);

        // Write to register (soft reset)
        write = 1;
        address = 8'h1F; // Register address for soft reset
        data_to_send = 8'h52; // Value to write
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Written 0x52 to register 0x1F");

        // End simulation
        #100 $finish;
    end

endmodule
