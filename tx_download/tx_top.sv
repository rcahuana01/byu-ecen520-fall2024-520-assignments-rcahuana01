`timescale 1ns / 1ps
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
    input wire logic SW,
    input wire logic BTNC,
    output logic LED,
    output logic UART_RXD_OUT,
    output logic LED16_B
    );


    //Parameters
    parameter CLK_FREQUENCY = 100_000_000;
    parameter BAUD_RATE = 19_200;
    parameter PARITY = 1;
    parameter DECOUNCE_TIME_US = 10_000;


    // Internal signals
    logic debounce;   //One shoot signal
    logic debounce_out, debounce_out1, debounce_out2;
    logic SW_sync[7:0];
    logic rst1, rst2; //Internal synchronizar flip flop signals
    logic tx_busy;


    //Instance of debouncer module
    debouncer D1(.clk(CLK100MHZ), .rst(rst2), .async_in(BTNC), .debounce_out(debounce_out));


    //One shoot detector
    always_ff@(posedge clk) begin
        debounce_out1 <= 0;
        debounce_out2 <= 0;
    end
    assign one_press = (debounce_out1 && debounce_out2);


    //Synchronizer
    always_ff@(posedge clk)
        SW_sync <= SW[7:0];


    // Global reset synchronizer
    always_ff@(posedge clk)begin
        rst1 <= CPU_RESETN;
        rst2 <= rst1;
    end  


    //
    assign LED = SW_sync;


    assign LED16_B = tx_busy;


    // Instance of the transmitter module
    tx T1(.clk(CLK100MHZ), .rst(rst2), .send(one_press), .din(SW_sync), .busy(tx_busy), .tx_out());





