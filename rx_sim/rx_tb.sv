`timescale 1ns / 1ps

module tb_rx;

    // Parameters
    parameter integer BAUD_RATE = 19_200;  // Baud rate
    parameter integer PARITY = 1;            // 1 = Odd, 0 = Even
    parameter integer NUMBER_OF_CHARS = 10;  // Number of characters to transmit

    // Signals
    logic clk;
    logic rst;
    logic tx_start;          // Start signal for the transmitter
    logic [7:0] tx_data;     // Data to transmit
    logic [7:0] rx_data;     // Data received from the receiver
    logic tx_busy;           // Transmitter busy signal
    logic rx_busy;           // Receiver busy signal
    logic tx_out;            // Transmitter output
    logic data_strobe;       // Indicates new data received
    logic rx_error;          // Indicates receiving error
    int errors;

    // Instantiate the transmitter
    tx #(
        .BAUD_RATE(BAUD_RATE)
    ) transmitter (
        .clk(clk),
        .rst(rst),
        .send(tx_start),
        .din(tx_data),
        .tx_out(tx_out),
        .busy(tx_busy)
    );

    // Instantiate the receiver
    rx #(
        .BAUD_RATE(BAUD_RATE),
        .PARITY(PARITY)
    ) receiver (
        .clk(clk),
        .rst(rst),
        .din(tx_out),        // Loop back transmitter output to receiver input
        .dout(rx_data),
        .busy(rx_busy),
        .data_strobe(data_strobe),
        .rx_error(rx_error)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Task to send data
    task send_data(input logic [7:0] data);
        logic [7:0] data_to_send; // Declare this as automatic
        data_to_send = data;
        tx_data = data_to_send;
        tx_start = 1;
        @(posedge clk);
        while (tx_busy) @(posedge clk); // Wait until transmitter is not busy
        tx_start = 0;
        @(posedge clk); // Wait for the clock cycle after sending
    endtask

    // Task to check received data
    task check_received(input logic [7:0] expected);
        logic [7:0] expected_value; // Declare this as automatic
        expected_value = expected;
        @(posedge data_strobe);
        if (rx_data != expected_value) begin
            $display("ERROR: Expected 0x%h but received 0x%h", expected_value, rx_data);
            errors++;
        end else begin
            $display("OK: Received 0x%h", rx_data);
        end
        if (rx_error) begin
            $display("ERROR: Parity or framing error detected.");
            errors++;
        end
    endtask

    // Main test sequence
    initial begin
        errors = 0;

        // Initial reset
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        // Allow some time for the modules to settle
        #100;

        // Test loop
        for (int i = 0; i < NUMBER_OF_CHARS; i++) begin
            // Declare these as automatic
            int delay_cycles;
            logic [7:0] data_to_send;
            delay_cycles = $urandom_range(5, 50);
            repeat (delay_cycles) @(posedge clk);
            data_to_send = $urandom_range(0, 255);
            send_data(data_to_send);
            check_received(data_to_send);
        end

        // End simulation
        $display("Simulation finished with %0d errors.", errors);
        $stop;
    end

endmodule
