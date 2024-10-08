`timescale 1ns / 1ps
/***************************************************************************
*
* Module: rxtx_top.sv
* Author: Rodrigo Cahuana
* Date: 10/01/2024
* Description: Top-level design for UART transmission and reception
*
****************************************************************************/
module rxtx_top (
    input wire logic CLK100MHZ,            // Clock input
    input wire logic CPU_RESETN,           // Reset (low asserted)
    input wire logic [7:0] SW,             // Switches (8 data bits to send)
    input wire logic BTNC,                  // Control signal to start a transmit operation
    output logic [15:0] LED,               // Board LEDs (used for data and busy)
    output logic UART_RXD_OUT,             // Transmitter output signal
    input wire logic UART_TXD_IN,           // Receiver input signal
    output logic LED16_B,                   // Used for TX busy signal
    output logic LED17_R,                   // Used for RX busy signal
    output logic LED17_G,                   // Used for RX error signal
    output logic [7:0] AN,                  // Anode signals for the seven segment display
    output logic [6:0] CA, CB, CC, CD, CE, CF, CG, // Seven segment display cathode signals
    output logic DP                        // Seven segment display digit point signal
);

    // Parameters
    parameter integer CLK_FREQUENCY = 100_000_000;
    parameter integer BAUD_RATE = 19_200;
    parameter integer PARITY = 1;           // 0 = even, 1 = odd
    parameter integer MIN_SEGMENT_DISPLAY_US = 1_000; // Amount of time in microseconds to display each digit
    parameter integer DEBOUNCE_TIME_US = 1_000;

    // Internal Signals
    logic rst_sync_1, rst_sync_2;
    logic btnc_debounced;
    logic tx_busy, rx_busy, rx_error;
    logic data_strobe, SW_sync;
    logic [7:0] rx_data;
    logic [7:0] rx_registers [0:3]; // Last 4 received values
    logic tx_write, tx_out_int;

    assign rst_sync_1 = ~CPU_RESETN;

    // Synchronized Reset
    always_ff @(posedge CLK100MHZ) begin
        rst_sync_2 <= rst_sync_1;
    end  

    // Synchronizer for Switch Inputs
    always_ff @(posedge CLK100MHZ) begin
        if (rst_sync_2) 
            SW_sync <= 0;
        else 
            SW_sync <= SW;
    end

    // Debouncer Instance
    debounce #(.DEBOUNCE_CLKS((CLK_FREQUENCY / 1_000_000) * DEBOUNCE_TIME_US)) debouncer (
        .clk(CLK100MHZ), 
        .rst(rst_sync_2), 
        .async_in(BTNC), 
        .debounce_out(btnc_debounced)
    );

    // One-shot Logic for Transmitter
    one_shot tx_one_shot (
        .clk(CLK100MHZ),
        .btnc_debounced(btnc_debounced),
        .one_press(tx_write)
    );

    // Transmitter Instance
    tx #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .BAUD_RATE(BAUD_RATE),
        .PARITY(PARITY)
    ) transmitter (
        .clk(CLK100MHZ),
        .rst(rst_sync_2),
        .send(tx_write),
        .din(SW_sync),
        .busy(tx_busy),
        .tx_out(UART_RXD_OUT)
    );

    // TX Busy LED
    assign LED16_B = tx_busy;
    assign LED[7:0] = SW_sync; // Show current switch values on lower LEDs

    // Two Flip-Flop Synchronizer for RX Input
    logic rx_sync_1, rx_sync_2;
    always_ff @(posedge CLK100MHZ) begin
        rx_sync_1 <= UART_TXD_IN; 
        rx_sync_2 <= rx_sync_1;   
    end

    // Receiver Instance
    rx #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .BAUD_RATE(BAUD_RATE),
        .PARITY(PARITY)
    ) receiver (
        .clk(CLK100MHZ),
        .rst(rst_sync_2),
        .din(rx_sync_2),
        .dout(rx_data),
        .busy(rx_busy),
        .data_strobe(data_strobe),
        .rx_error(rx_error)
    );

    // RX Busy and Error LEDs
    assign LED17_R = rx_busy;
    assign LED17_G = rx_error;

    // Update Received Values and LED Output
    always_ff @(posedge CLK100MHZ) begin
        if (rst_sync_2) begin
            rx_registers[0] <= 8'h00;
            rx_registers[1] <= 8'h00;
            rx_registers[2] <= 8'h00;
            rx_registers[3] <= 8'h00;
        end else if (data_strobe) begin
            // Shift registers and store new value
            rx_registers[3] <= rx_registers[2];
            rx_registers[2] <= rx_registers[1];
            rx_registers[1] <= rx_registers[0];
            rx_registers[0] <= rx_data;
           
        end
    end
    assign  LED[15:8] = rx_data; // Show received data on upper LEDs
    // Seven Segment Display Controller
    ssd #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .MIN_SEGMENT_DISPLAY_US(MIN_SEGMENT_DISPLAY_US)
    ) display_controller (
        .clk(CLK100MHZ),
        .rst(rst_sync_2),
        .display_val({rx_registers[3], rx_registers[2], rx_registers[1], rx_registers[0]}),
        .dp(1'b0),               // Digit point
        .blank(1'b0),            // Always show display
        .segments({CA, CB, CC, CD, CE, CF, CG}),
        .dp_out(DP),
        .an_out(AN)
    );

endmodule
