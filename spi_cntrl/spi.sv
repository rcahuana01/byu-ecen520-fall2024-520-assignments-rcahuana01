`timescale 1ns / 1ps
/***************************************************************************
*
* Module: spi.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520
* Date: 9/20/2024
* Description: SPI Design
*
****************************************************************************/
module spi(
    input wire logic clk,     // Clock
    input wire logic rst,    // Reset
    input wire logic start,      //start a transfer
    input wire logic  [7:0] data_to_send,   //data to send to subunit
    input wire logic hold_cs,               //hold CS signal for multi-byte transfers
    input wire logic SPI_MISO,              //SPI MISO signal
    output logic [7:0] data_received,         // Data received on the last transfer
    output logic busy,      // Contoller is busy
    output logic done,  //Indicates that a new data value has been received
    output logic SPI_SCLK,
    output logic SPI_MISO,
    output logic SPI_CS          // Indicates that there was an error when receiving
);

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;  // Sample frequency
    parameter SCLK_FREQUENCY = 500_000;           // Number of signals changed per second
    
    // Internal signals
    logic halftimerDone, incorrectParity, checkMiddle, stopBit, stopBit, startBit, checkMiddle; 
    logic [7:0] temp_dout;
    logic [31:0] timer;
    typedef enum logic [2:0] {IDLE, LOAD_DATA, TRANSMIT, CHECK_HOLD, FINISH} state_t;
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
    
    // State machine
    always_comb begin
         ns = cs;
        clrTimer = 1'b0;
        incBit = 1'b0;
        clrBit = 1'b0;
        data_strobe = 1'b0;
        rx_error = 1'b0;
        busy = 1'b1;
        calculateParity = 1'b0;
        stopBit = 1'b0;
        if (rst)
            ns = IDLE;
        else begin
            case (cs)
                IDLE: begin
                    if (start) begin
                        ns = LOW;
                end
                LOAD_DATA: begin
                   data << data_to_send;
                   ns = HIGH;
                   cs = 0;
                end
                TRANSMIT: begin
                    if (timerDone) begin
                        clrBit = 1;
                        ns = DATA;
                end
                REPEAT: begin
                    data_strobe = 1;
                    if (timerDone)
                        if (bitDone)
                            ns = END
                        else 
                            incBit = 1;
                end
                CHECK_HOLD: begin
                    if (hold_cs) 
                        ns = LOAD_DATA;
                    else if(hold_cs)
                        ns = FINISH;
                end
                FINISH: begin
                    cs = 1;
                    done = 1;
                    ns = IDLE;
                end
            endcase
        end
    end

     


endmodule
