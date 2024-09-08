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

    param CLK_FREQUENCY = 100000000;
    param BAUD_DATE = 19200;
    param PARITY = 1;
    
    // Button synchronizer
    always_ff@(posedge clk)
    begin
        if (!tx)
            rst <= 1;
        else
            rst <= 0;
    end

    always_ff@(posedge clk)
    begin
        if (send) begin
            busy <= 1;
            rst <= 1;
        end
        else
            busy <= 0;
    end
    

    // Transmitter
    tx tx_inst(
        .clk    (clk),
        .Reset  (reset),
        .Send   (send_character),
        .Din    (sw),
        .Sent   (),
        .Sout   (tx_out)
    );

    // Seven-Segment Display
    SevenSegmentControl SSC (
        .clk(clk),
        .reset(reset),
        .dataIn({8'h00, sw}),
        .digitDisplay(4'h3),
        .digitPoint(4'h0),
        .anode(anode),
        .segment(segment)
    );

endmodule