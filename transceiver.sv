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
    input wire logic rst,      
    input wire logic send,
    input wire logic [7:0] din,
    output logic busy,
    output logic tx_out
);

    localparam CLK_FREQUENCY = 100_000_000;
    localparam BAUD_RATE = 19_200;
    localparam BAUD_PERIOD = CLK_FREQUENCY / BAUD_RATE;


    // Define states
    typedef enum logic[2:0] { IDLE, SEND, WAIT, DONE } StateType;
    StateType ns, cs;

    // Internal signals
    logic clrTimer, incTimer, timer[15:0], bitCount[5:0], incBit, clrBit, data[10:0], parityBit;

    // Bit timer
     always_ff @(posedge clk) begin
        if (rst || clrTimer)
            timer <= 0;
        else 
            timer <= timer + 1;
     end

    // Bit counter
    always_ff @(posedge clk) begin
       if (rst || clrBit)
            bitCount <= 0;
        else if (incBit)
            bitCount <= bitCount + 1;
    end 

    
    // Data initialization
    always_ff @(posedge clk) begin 
        if (rst) 
            data <= 11'b1;
        else 
            data[10] <= 1'b0;
            data[9:2] <= din;
            data[1] <= parityBit;
            data[0] <= 1'b1; //Stop bit
    end

    // State transition
    always_comb begin     
        // Assign default values
        ns = cs;
        clrTimer = 1'b0;
        incBit = 1'b0;
        clrBit = 1'b0;
        incTimer = 1'b0;
        parityBit = 1'b0;
        // State transitions and control   
        case (cs)
            IDLE: begin
                if (send) begin
                ns = SEND;
                busy = 1'b1;
                incTimer = 1'b1;
                incBit = 1'b1;
                end
            end
            SEND: begin
                if (timer == BAUD_PERIOD-1) begin
                    incBit = 1'b1;
                    if (incBit == 10)
                    ns = WAIT;
                end
            end
            WAIT: begin
                if (timer == BAUD_PERIOD-1) 
                    clrTimer = 1'b0;
                    ns = DONE;   
            end
            DONE: begin
               
            end
        endcase
        end

    // State register
    always_ff @(posedge clk)
        cs <= ns;

    // Parity bit calculation
    assign parityBit = (PARITY == 1) ? ~(^din) : ^din;

    // Output assignment
    always_comb begin
        case (cs)
            START: tx_out = 1'b0;  // Start bit
            SEND: tx_out = dataBit; // Data bits
            WAIT: tx_out = parityBit; // Parity bit
            DONE: tx_out = 1'b1;   // Stop bit
            default: tx_out = 1'b1; // Default to stop bit
        endcase
    end

endmodule
