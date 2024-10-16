`timescale 1ns / 1ps
/***************************************************************************
*
* Module: top_spi_adxl362.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520, Section 01, Fall 2024
* Date: 10/14/2024
* Description: SPI Top-Level Design
*
****************************************************************************/
module top_spi_adxl362 #(
    parameter CLK_FREQUENCY       = 100_000_000,    // System clock frequency (in Hz)
    parameter SEGMENT_DISPLAY_US  = 1_000,          // Time to display each digit (in microseconds)
    parameter DEBOUNCE_TIME_US    = 1_000,          // Debounce time for buttons (in microseconds)
    parameter SCLK_FREQUENCY      = 1_000_000,      // SPI clock frequency (in Hz)
    parameter DISPLAY_RATE        = 2               // Times per second to update display
)(
    input  wire        CLK100MHZ,                   // System clock
    input  wire        CPU_RESETN,                  // Reset signal (active low)
    input  wire [15:0] SW,                          // 16 switches
    input  wire        BTNL,                        // Left button
    input  wire        BTNR,                        // Right button
    output wire [15:0] LED,                         // 16 LEDs
    output wire        LED16_B,                     // Blue LED
    input  wire        ACL_MISO,                    // Accelerometer SPI MISO
    output wire        ACL_SCLK,                    // Accelerometer SPI SCLK
    output wire        ACL_CSN,                     // Accelerometer SPI CSN
    output wire        ACL_MOSI,                    // Accelerometer SPI MOSI
    output wire [7:0]  AN,                          // Seven-segment display anodes
    output wire        CA, CB, CC, CD, CE, CF, CG,  // Seven-segment display cathodes
    output wire        DP                           // Seven-segment display decimal point
);

    // Clock and reset
    wire clk = CLK100MHZ;
    wire rst = ~CPU_RESETN;  // Active high reset

    // Assign LEDs to mirror switches
    assign LED = SW;

    // Constants for accelerometer register addresses
    localparam [7:0] X_AXIS_REG = 8'h08;   // X-axis data register
    localparam [7:0] Y_AXIS_REG = 8'h09;   // Y-axis data register
    localparam [7:0] Z_AXIS_REG = 8'h0A;   // Z-axis data register

    // Constants for state machine states
    localparam [2:0]
        AUTO_STATE_IDLE    = 3'd0,
        AUTO_STATE_READ_X  = 3'd1,
        AUTO_STATE_WAIT_X  = 3'd2,
        AUTO_STATE_READ_Y  = 3'd3,
        AUTO_STATE_WAIT_Y  = 3'd4,
        AUTO_STATE_READ_Z  = 3'd5,
        AUTO_STATE_WAIT_Z  = 3'd6;

    // Calculate display period in clock cycles
    localparam integer DISPLAY_PERIOD = CLK_FREQUENCY / DISPLAY_RATE;

    // Signals for adxl362_controller
    wire adxl_busy;                  // Indicates if the SPI controller is busy
    wire adxl_done;                  // Indicates completion of SPI transfer
    wire [7:0] adxl_data_received;   // Data received from the accelerometer

    // User interface signals
    reg start_transfer;              // Start signal for SPI transfer
    reg write_transfer;              // Write signal for SPI transfer
    reg [7:0] data_to_send;          // Data to send in SPI transfer
    reg [7:0] address;               // Address for SPI transfer

    // Debounce signals for buttons
    wire btnl_debounced;             // Debounced left button
    wire btnr_debounced;             // Debounced right button

    // One-shot signals
    wire btnl_pressed;               // Left button pressed (one-shot)
    wire btnr_pressed;               // Right button pressed (one-shot)

    // Data storage for display
    reg [7:0] last_data_received;    // Last data received from manual read
    reg [7:0] x_axis_data;           // X-axis data
    reg [7:0] y_axis_data;           // Y-axis data
    reg [7:0] z_axis_data;           // Z-axis data

    // Variables for display and FSM timing
    reg [31:0] display_counter;      // Counter for display update timing
    reg [2:0] auto_read_state;       // State variable for auto-read FSM
    reg manual_read_pending;         // Indicates if a manual read is pending

    // Seven-segment display signals
    wire [31:0] display_val;         // Value to display on seven-segment
    wire [7:0] dp;                   // Decimal points for display

    /***************************************************************************
    * Module Instantiation: Debounce for BTNL (Left Button)
    * Debounces the left button input signal.
    ***************************************************************************/
    debounce #(
        .DEBOUNCE_CLKS((CLK_FREQUENCY / 1_000_000) * DEBOUNCE_TIME_US)
    ) debounce_btnl (
        .clk(clk),
        .rst(rst),
        .async_in(BTNL),
        .debounce_out(btnl_debounced)
    );

    /***************************************************************************
    * Module Instantiation: Debounce for BTNR (Right Button)
    * Debounces the right button input signal.
    ***************************************************************************/
    debounce #(
        .DEBOUNCE_CLKS((CLK_FREQUENCY / 1_000_000) * DEBOUNCE_TIME_US)
    ) debounce_btnr (
        .clk(clk),
        .rst(rst),
        .async_in(BTNR),
        .debounce_out(btnr_debounced)
    );

    /***************************************************************************
    * Module Instantiation: One-Shot for BTNL (Left Button Press)
    * Generates a one-clock-cycle pulse when a rising edge is detected.
    ***************************************************************************/
    one_shot oneshot_btnl (
        .clk(clk),
        .btnc_debounced(btnl_debounced),
        .one_press(btnl_pressed)
    );

    /***************************************************************************
    * Module Instantiation: One-Shot for BTNR (Right Button Press)
    * Generates a one-clock-cycle pulse when a rising edge is detected.
    ***************************************************************************/
    one_shot oneshot_btnr (
        .clk(clk),
        .btnc_debounced(btnr_debounced),
        .one_press(btnr_pressed)
    );

    /***************************************************************************
    * State Machine: Main FSM for SPI Communication and Data Handling
    * Handles manual read/write operations and automatic periodic reading of
    * accelerometer data (X, Y, Z axes). Manages start signals for SPI transfers
    * and updates display data.
    ***************************************************************************/
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all control and data signals
            start_transfer       <= 1'b0;
            write_transfer       <= 1'b0;
            data_to_send         <= 8'd0;
            address              <= 8'd0;
            last_data_received   <= 8'd0;
            x_axis_data          <= 8'd0;
            y_axis_data          <= 8'd0;
            z_axis_data          <= 8'd0;
            display_counter      <= 32'd0;
            auto_read_state      <= AUTO_STATE_IDLE;
            manual_read_pending  <= 1'b0;
        end else begin
            // Default to not start a transfer
            start_transfer <= 1'b0;

            if (btnl_pressed && !adxl_busy) begin
                // Initiate write transfer when left button is pressed
                data_to_send     <= SW[15:8];
                address          <= SW[7:0];
                write_transfer   <= 1'b1; // Indicate write operation
                start_transfer   <= 1'b1;
            end else if (btnr_pressed && !adxl_busy) begin
                // Initiate read transfer when right button is pressed
                address          <= SW[7:0];
                write_transfer   <= 1'b0; // Indicate read operation
                start_transfer   <= 1'b1;
                manual_read_pending <= 1'b1; // Manual read pending
            end else if (!adxl_busy) begin
                if (manual_read_pending && adxl_done) begin
                    // Manual read completed
                    last_data_received <= adxl_data_received;
                    manual_read_pending <= 1'b0;
                end else begin
                    // Automatic reading of X, Y, Z axis data
                    case (auto_read_state)
                        AUTO_STATE_IDLE: begin
                            if (display_counter >= DISPLAY_PERIOD) begin
                                display_counter <= 32'd0;
                                auto_read_state <= AUTO_STATE_READ_X;
                            end else begin
                                display_counter <= display_counter + 1;
                            end
                        end
                        AUTO_STATE_READ_X: begin
                            // Start reading X-axis data
                            address          <= X_AXIS_REG;
                            write_transfer   <= 1'b0; // Read operation
                            start_transfer   <= 1'b1;
                            auto_read_state  <= AUTO_STATE_WAIT_X;
                        end
                        AUTO_STATE_WAIT_X: begin
                            if (adxl_done) begin
                                x_axis_data    <= adxl_data_received;
                                auto_read_state <= AUTO_STATE_READ_Y;
                            end
                        end
                        AUTO_STATE_READ_Y: begin
                            // Start reading Y-axis data
                            address          <= Y_AXIS_REG;
                            write_transfer   <= 1'b0; // Read operation
                            start_transfer   <= 1'b1;
                            auto_read_state  <= AUTO_STATE_WAIT_Y;
                        end
                        AUTO_STATE_WAIT_Y: begin
                            if (adxl_done) begin
                                y_axis_data    <= adxl_data_received;
                                auto_read_state <= AUTO_STATE_READ_Z;
                            end
                        end
                        AUTO_STATE_READ_Z: begin
                            // Start reading Z-axis data
                            address          <= Z_AXIS_REG;
                            write_transfer   <= 1'b0; // Read operation
                            start_transfer   <= 1'b1;
                            auto_read_state  <= AUTO_STATE_WAIT_Z;
                        end
                        AUTO_STATE_WAIT_Z: begin
                            if (adxl_done) begin
                                z_axis_data    <= adxl_data_received;
                                auto_read_state <= AUTO_STATE_IDLE;
                            end
                        end
                        default: auto_read_state <= AUTO_STATE_IDLE;
                    endcase
                end
            end
        end
    end

    // Concatenate data for seven-segment display (each nibble represents a digit)
    assign display_val = {
        z_axis_data[7:4], z_axis_data[3:0],
        y_axis_data[7:4], y_axis_data[3:0],
        x_axis_data[7:4], x_axis_data[3:0],
        last_data_received[7:4], last_data_received[3:0]
    };

    // No decimal points used
    assign dp = 8'd0;

    /***************************************************************************
    * Module Instantiation: ADXL362 Controller
    * Manages SPI communication with the ADXL362 accelerometer.
    ***************************************************************************/
    adxl362_controller #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .SCLK_FREQUENCY(SCLK_FREQUENCY)
    ) adxl362_inst (
        .clk(clk),
        .rst(rst),
        .start(start_transfer),
        .write(write_transfer),
        .data_to_send(data_to_send),
        .address(address),
        .SPI_MISO(ACL_MISO),
        .busy(adxl_busy),
        .done(adxl_done),
        .SPI_SCLK(ACL_SCLK),
        .SPI_MOSI(ACL_MOSI),
        .SPI_CS(ACL_CSN),
        .data_received(adxl_data_received)
    );

    // Turn on LED16_B (blue LED) when ADXL362 controller is busy
    assign LED16_B = adxl_busy;

    /***************************************************************************
    * Module Instantiation: Seven-Segment Display Controller
    * Drives the seven-segment display with the accelerometer data.
    ***************************************************************************/
    ssd #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .MIN_SEGMENT_DISPLAY_US(SEGMENT_DISPLAY_US)
    ) seven_seg_inst (
        .clk(clk),
        .rst(rst),
        .display_val(display_val),
        .dp(dp),
        .blank(1'b0),
        .segments({CA, CB, CC, CD, CE, CF, CG}),
        .dp_out(DP),
        .an_out(AN)
    );

endmodule