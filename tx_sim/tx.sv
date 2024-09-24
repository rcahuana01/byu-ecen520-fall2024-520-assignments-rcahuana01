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
    localparam BIT_RANGE = 3;  
    localparam DATA_BITS = 8;

    // State definitions
    typedef enum logic[2:0] {IDLE, START, BITS, PAR, STOP } state_t;
    state_t ns, cs;

    // Internal signals
    logic clrTimer, timerDone;
    logic clrBit, incBit, bitDone;
    logic [BIT_RANGE:0] bitNum; 
    logic [TIMER_RANGE:0]timer;
    logic tx_out_int;  // Internal signal for tx_out

    // Bit timer
    assign timerDone = (timer >= BAUD_PERIOD);

    always_ff @(posedge clk or posedge rst) begin
        if (rst || clrTimer) 
            timer <= 0;
        else if (timerDone)
            timer <= 0;  // Reset timer on done
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
        tx_out_int = 1'b1;

        if (rst) begin
            ns = IDLE;
            tx_out_int = 1'b1; // Default state for idle line
        end else begin
            case (cs)
                IDLE: begin
                    if (send) 
                        ns = START;
                    clrTimer = 1'b1;
                    tx_out_int = 1'b1;
                end
                START: begin
                    if (timerDone) begin
                        ns = BITS;
                        clrBit = 1'b1;
                    end
                    tx_out_int = 1'b0;
                end
                BITS: begin
                    if (timerDone) begin
                        if (bitDone) 
                            ns = PAR;
                        else 
                            incBit = 1'b1;
                    end
                    tx_out_int = din[bitNum];
                end
                PAR: begin
                    if (timerDone) 
                        ns = STOP;
                    tx_out_int = !PARITY ? ^din : ~(^din);
                end
                STOP: begin
                    tx_out_int = 1'b1; 
                    if (timerDone)
                        ns = IDLE;
                end
            endcase
        end
    end

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            cs <= IDLE;
        else
            cs <= ns;
    end
      
    // Assign busy state
    assign busy = (cs != IDLE);
     
    // Output assignment
    always_ff @(posedge clk or posedge rst)
        tx_out <= rst ? 1'b1 : tx_out_int;

endmodule
