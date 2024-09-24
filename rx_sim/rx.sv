`timescale 1ns / 1ps
/***************************************************************************
*
* Module: rx.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520
* Date: 9/20/2024
* Description: UART Receiver Design
*
****************************************************************************/
module rx(
    input wire logic clk,     // Clock
    input wire logic rst,    // Reset
    input wire logic din,      // RX input signal
    output logic [7:0] dout,         // Received data values
    output logic busy,      // Indicates that the transmitter is in the middle of a transmit
    output logic data_strobe,  //Indicates that a new data value has been received
    output logic rx_error          // Indicates that there was an error when receiving
);

    // Parameters
    parameter integer CLK_FREQUENCY = 100_000_000;  // Sample frequency
    parameter integer BAUD_RATE = 19_200;           // Number of signals changed per second
    parameter integer PARITY = 1;                   // Parity type (0=Even, 1=Odd)
    integer BAUD_PERIOD = CLK_FREQUENCY/BAUD_RATE;  // Time between transitions in a signal or number of ticks
    // Internal signals
    logic halftimerDone, incorrectParity, checkMiddle, stopBit, stopBit, startBit, checkMiddle; 
    logic [7:0] temp_dout;
    logic [31:0] timer;

    typedef enum logic [2:0] {IDLE, START, DATA, STOP} state_t;
    state_t cs, ns;
    // Bit timer
    assign timerDone = (timer >= BAUD_PERIOD);
    assign halftimerDone = (timer >= (BAUD_PERIOD/2));
    always_ff @(posedge clk or posedge rst) begin
        if (rst || clrTimer || timerDone) 
            timer <= 0;
        else
            timer <= timer + 1;
    end

    // Bit counter
    assign bitDone = (bitNum >= DATA_BITS-1);

    always_ff @(posedge clk or posedge rst) begin
        if (rst || clrBit)
            bitNum <= 0;
        else if (incBit)
            bitNum <= bitNum + 1;
    end
    assign checkMiddle = halftimerDone ? 1 : 0;
    assign incorrectParity = calculateParity ? ~^dout : ^dout; 
    assign parityBit = incorrectParity ? 1 : 0;
    
    // State machine
    always_comb begin
        ns = cs;
        clrTimer = 0;
        incBit = 0;
        clrBit = 0;
        data_strobe = 0;
        rx_error = 0;
        busy = 1;
        calculateParity = 0;
        stopBit = 0;
        if (rst)
            ns = IDLE;
        else begin
            case (cs)
                IDLE: begin
                    if (din) begin
                        ns = START;
                        clrTimer = 1'b1;
                    end
                end
                START: begin
                    if (halftimerDone) begin
                        ns = PAR;
                        calculateParity = 1;
                    end
                end
                  ns = DATA;
                end
                DATA: begin
                    data_strobe = 1;
                    if (timerDone) begin
                        if (bitDone)
                            ns = STOP;
                        else 
                            incBit = 1;
                    end
                end
                STOP: begin
                    if (timerDone) 
                        ns = IDLE;
                end
            endcase
        end
    end

    // State register
    always_ff @(posedge clk or posedge rst) 
        cs <= rst ? IDLE : ns;
    assign incorrectParity = calculateParity ? 1 : 0;

    always_ff@(posedge clk)
        if (startBit)
            din <= {din[7:0],0};
        else if (stopBit)
            din <= 0;

    always_comb begin
        if (checkMiddle || incorrectParity || !stopBit)
            rx_error = 1;
    end
     


endmodule
