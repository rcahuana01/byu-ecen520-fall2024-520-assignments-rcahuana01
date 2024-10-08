`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  
//  Module name: rx_tb.sv
//  Name: Rodrigo Cahuana
//  Class: ECEN 520
//  Date: 09/24/2024
//  Description: Testbench for UART Receiver module. 
//
//////////////////////////////////////////////////////////////////////////////////

module rx_tb; 
    // Parameters
    parameter integer CLK_FREQUENCY = 100_000_000; 
    parameter integer BAUD_RATE = 19_200;          // Default baud rate 
    parameter integer PARITY = 1;                   // Default parity (1=odd) 
    parameter integer NUMBER_OF_CHARS = 10;         // Number of characters to transmit 

    // Testbench Parameters 
    localparam integer NUM_CYCLES_BEFORE_START = 10; // Cycles before starting test
    localparam integer NUM_CYCLES_RESET = 5;          // Cycles for reset

    // Clock and Reset logic 
    logic clk;                                      
    logic rst;                                       

    // UART Connections 
    logic [7:0] tx_data;                            // Data to transmit 
    logic tx_start;                                  // Start transmission signal 
    logic tx_busy;                                   // Transmitter busy signal 
    logic din;                                       // Transmitter output connected to Receiver input 
    logic [7:0] rx_data;                            // Received data 
    logic rx_busy, rx_data_strobe, rx_error;       // Receiver signals 

    // Instantiate the UART Transmitter 
    tx #(
        .CLK_FREQUENCY(CLK_FREQUENCY), 
        .BAUD_RATE(BAUD_RATE), 
        .PARITY(PARITY) 
    ) transmitter (
        .clk(clk), 
        .rst(rst), 
        .send(tx_start), 
        .din(tx_data), 
        .busy(tx_busy), 
        .tx_out(din) // Connect transmitter output to receiver input 
    ); 

    // Instantiate the UART Receiver 
    rx #(
        .CLK_FREQUENCY(CLK_FREQUENCY), 
        .BAUD_RATE(BAUD_RATE), 
        .PARITY(PARITY) 
    ) receiver (
        .clk(clk), 
        .rst(rst), 
        .din(din), 
        .dout(rx_data), 
        .busy(rx_busy), 
        .data_strobe(rx_data_strobe), 
        .rx_error(rx_error) 
    ); 

    // Clock generation 
    always begin 
        clk = 1; #5; 
        clk = 0; #5; 
    end 

    // Task to send and verify data 
    task automatic send_and_verify(input logic [7:0] value_to_send); 
        begin 
            tx_data = value_to_send; 
            tx_start = 1; 
            @(posedge clk); 
            tx_start = 0; 
            wait(tx_busy); // Wait for transmission to start 
            wait(!tx_busy); // Wait for transmission to end 

            // Check received data against sent data
            if (rx_data == value_to_send && !rx_error) 
                $display("Time [%0tns]: Transmit OK - Value %h", $time/1000.0, value_to_send); 
            else 
                $display("Time [%0tns]: ERROR - Received Value %h, Expected %h, rx_error=%b", 
                    $time/1000.0, rx_data, value_to_send, rx_error); 
        end 
    endtask 

    // Initial block 
    initial begin 
        $display("Starting UART RX Testbench"); 

        // Initialize 
        clk = 0; 
        rst = 1; // Assert reset 
        tx_start = 0; 
        tx_data = 8'hXX; // Dummy value

        repeat(NUM_CYCLES_BEFORE_START) @(posedge clk); 
        rst = 0; // Deassert reset 
        repeat(NUM_CYCLES_RESET) @(posedge clk); 

        // Main test sequence 
        $display("Starting test sequence"); 

        for (int i = 0; i < NUMBER_OF_CHARS; i++) begin 
            send_and_verify($random % 256); // Send a random 8-bit value 
            repeat($urandom_range(1, 10)) @(posedge clk); // Random delay 
        end 

        // End the simulation 
        $display("Test sequence complete. Stopping simulation."); 
        $stop; 
    end 
endmodule
