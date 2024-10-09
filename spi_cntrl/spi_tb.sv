`timescale 1ns / 1ps
/***************************************************************************
*
* Module: spi_tb.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520
* Date: 10/09/2024
* Description: Testbench to verify the functionality of the SPI controller
*
****************************************************************************/
module spi_tb();

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;  // Clock frequency (100 MHz)
    parameter SCLK_FREQUENCY = 500_000;      // SCLK frequency (500 kHz)

    // Inputs and outputs
    reg clk;
    reg rst;
    reg start;
    reg hold_cs;
    reg [7:0] data_to_send;
    wire [7:0] data_received;
    wire busy;
    wire done;
    wire SPI_SCLK;
    wire SPI_MOSI;
    wire SPI_CS;
    wire SPI_MISO;

    // Subunit signals
    wire[7:0] subunit_received_value;
    reg[7:0] subunit_send_value;
    wire subunit_new_value;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Flip clock every 5ns
    end

    // Instantiate the SPI controller
    spi #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .SCLK_FREQUENCY(SCLK_FREQUENCY)
    ) spi_cntrl (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_to_send(data_to_send),
        .hold_cs(hold_cs),
        .SPI_MISO(SPI_MISO),
        .data_received(data_received),
        .busy(busy),
        .done(done),
        .SPI_SCLK(SPI_SCLK),
        .SPI_MOSI(SPI_MOSI),
        .SPI_CS(SPI_CS)
    );

    // Instantiate the SPI subunit model
    spi_subunit spi_sub (
        .sclk(SPI_SCLK),
        .mosi(SPI_MOSI),
        .miso(SPI_MISO),
        .cs(SPI_CS),
        .send_value(subunit_send_value), // Sending a dummy value initially
        .received_value(subunit_received_value),
        .new_value(subunit_new_value)
    );
        // Task to send a single byte
    task single_byte_transfer(input [7:0] data);
        begin
            @(posedge clk); // Wait for the rising edge of the clock
            data_to_send = data;
            hold_cs = 0;
            start = 1;
            @(posedge clk); // Wait for the rising edge of the clock
            start = 0;
            wait(done == 1);  // Wait for transaction to complete
            $display("Sent: 0x%02X, Received: 0x%02X", data, data_received);
            if (data_received == subunit_send_value) begin
                $display("Success: Sent 0x%h, Received 0x%h", data, data_received);
            end else begin
                $display("Error: Sent 0x%h, Received 0x%h", data, data_received);
            end
        end
    endtask

    // Task to send multiple bytes
    task multi_byte_transfer(input [7:0] data_byte1, input [7:0] data_byte2);
        begin
            @(posedge clk); // Wait for the rising edge of the clock
            data_to_send = data_byte1;
            hold_cs = 1;  // Keep CS low for multi-byte transaction
            start = 1;
            @(posedge clk); // Wait for the rising edge of the clock
            start = 0;
            wait(done == 1);  // Wait for transaction to complete
            $display("Sent: 0x%02X, Received: 0x%02X", data_byte1, data_received);
            if (data_received == subunit_send_value) begin
                $display("Success: Sent 0x%h, Received 0x%h", data_byte1, data_received);
            end else begin
                $display("Error: Sent 0x%h, Received 0x%h", data_byte1, data_received);
            end
            
            data_to_send = data_byte2;
            hold_cs = 0;
            start = 1;
            @(posedge clk); // Wait for the rising edge of the clock
            start = 0;
            wait(done);
            $display("Sent: 0x%02X, Received: 0x%02X", data_byte2, data_received);
            if (data_received == subunit_send_value) begin
                $display("Success: Sent 0x%h, Received 0x%h", data_byte2, data_received);
            end else begin
                $display("Error: Sent 0x%h, Received 0x%h", data_byte2, data_received);
            end
        end
    endtask
    
    // Main process testbench
    initial begin
        // Initialize signals
        clk = 0; // Initialize the clock
        rst = 1;
        start = 0;
        data_to_send = 8'h00;
        hold_cs = 1;
        subunit_send_value = 8'hA4; // Initialize with expected value
        #100ns;

        // Reset sequence
        rst = 0; // Release reset
        #20;

        // Send a single byte
        for (int i = 0; i < 10; i = i + 1) begin // Change 5 to however many bytes you want to send
            single_byte_transfer(8'hA4 + i); // Example: Send values A4, A5, A6, A7, A8
            @(posedge clk); // Wait for next clock edge
        end

        // Send multiple bytes
        for (int j = 0; j < 5; j = j + 1) begin // Change 3 to however many pairs of bytes you want to send
            multi_byte_transfer(8'hA4 + j, 8'hA1 + j); // Example: Send pairs (A4,A1), (A5,A2), (A6,A3)
            @(posedge clk); // Wait for next clock edge
        end

        // End simulation
        #100;
        $stop;
    end

endmodule
