`timescale 1ns / 1ps
/***************************************************************************
*
* Module: ssd.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520
* Date: 9/27/2024
* Description: Seven Segment Display Design
*
****************************************************************************/
module ssd (
    input wire logic clk,                  // Clock signal
    input wire logic rst,                  // Reset signal
    input wire logic [31:0] display_val,   // 32-bit value to display
    input wire logic [7:0] dp,             // Decimal point control for each digit
    input wire logic blank,                // Blank display signal
    output logic [6:0] segments,           // Seven segment control output
    output logic dp_out,                   // Decimal point output
    output logic [7:0] an_out              // Anode control output for 8 digits
);

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;  // System clock frequency
    parameter MIN_SEGMENT_DISPLAY_US = 10_000; // Time to display each digit in microseconds
    localparam COUNTER_MAX = (CLK_FREQUENCY / 1_000_000) * MIN_SEGMENT_DISPLAY_US;

    // Internal signals
    logic [$clog2(COUNTER_MAX)-1:0] timer;  // Timer for digit multiplexing
    logic [2:0] bitNum;                     // Current digit index (3 bits for 8 digits)
    logic timer_done;                       // Timer completion flag

    // Bit timer
    always_ff @(posedge clk or posedge rst) begin
        if (rst) 
            timer <= 0;
        else if (timer_done)
            timer <= 0;  // Reset timer on done
        else
            timer <= timer + 1;
    end

    // Timer done signal logic
    assign timer_done = (timer >= COUNTER_MAX);

    // Logic to cycle through the 8 digits
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bitNum <= 0;
        end else if (timer_done) begin
            bitNum <= (bitNum == 7) ? 0 : bitNum + 1;
        end
    end

    // Anode control: only one digit (anode) is activated at a time
    always_ff @(posedge clk or posedge rst) begin
        if (blank) begin
            an_out <= 8'hFF;  // All anodes off when blanking
        end else begin
            an_out <= ~(1 << bitNum);  // Activate one anode at a time (active low)
        end
    end

    // Decimal point output: dp_out corresponds to the active digit
    assign dp_out = dp[bitNum];

    // Function to decode a 4-bit value into the 7-segment display pattern
    function logic [6:0] decode_digit(input logic [3:0] digit);
        case (digit)
            4'd0: decode_digit = 7'b0000001; // 0
            4'd1: decode_digit = 7'b1001111; // 1
            4'd2: decode_digit = 7'b0010010; // 2
            4'd3: decode_digit = 7'b0000110; // 3
            4'd4: decode_digit = 7'b1001100; // 4
            4'd5: decode_digit = 7'b0100100; // 5
            4'd6: decode_digit = 7'b0100000; // 6
            4'd7: decode_digit = 7'b0001111; // 7
            4'd8: decode_digit = 7'b0000000; // 8
            4'd9: decode_digit = 7'b0000100; // 9
            4'd10: decode_digit = 7'b0001000; // A
            4'd11: decode_digit = 7'b1100000; // b
            4'd12: decode_digit = 7'b0110001; // C
            4'd13: decode_digit = 7'b1000010; // d
            4'd14: decode_digit = 7'b0110000; // E
            4'd15: decode_digit = 7'b0111000; // F
            default: decode_digit = 7'b1111111; // All segments off (blank)
        endcase
    endfunction

    // Segment output logic: display the corresponding 4-bit value for each digit
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            segments <= 7'b1111111;  // Turn off all segments on reset
        end else begin
            segments <= decode_digit(display_val[bitNum * 4 +: 4]);  // Extract and decode the corresponding 4-bit value for the current digit
        end
    end
endmodule
