`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  
//  Module name: tx.sv
//  Name: Rodrigo Cahuana
//  Class: ECEN 520
//  Date: 09/07/2024
//  Description: UART Transceiver top-level design
//
//////////////////////////////////////////////////////////////////////////////////

module tx (
    input wire logic clk,              // Clock input
    input wire logic rst,              // Reset input
    input wire logic send,             // Control signal to start a transmit operation
    input wire logic [7:0] din,        // Data input (8 bits)
    output logic busy,                 // Indicates that the transmitter is busy
    output logic tx_out                // Transmitter output signal
);

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;
    parameter BAUD_RATE = 19_200;
    parameter PARITY = 1;

    localparam BAUD_PERIOD = CLK_FREQUENCY / BAUD_RATE;
    localparam DATA_RANGE = 10;
    localparam TIMER_RANGE = 15;
    localparam BIT_RANGE = 5; 
    localparam DATA_BITS = 8;

    // State definitions
    typedef enum logic[2:0] {IDLE, START, BITS, PAR, STOP } state_t;
    state_t ns, cs;

    // Internal signals
    logic clrTimer, timerDone;
    logic clrBit, incBit, bitDone;
    logic startBit, dataBit, parityBit, stopBit, bitNum; 

    logic [TIMER_RANGE:0] timer;
    logic [BIT_RANGE:0] bitCount;
    logic tx_out_int;  // Internal signal for tx_out

    // Bit timer
    assign timerDone = (timer == BAUD_PERIOD) ? 1 : 0;

    always_ff @(posedge clk) begin
        if (rst || clrTimer || timerDone)
            timer <= 0;
        else
            timer <= timer + 1;
    end

    // Bit counter
    assign bitDone = (bitNum == DATA_BITS-1) ? 1 : 0;

    always_ff @(posedge clk) begin
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
        startBit = 1'b0;
        dataBit = 1'b0;
        parityBit = 1'b0;
        stopBit = 0;

        if (rst) begin
            ns = IDLE;
        end else begin
            case (cs)
                IDLE: begin
                    if (send) 
                        ns = START;
                    clrTimer = 1'b1;
                end
                START: begin
                    if (timerDone) begin
                        ns = BITS;
                        clrBit = 1'b1;
                    end
                    startBit = 1'b1;
                end
                BITS: begin
                    if (timerDone) begin
                        if (bitDone) 
                            ns = PAR;
                        else 
                            incBit = 1'b1;
                    end
                    dataBit = 1'b1;
                end
                PAR: begin
                    if (timerDone) 
                        ns = STOP;
                    parityBit = 1'b1;
                end
                STOP: begin
                    if (timerDone) begin
                        ns = IDLE;
                        stopBit = 1;
                    end
                end
            endcase
        end
    end

    // State register
    always_ff @(posedge clk) begin
        cs <= ns;
    end
      
    // Assign busy state
    assign busy = (cs != IDLE);
    
    // Datapath
    always_ff @(posedge clk)
        if (startBit)
            tx_out_int <= 0;
        else if (dataBit)
            tx_out_int <= din[bitNum];
        else if (parityBit)
            tx_out_int <= PARITY ? ^din : ~(^din);
        else if (stopBit)
            tx_out_int <= 1;
        else
            tx_out_int <= 1;  
    
    // Output assignment
    always_ff @(posedge clk or posedge rst)
        tx_out = rst ? 1 :tx_out_int;

endmodule
