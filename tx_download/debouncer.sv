`timescale 1ns / 1ps
/***************************************************************************
*
* Module: debouncer.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520
* Date: 9/15/2024
* Description: Debouncer state machine
*
*
****************************************************************************/


module debouncer(
    input wire logic clk,
    input wire logic rst,
    input wire logic async_in,
    output logic debounce_out
    );
    //Parameters
    parameter integer DEBOUNCE_CLKS = 1_000;

    localparam counterBits = ($clog2(DEBOUNCE_CLKS));
    //Internal signals
    logic timerDone; //Timer done
    logic clrTimer; //Clear timer
    logic async_in1, async_in2;
    logic [counterBits-1:0] counter;

    typedef enum logic[1:0] {s0,s1,s2,s3,ERR='X} StateType;
    StateType ns, cs;
   
    // Debounce counter
    always_ff@(posedge clk)
        if () 
            bitNum <= 0;
        else if (counterBits == ) 
            bitNum <= bitNum + 1;

    // Synchronizer on the input async_in
    always_ff@(posedge clk) begin
        if (rst) begin
            async_in1 <= 0;
            async_in2 <= 0;
        end
        else begin
            async_in1 <= async_in;
            async_in2 <= async_in1;
        end
    end
    assign timerDone = (counterBits < DEBOUNCE_CLKS) ? 1 : 0;

    // Debouncer state machine
    always_comb
    begin
    ns = ERR; // default
    clrTimer = 0; // default
    debounce_out = 0; //default
    //IFL and OFL logic for debounce
    if (rst)
        ns = s0;
     else
        case (cs)
        s0: begin
            clrTimer = 1'b1;
            if (!async_in2) ns = s0;
                else ns = s1;
            end  
           
        s1: begin
                if (!async_in2) ns = s0;
                else if (async_in2 && timerDone) ns = s2;
                else if (async_in2 && !timerDone) ns = s1;
                else ns = s1;
            end
               
        s2: begin
            debounce_out = 1'b1;
            clrTimer = 1'b1;
            if (async_in2) ns = s2;
                else ns = s3;
            end  
           
        s3: begin
            debounce_out = 1'b1;
            if (async_in2) ns = s2;
                else if (!async_in2 && timerDone) ns = s0;
                else if (!async_in2 && !timerDone) ns = s3;
                else ns = s3;
            end  
        endcase


    end
   
    always_ff @(posedge clk)
        cs <= ns;


endmodule