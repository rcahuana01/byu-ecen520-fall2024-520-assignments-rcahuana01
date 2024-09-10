//////////////////////////////////////////////////////////////////////////////////
//
//  Filename: transceiver.sv
//  Name: Rodrigo Cahuana
//  Class: ECEN 520
//  Date: 09/07/2024
//  Description: UART Transceiver top-level design
//
//
//////////////////////////////////////////////////////////////////////////////////

module transceiver(
    input wire logic            clk,
    input wire logic            rst, //reset
    input wire logic            send,
    input wire logic    [7:0]   din,
    output logic                busy,
    output logic                tx_out);

    parameter CLK_FREQUENCY = 100_000_000;
    parameter BAUD_RATE = 19_200;

    localparam [1:0] IDLE = 2'b00,
                     SEND = 2'b01,
                     WAIT =2'b10,
                     DONE = 2'b11;

    // State Variable
    reg [1:0] current_state, next_state;

    // State Machine Logic
    always_ff @(posedge clk)
    begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    always_comb
    begin
        case (IDLE)
            1b'1: send <= 1'b1;
            send <= din;
            
            default: send <= 1'b0;
        endcase
        case (SEND)
            1b'1: send <= 1'b1;  
            send <= din;
            
            default: send <= 1'b0; 
        endcase
        case (WAIT)
            1b'1: send <= 1'b1;  
            send <= din;
            
            default: send <= 1'b0; 
        endcase
        case (DONE)
            1b'1: send <= 1'b1;  
            send <= din;
            
            default: send <= 1'b0; 
        endcase
    end


endmodule