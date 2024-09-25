`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  
//  Module name: rx.sv
//  Name: Rodrigo Cahuana
//  Class: ECEN 520
//  Date: 09/24/2024
//  Description: UART Receiver top-level design
//
//////////////////////////////////////////////////////////////////////////////////

module rx (
    input wire logic clk,           // Clock input
    input wire logic rst,           // Reset input
    input wire logic din,           // RX input signal
    output logic [7:0] dout,        // Received data values
    output logic busy,              // Indicates that the receiver is busy
    output logic data_strobe,       // Indicates that new data has been received
    output logic rx_error           // Indicates that there was an error when receiving
);

    // Parameters
    parameter integer CLK_FREQUENCY = 100_000_000;  // Clock frequency
    parameter integer BAUD_RATE = 19_200;            // Baud rate
    parameter integer PARITY = 1;                     // 0 = even, 1 = odd

    localparam integer BAUD_PERIOD = CLK_FREQUENCY / BAUD_RATE; // Baud period
    localparam integer TIMER_RANGE = 15;               // Timer range
    localparam integer BIT_RANGE = 3;                 // Bit range for counter
    localparam integer DATA_BITS = 8;                  // Number of data bits

    // State definitions
    typedef enum logic[2:0] {IDLE, START, DATA, PAR, STOP} state_t;
    state_t cs, ns;                         

    // Internal signals
    logic [BIT_RANGE:0] bitNum;                  
    logic [TIMER_RANGE:0] timer;                  
    logic timer_done, half_timer_done;              
    logic clrBit, incBit, parity_bit;              

    // Assign busy state
    assign busy = (cs != IDLE);
    
    // Timer Logic
    assign timer_done = (timer >= BAUD_PERIOD);
    assign half_timer_done = (timer >= (BAUD_PERIOD / 2)); 

    // Timer logic block
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            timer <= 0;                           
        end else begin
            if (timer_done) 
                timer <= 0;                        
            else
                timer <= timer + 1;                
        end
    end

    // Bit Counter Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bitNum <= 0;                              
        end else begin
            if (clrBit)
                bitNum <= 0;                          
            else if (incBit)
                bitNum <= bitNum + 1;                 
        end
    end

    // State Machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cs <= IDLE;                            
        end else begin
            cs <= ns;                              
        end
    end

    // State Transition Logic
    always_comb begin
        ns = cs;                                     
        dout = dout;                             
        data_strobe = 0;                            
        rx_error = 0;                           
        clrBit = 0;                             
        incBit = 0;                             

        case (cs)
            IDLE: begin
                // Check for start bit
                if (din == 0) begin                    
                    ns = START;
                end
            end
            START: begin
                // Wait for half of the baud period to ensure we are in the middle of the start bit
                if (half_timer_done) begin
                    ns = DATA;                         
                    clrBit = 1;                      
                end
            end
            DATA: begin
                // Sample input at the middle of the bit period
                if (timer_done) begin
                    dout = {din, dout[7:1]};         
                    incBit = 1;                     
                    if (bitNum == DATA_BITS) begin
                        ns = PAR;                     
                    end
                end
            end
            PAR: begin
                // Check for parity
                if (timer_done) begin
                    parity_bit = ^dout;                
                    if (din != (PARITY ? ~parity_bit : parity_bit)) begin
                        rx_error = 1;                  
                    end
                    ns = STOP;                          
                end
            end
            STOP: begin
                // Check for stop bit
                if (timer_done) begin
                    if (din != 1) begin
                        rx_error = 1;               
                    end
                    data_strobe = 1;           
                    ns = IDLE;                      
                end
            end
            default: begin
                ns = IDLE;                           
            end
        endcase
    end

endmodule
