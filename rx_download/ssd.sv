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
    input wire logic clk,
    input wire logic rst,
    input wire logic [31:0] display_val,
    input wire logic [7:0] dp,         // Digit points for each segment
    input wire logic blank,            // Blank signal
    output logic [6:0] segments,       // Seven segment drivers
    output logic dp_out,               // Digit point output
    output logic [7:0] an_out          // Anode signals
);

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;
    parameter MIN_SEGMENT_DISPLAY_US = 10_000; // Time to display each digit
    localparam COUNTER_MAX = CLK_FREQUENCY * (MIN_SEGMENT_DISPLAY_US / 1000000);
    
    // State definitions
    typedef enum logic[1:0] {DISPLAY, START} state_t;
    state_t cs, ns;                         

    // Internal signals
    logic [2:0] bitNum;                     // 3 bits for 8 digits
    logic [$clog2(COUNTER_MAX)-1:0] timer; // Timer width
    logic timer_done;              
    logic clrBit, incBit;

    // Timer Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            timer <= 0;                           
        end else begin
            if (timer_done) 
                timer <= 0;                        
            else
                timer <= timer + 1;                
        end
    end

    // Timer Done Logic
    assign timer_done = (timer >= COUNTER_MAX);

    // Counter Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bitNum <= 0;                              
        end else begin
            if (clrBit)
                bitNum <= 0;                          
            else if (incBit)
                bitNum <= bitNum + 1;                 
        end
    end

    // State Machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cs <= START;                            
        end else begin
            cs <= ns;                              
        end
    end

    // State Transition Logic
    always_comb begin
        ns = cs;                                     
        clrBit = 0; 
        incBit = 0;
        
        case (cs)
            DISPLAY: begin
                if (timer_done) begin
                    ns = START;                         
                    incBit = 1; // Increment the digit index
                end
            end
            START: begin
                if (timer_done) begin
                    clrBit = 1; // Clear the bit number for next digit
                    ns = DISPLAY;
                end
            end
            default: ns = START;                               
        endcase
    end

    // Anode signals and DP output
    assign an_out = blank ? 8'hFF : ~(1 << bitNum); // Active low
    assign dp_out = dp[bitNum];

    // Function to decode digit value to segment representation
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
            4'd11: decode_digit = 7'b1100000; // B
            4'd12: decode_digit = 7'b0110001; // C
            4'd13: decode_digit = 7'b1000010; // D
            4'd14: decode_digit = 7'b0110000; // E
            4'd15: decode_digit = 7'b0111000; // F
            default: decode_digit = 7'b1111111; // Default off
        endcase
    endfunction

    // Display Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            segments <= 7'b1111111; // All segments off
        end else begin
            segments <= decode_digit(display_val[bitNum * 4 +: 4]);
        end
    end

endmodule
