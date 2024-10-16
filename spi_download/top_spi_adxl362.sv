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
    parameter CLK_FREQUENCY = 100_000_000,    // System clock frequency (in Hz)
    parameter SEGMENT_DISPLAY_US = 1_000,     // Time to display each digit (in microseconds)
    parameter DEBOUNCE_TIME_US = 1_000,       // Debounce time for buttons (in microseconds)
    parameter SCLK_FREQUENCY = 1_000_000,     // SPI clock frequency (in Hz)
    parameter DISPLAY_RATE = 2                // Times per second to update display
)(
    input wire CLK100MHZ,                     // System clock
    input wire CPU_RESETN,                    // Reset signal (active low)
    input wire [15:0] SW,                     // 16 switches
    input wire BTNL,                          // Left button
    input wire BTNR,                          // Right button
    output wire [15:0] LED,                   // 16 LEDs
    output wire LED16_B,                      // Blue LED
    input wire ACL_MISO,                      // Accelerometer SPI MISO
    output wire ACL_SCLK,                     // Accelerometer SPI SCLK
    output wire ACL_CSN,                      // Accelerometer SPI CSN
    output wire ACL_MOSI,                     // Accelerometer SPI MOSI
    output wire [7:0] AN,                     // Seven-segment display anodes
    output wire CA, CB, CC, CD, CE, CF, CG,   // Seven-segment display cathodes
    output wire DP                            // Seven-segment display decimal point
);
    wire clk = CLK100MHZ;
    wire rst = ~CPU_RESETN;  // Active high reset

    assign LED = SW;  // LEDs mirror switches

    // Signals for adxl362_controller
    wire adxl_busy, adxl_done;
    wire [7:0] adxl_data_received;

    // For manual read/write operations
    reg start_transfer, write_transfer;
    reg [7:0] data_to_send;
    reg [7:0] address;

    // For buttons debouncing
    wire btnl_debounced, btnr_debounced;

    // For edge detection
    reg btnl_prev, btnr_prev;
    wire btnl_pressed, btnr_pressed;

    // For display
    reg [7:0] last_data_received;
    reg [7:0] x_axis_data;
    reg [7:0] y_axis_data;
    reg [7:0] z_axis_data;

    // For FSM and timing
    reg [31:0] display_counter;
    reg [2:0] auto_read_state;
    localparam integer DISPLAY_PERIOD = CLK_FREQUENCY / DISPLAY_RATE;

    // For seven segment display
    wire [31:0] display_val;
    wire [7:0] dp;  // decimal points

    // Additional signals
    reg manual_transfer, write_transfer_d, manual_transfer_d;

    assign btnl_pressed = btnl_debounced & ~btnl_prev;
    assign btnr_pressed = btnr_debounced & ~btnr_prev;

    // Debounce buttons
    debounce #(
        .DEBOUNCE_CLKS((CLK_FREQUENCY / 1_000_000) * DEBOUNCE_TIME_US)
    ) debounce_btnl (
        .clk(clk),
        .rst(rst),
        .async_in(BTNL),
        .debounce_out(btnl_debounced)
    );

    debounce #(
        .DEBOUNCE_CLKS((CLK_FREQUENCY / 1_000_000) * DEBOUNCE_TIME_US)
    ) debounce_btnr (
        .clk(clk),
        .rst(rst),
        .async_in(BTNR),
        .debounce_out(btnr_debounced)
    );
    // assign btnr_debounced = BTNR;
    // assign btnl_debounced = BTNL;

    // Edge detection
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            btnl_prev <= 0;
            btnr_prev <= 0;
        end else begin
            btnl_prev <= btnl_debounced;
            btnr_prev <= btnr_debounced;
        end
    end

    // Main FSM
	always_ff @(posedge clk or posedge rst) begin
	    if (rst) begin
	        start_transfer <= 0;
	        write_transfer <= 0;
	        data_to_send <= 8'd0;
	        address <= 8'd0;
	        last_data_received <= 8'd0;
	        x_axis_data <= 8'd0;
	        y_axis_data <= 8'd0;
	        z_axis_data <= 8'd0;
	        display_counter <= 0;
	        auto_read_state <= 0;
	        manual_transfer <= 0;
	        write_transfer_d <= 0;
	        manual_transfer_d <= 0;
	    end else begin
	        // Update delayed signals
	        manual_transfer_d <= manual_transfer;
	        write_transfer_d <= write_transfer;

	        // Default to not start a transfer
	        start_transfer <= 0;

	        if (btnl_pressed && !adxl_busy) begin
	            // Initiate write transfer
	            start_transfer <= 1;
	            write_transfer <= 1;
	            data_to_send <= SW[15:8];
	            address <= SW[7:0];
	            manual_transfer <= 1;
	        end else if (btnr_pressed && !adxl_busy) begin
	            // Initiate read transfer
	            start_transfer <= 1;
	            write_transfer <= 0;
	            address <= SW[7:0];
	            manual_transfer <= 1;
	        end else if (!adxl_busy) begin
	            // Automatic read of X, Y, Z
	            manual_transfer <= 0;
	            case (auto_read_state)
	                0: begin
	                    if (display_counter >= DISPLAY_PERIOD) begin
	                        display_counter <= 0;
	                        auto_read_state <= 1;  // Start reading X-axis
	                    end else begin
	                        display_counter <= display_counter + 1;
	                    end
	                end
	                1: begin
	                    start_transfer <= 1;
	                    write_transfer <= 0;
	                    address <= 8'h08;  // X-axis register
	                    auto_read_state <= 2;
	                end
	                2: begin
	                    if (adxl_done) begin
	                        x_axis_data <= adxl_data_received;
	                        auto_read_state <= 3;
	                    end
	                end
	                3: begin
	                    start_transfer <= 1;
	                    write_transfer <= 0;
	                    address <= 8'h09;  // Y-axis register
	                    auto_read_state <= 4;
	                end
	                4: begin
	                    if (adxl_done) begin
	                        y_axis_data <= adxl_data_received;
	                        auto_read_state <= 5;
	                    end
	                end
	                5: begin
	                    start_transfer <= 1;
	                    write_transfer <= 0;
	                    address <= 8'h0A;  // Z-axis register
	                    auto_read_state <= 6;
	                end
	                6: begin
	                    if (adxl_done) begin
	                        z_axis_data <= adxl_data_received;
	                        auto_read_state <= 0;
	                    end
	                end
	                default: auto_read_state <= 0;
	            endcase
	        end

	        // Capture data received from manual read
	        if (adxl_done && manual_transfer_d && !write_transfer_d) begin
	            last_data_received <= adxl_data_received;
	        end
	    end
	end

    // Display value for seven segment display
    assign display_val = {
        z_axis_data[7:4], z_axis_data[3:0],
        y_axis_data[7:4], y_axis_data[3:0],
        x_axis_data[7:4], x_axis_data[3:0],
        last_data_received[3:0], last_data_received[7:4]
    };
    assign dp = 8'd1;

    // Instantiate adxl362_controller
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

    // Turn on LED16_B when adxl362_controller is busy
    assign LED16_B = adxl_busy;

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