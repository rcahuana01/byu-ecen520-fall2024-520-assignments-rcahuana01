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
    input wire logic CLK100MHZ,     //clk
    input wire logic CPU_RESETN,    //reset
    input wire logic [7:0] SW,      //switches(8 data bits to send)
    input wire logic BTNC,          //control signal to start a transmit operation
    output logic [7:0] LED,         //board LEDs
    output logic UART_RXD_OUT,      //transmitter output signal
    output logic LED16_B            //used for tx busy signal
    );


    //Parameters
    parameter integer CLK_FREQUENCY = 100_000_000;  //Specify the clock frequency
    parameter integer BAUD_RATE = 19_200;           //Baud rate of the design
    parameter integer PARITY = 1;                   //Parity type (0=Even, 1=Odd)
    parameter integer DEBOUNCE_TIME_US = 10_000;    //Specifies the minimum debounce delay in microseconds(10ms)


    // Internal signals
    logic btnc_debounced, debounce_out1, debounce_out2;
    logic [7:0]SW_sync;
    logic rst, rst1, rst2; //Internal synchronizar flip flop signals
    logic tx_busy, tx_out_int, one_press;

    //Reset signal 
    assign rst = ~CPU_RESETN;

    //Instance of debouncer module
    debounce #(.DEBOUNCE_CLKS((CLK_FREQUENCY * DEBOUNCE_TIME_US)/1_000_000)) debouncer (.clk(CLK100MHZ), .rst(rst2), 
    .async_in(BTNC), .debounce_out(btnc_debounced));

    // Instance of the transmitter module
    tx #(.CLK_FREQUENCY(CLK_FREQUENCY), .BAUD_RATE(BAUD_RATE), .PARITY(PARITY)) transmitter(.clk(CLK100MHZ),
     .rst(rst2), .send(one_press), .din(SW_sync), .busy(tx_busy), .tx_out(tx_out_int));

    //One shoot detector
    always_ff@(posedge CLK100MHZ) begin
        debounce_out1 <= btnc_debounced;
        debounce_out2 <= debounce_out1;
    end
    assign one_press = (debounce_out1 & ~debounce_out2);

    //Synchronizer
    always_ff@(posedge CLK100MHZ)
        SW_sync <= SW;

    // Assign the switches to the leds (Debug help)
    assign LED = SW;

    // Attach the tx_busy signal from the transmitter to the LED16_B signal
    assign LED16_B = tx_busy;

    // Global reset synchronizer
    always_ff@(posedge CLK100MHZ)begin
        rst1 <= rst;
        rst2 <= rst1;
    end  

    // Assign the transmitter signal
    assign UART_RXD_OUT = tx_out_int;
endmodule







