`timescale 1ns / 1ps

module rx(
    input wire logic clk,           // Clock
    input wire logic rst,           // Reset
    input wire logic din,           // RX input signal
    output logic [7:0] dout,        // Received data values
    output logic busy,              // Indicates that the receiver is busy
    output logic data_strobe,       // Indicates that new data has been received
    output logic rx_error           // Indicates that there was an error when receiving
);

    // Parameters
    parameter integer CLK_FREQUENCY = 100_000_000; // Sample frequency
    parameter integer BAUD_RATE = 19_200;          // Baud rate
    parameter integer DATA_BITS = 8;                // Number of data bits
    parameter integer PARITY = 1; // Make it a parameter instead of localparam

    localparam integer BAUD_PERIOD = CLK_FREQUENCY / BAUD_RATE; // Baud period in clock cycles
    
    // Internal signals
    logic [7:0] r_char;
    logic [3:0] bit_counter;
    logic [31:0] timer;
    logic sampling_done;
    logic start_bit_detected;
    logic parity_check;
    typedef enum logic [2:0] {IDLE, START, DATA, PAR, STOP} state_t;
    state_t current_state, next_state;

    // Receive busy condition
    assign busy = (current_state != IDLE);

    // State Machine
    always_ff @(posedge clk or posedge rst)
        if (rst)
            current_state <= IDLE;
        else 
            current_state <= next_state;

    // IFL and OFL
    always_comb begin
        next_state = current_state;
        dout = 0;
        data_strobe = 0;
        rx_error = 0;
        timer = 0;
        bit_counter = 0;
        case (current_state)
            IDLE: begin
                if (din == 0) begin
                    next_state = START;
                    start_bit_detected = 1;
                end
            end
            START: begin
                if (timer >= (BAUD_PERIOD / 2)) begin
                    timer = 0;
                    next_state = DATA;
                    r_char = 0; 
                end
            end
            DATA: begin
                if (timer >= BAUD_PERIOD) begin
                    timer = 0; 
                    r_char = {din, r_char[7:1]};
                    if (bit_counter < DATA_BITS - 1) begin
                        bit_counter = bit_counter + 1; 
                    end else begin
                        next_state = PAR; 
                        bit_counter = 0; 
                    end
                end
            end
            PAR: begin
                if (timer >= BAUD_PERIOD) begin
                    timer = 0;
                    if (din != parity_check) begin
                        rx_error = 1;
                    end
                    next_state = STOP; 
                end
            end
            STOP: begin
                if (timer >= BAUD_PERIOD) begin
                    timer = 0;
                    if (din == 1) begin 
                        dout <= r_char;
                        data_strobe <= 1; 
                    end else begin
                        rx_error = 1; 
                    end
                    next_state = IDLE; 
                end
            end
        endcase
    end

    // Check parity
    assign parity_check = ^r_char ^ 1'b1; // Adjust this based on your parity logic

    // Timer logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            timer <= 0;
        end else if (current_state != IDLE) begin
            timer <= timer + 1; 
        end
    end

endmodule
