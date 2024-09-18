`timescale 1ns / 1ps
/***************************************************************************
*
* Module: debounce.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520
* Date: 9/15/2024
* Description: Debouncer state machine
*
****************************************************************************/
module debounce(
    input wire logic clk,       // Clock input for synchronization
    input wire logic rst,       // Synchronous reset (active high)
    input wire logic async_in,  // Asynchronous input signal to be debounced
    output logic debounce_out   // Debounced output signal
);

    // Parameters
    parameter integer DEBOUNCE_CLKS = 1_000; // Number of clock cycles for debounce delay

    // Calculate the number of bits required for the debounce counter
    localparam counterBits = ($clog2(DEBOUNCE_CLKS));
    
    // Internal signals
    logic timerDone; // Signal indicating when the debounce timer has completed
    logic clrTimer;  // Signal to clear the debounce counter
    logic async_in1, async_in2; // Two-stage synchronizer for the asynchronous input
    logic [(counterBits-1):0] counter; // Counter to track debounce timing

    // Define states for the state machine
    typedef enum logic[1:0] {s0, s1, s2, s3, ERR='X} StateType;
    StateType ns, cs; // Next state (ns) and current state (cs)

    // Debounce counter logic
    always_ff @(posedge clk) begin
        if (rst || clrTimer) 
            counter <= 0; // Reset the counter if reset is high or clear timer is active
        else if (counter < DEBOUNCE_CLKS-1) 
            counter <= counter + 1; // Increment counter until the debounce duration is reached
    end

    // Signal indicating that the timer has completed its count
    assign timerDone = (counter == DEBOUNCE_CLKS-1);

    // Two-stage synchronizer for async_in
    always_ff @(posedge clk) begin
        if (rst) begin
            async_in1 <= 0; // Reset first stage of synchronizer
            async_in2 <= 0; // Reset second stage of synchronizer
        end else begin
            async_in1 <= async_in; // Capture the asynchronous input in the first stage
            async_in2 <= async_in1; // Capture the first stage in the second stage
        end
    end

    // Debouncer state machine
    always_comb begin
        ns = ERR; // Default to error state
        clrTimer = 0; // Default for clear timer signal
        debounce_out = 0; // Default for debounced output signal

        // State machine logic
        if (rst) begin
            ns = s0; // Go to initial state on reset
        end else begin
            case (cs)
                s0: begin
                    // Initial state: wait for stable low signal to start debounce
                    clrTimer = 1'b1; // Clear the timer at the start
                    if (!async_in2) 
                        ns = s0; // Stay in state s0 if the input is low
                    else 
                        ns = s1; // Move to state s1 if the input goes high
                end  
                
                s1: begin
                    // Wait for the input to be stable high for the debounce period
                    if (!async_in2) 
                        ns = s0; // Return to state s0 if the input goes low
                    else if (async_in2 && timerDone) 
                        ns = s2; // Move to state s2 if the timer has completed
                    else 
                        ns = s1; // Stay in state s1 while input is high
                end

                s2: begin
                    // Debounce output goes high; wait for the input to drop low
                    debounce_out = 1'b1; // Set output high to indicate stable signal
                    clrTimer = 1'b1; // Clear timer since we are in a stable state
                    if (async_in2) 
                        ns = s2; // Stay in state s2 if still high
                    else 
                        ns = s3; // Move to state s3 if the input goes low
                end  

                s3: begin
                    // Wait for the input to be stable low after the output is set
                    debounce_out = 1'b1; // Keep output high while in state s3
                    if (async_in2) 
                        ns = s2; // Return to state s2 if the input goes high again
                    else if (!async_in2 && timerDone) 
                        ns = s0; // Return to state s0 if the input is low and timer is done
                    else 
                        ns = s3; // Stay in state s3 while the input remains low
                end  
            endcase
        end
    end
   
    // Update current state at each clock cycle
    always_ff @(posedge clk) begin
        cs <= ns; // Transition to the next state
    end

endmodule
