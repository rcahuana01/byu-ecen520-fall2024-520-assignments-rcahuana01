//////////////////////////////////////////////////////////////////////////////////
//
//  Filename: transceiver.sv
//  Name: Rodrigo Cahuana
//  Class: ECEN 520
//  Date: 09/07/2024
//  Description: UART Transceiver top-level design
//
//////////////////////////////////////////////////////////////////////////////////

module transceiver (
    input wire logic clk,
    input wire logic rst,       // Reset
    input wire logic send,
    input wire logic [7:0] din,
    output logic busy,
    output logic tx_out
);

    localparam CLK_FREQUENCY = 100_000_000;
    localparam BAUD_RATE = 19_200;
    // localparam [1:0] IDLE = 2'b00, START = 2'b01, BITS = 2'b10, PAR = 2'b11, STOP = 2'b100, ACK = 2'b101;

    // Define states
    typedef enum logic[2:0] { IDLE, SEND, WAIT, DONE } StateType;
    StateType ns, cs;

    // Internal signals
    logic send, 

    // Baud rate timer
     always_comb begin
        
     end


    // State transition and control logic
    always_comb begin
        // Assign default values
        ns = cs;
        clrTimer = 1'b0;
        incBit = 1'b0;
        clrBit = 1'b0;
        startBit = 1'b0;
        dataBit = 1'b0;
        parityBit = 1'b0;
        Sent = 1'b0;

        // State transitions and control
        if (rst)
            ns = IDLE;
        else begin
            case (cs)
                IDLE: begin
                    if (send) ns = START;
                    clrTimer = 1'b1;
                end
                SEND: begin
                    if (timerDone) begin
                        ns = BITS;
                        clrBit = 1'b1;
                    end
                    startBit = 1'b1;
                end
                WAIT: begin
                    if (timerDone) begin
                        if (bitDone) ns = PAR;
                        else incBit = 1'b1;
                    end
                    dataBit = 1'b1;
                end
                DONE: begin
                    if (~send) ns = IDLE;

                end
            endcase
        end
    end

    // Output assignment (based on state)
    always_comb begin
        case (cs)
            START: tx_out = 1'b0;  // Start bit
            SEND: tx_out = dataBit; // Data bits
            WAIT: tx_out = parityBit; // Parity bit
            DONE: tx_out = 1'b1;   // Stop bit
            default: tx_out = 1'b1; // Default to stop bit
        endcase
    end

    // Bit counter
    always_comb begin
        
    end


endmodule
