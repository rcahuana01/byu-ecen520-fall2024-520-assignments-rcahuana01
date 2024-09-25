`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// RX Testbench
//////////////////////////////////////////////////////////////////////////////////

module tb_receiver;

    // Testbench parameters
    parameter integer BAUD_RATE = 19_200;       // Baud rate for transmitter and receiver
    parameter integer PARITY = 1;                // 1 = Odd parity, 0 = Even parity
    parameter integer NUMBER_OF_CHARS = 10;      // Number of characters to transmit

    // Signals
    logic clk;
    logic rst;
    logic tx_start;            // Start signal for the transmitter
    logic [7:0] tx_data;       // Data to transmit
    logic [7:0] rx_data;       // Data received from the receiver
    logic tx_busy;             // Transmitter busy signal
    logic rx_busy;             // Receiver busy signal
    logic tx_out;              // Transmitter output (to receiver input)
    logic data_strobe;         // Indicates new data received
    logic rx_error;            // Indicates receiving error
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

    // Task for initiating a transfer
    task send_data(input logic [7:0] char_value);
        @(negedge clk);  // Wait for a negative clock edge
        $display("[%0tns] Transmitting 0x%h", $time/1000.0, char_value);

        // Set inputs
        tx_data = char_value;
        tx_start = 1;

        // Wait for next clock cycle
        @(negedge clk);

        // Wait until busy goes high or reset is asserted
        wait (tx_busy == 1'b1 || rst == 1'b1);

        // Deassert send
        @(negedge clk);
        tx_start = 0;

        // Wait for data to be received
        @(posedge data_strobe);
        if (rx_data == char_value) begin
            $display("OK: Sent 0x%h, Received 0x%h", char_value, rx_data);
        end else begin
            $display("ERROR: Sent 0x%h, Received 0x%h", char_value, rx_data);
            errors++;
        end
    endtask

    //////////////////////////////////
    // Main Test Bench Process
    //////////////////////////////////
    initial begin
        // Declare local variables here
        int delay_cycles; // Declare delay_cycles as automatic
        logic [7:0] data_to_send; // Declare data_to_send as automatic

        errors = 0;

        // Initial reset
        rst = 1;
        #20; // Hold reset for a while
        rst = 0;

        // Allow some time for the modules to settle
        #100;

        // Main test loop
        for (int i = 0; i < NUMBER_OF_CHARS; i++) begin
            delay_cycles = $urandom_range(5, 50); // Wait a random number of clock cycles
            repeat (delay_cycles) @(posedge clk);
            data_to_send = $urandom_range(0, 255); // Generate random 8-bit data
            send_data(data_to_send);
        end

        // End simulation
        $display("Simulation finished with %0d errors.", errors);
        $stop;
    end

endmodule
