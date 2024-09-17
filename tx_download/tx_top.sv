`timescale 1ns / 1ps
import tx_sim/tx.sv
/***************************************************************************
*
* Module: tx_top.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520
* Date: 9/15/2024
* Description: top-level FPGA design
*
*
****************************************************************************/
module tx_top(
    input wire logic CLK100MHZ,
    input wire logic CPU_RESETN,
    input wire logic [7:0] SW,
    input wire logic BTNC,
    output logic [7:0] LED,
    output logic UART_RXD_OUT,
    output logic LED16_B
    );


    //Parameters
    parameter integer CLK_FREQUENCY = 100_000_000;
    parameter integer BAUD_RATE = 19_200;
    parameter integer PARITY = 1; // Odd parity
    parameter integer DEBOUNCE_TIME_US = 10_000;


    // Internal signals
    logic debounce;   //One shoot signal
    logic debounce_out, debounce_out1, debounce_out2;
    logic SW_sync[7:0];
    logic rst1, rst2; //Internal synchronizar flip flop signals
    logic tx_busy, tx_out_int;


    //Instance of debouncer module
    debouncer D1(.clk(CLK100MHZ), .rst(rst2), .async_in(BTNC), .debounce_out(debounce_out));

    // Instance of the transmitter module
    tx T1(.clk(CLK100MHZ), .rst(rst2), .send(one_press), .din(SW_sync), .busy(tx_busy), .tx_out(tx_out_int));

    //One shoot detector
    always_ff@(posedge clk) begin
        debounce_out1 <= debounce_out;
        debounce_out2 <= debounce_out1;
    end
    assign one_press = (debounce_out1 && debounce_out2);

    //Synchronizer
    always_ff@(posedge clk)
        SW_sync <= SW[7:0];

    // Assign the switches to the leds (Debug help)
    assign LED = SW_sync;

    // Attach the tx_busy signal from the transmitter to the LED16_B signal
    assign LED16_B = tx_busy;

    // Global reset synchronizer
    always_ff@(posedge clk)begin
        rst1 <= CPU_RESETN;
        rst2 <= rst1;
    end  

    // Assign the transmitter signal
    assign UART_RXD_OUT = tx_out_int;







