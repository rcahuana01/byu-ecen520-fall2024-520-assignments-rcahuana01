`timescale 1ns / 1ps
/***************************************************************************
*
* Module: top_spi_adxl362.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520, Section 01, Fall 2024
* Date: 10/15/2024
* Description: Top-level design for the ADXL362 SPI controller and display
*
****************************************************************************/
module top_spi_adxl362 #(
    parameter CLK_FREQUENCY = 100_000_000,    // System clock frequency (in Hz)
    parameter SEGMENT_DISPLAY_US = 1_000,     // Time to display each digit (in microseconds)
    parameter DEBOUNCE_TIME_US = 1_000,       // Debounce time for buttons (in microseconds)
    parameter SCLK_FREQUENCY = 1_000_000,     // SPI clock frequency (in Hz)
    parameter DISPLAY_RATE = 2                // Times per second to update display
)(
    input wire CLK100MHZ,               // System clock
    input wire CPU_RESETN,              // Reset signal (active low)
    input wire [15:0] SW,               // 16 switches
    input wire BTNL,                    // Left button (write trigger)
    input wire BTNR,                    // Right button (read trigger)
    output wire [15:0] LED,             // 16 LEDs
    output wire LED16_B,                // Blue LED (SPI busy)
    input wire ACL_MISO,                // ADXL362 SPI MISO
    output wire ACL_SCLK,               // ADXL362 SPI SCLK
    output wire ACL_CSN,                // ADXL362 SPI CSN
    output wire ACL_MOSI,               // ADXL362 SPI MOSI
    output wire [7:0] AN,               // Seven-segment display anodes
    output wire CA, CB, CC, CD, CE, CF, CG,  // Seven-segment display cathodes
    output wire DP                      // Seven-segment display decimal point
);

    logic clk = CLK100MHZ;
    logic rst = ~CPU_RESETN;  // Active high reset

    // LEDs mirror switches
    assign LED = SW;

    // Signals for adxl362_controller
    logic adxl_busy, adxl_done;
    logic [7:0] adxl_data_received;

    // Manual read/write operation signals
    logic start_transfer, write_transfer;
    logic [7:0] data_to_send, address;

    // For display of X, Y, Z data
    logic [7:0] x_axis_data, y_axis_data, z_axis_data;
    
    // State Machine
    typedef enum logic [2:0] {
        IDLE,
        READ_X_AXIS,
        WAIT_FOR_X_DATA,
        READ_Y_AXIS,
        WAIT_FOR_Y_DATA,
        READ_Z_AXIS,
        WAIT_FOR_Z_DATA
    } state_t;
    state_t auto_read_state;

    // For Seven-Segment Display
    logic [31:0] display_val;
    logic [7:0] dp;

    // Debounce buttons
    debounce #(.DEBOUNCE_CLKS((CLK_FREQUENCY / 1_000_000) * DEBOUNCE_TIME_US)) debounce_btnl (
        .clk(clk),
        .rst(rst),
        .async_in(BTNL),
        .debounce_out(btnl_debounced)
    );

    debounce #(.DEBOUNCE_CLKS((CLK_FREQUENCY / 1_000_000) * DEBOUNCE_TIME_US)) debounce_btnr (
        .clk(clk),
        .rst(rst),
        .async_in(BTNR),
        .debounce_out(btnr_debounced)
    );

    // State machine for auto-read of X, Y, Z axis
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset signals
            start_transfer <= 0;
            write_transfer <= 0;
            x_axis_data <= 8'd0;
            y_axis_data <= 8'd0;
            z_axis_data <= 8'd0;
            auto_read_state <= IDLE;
        end else begin
            // Automatic read process
            case (auto_read_state)
                IDLE: begin
                    auto_read_state <= READ_X_AXIS;
                end
                READ_X_AXIS: begin
                    start_transfer <= 1;
                    write_transfer <= 0;
                    address <= 8'h08;  // X-axis register
                    auto_read_state <= WAIT_FOR_X_DATA;
                end
                WAIT_FOR_X_DATA: begin
                    if (adxl_done) begin
                        x_axis_data <= adxl_data_received;
                        auto_read_state <= READ_Y_AXIS;
                    end
                end
                READ_Y_AXIS: begin
                    start_transfer <= 1;
                    write_transfer <= 0;
                    address <= 8'h09;  // Y-axis register
                    auto_read_state <= WAIT_FOR_Y_DATA;
                end
                WAIT_FOR_Y_DATA: begin
                    if (adxl_done) begin
                        y_axis_data <= adxl_data_received;
                        auto_read_state <= READ_Z_AXIS;
                    end
                end
                READ_Z_AXIS: begin
                    start_transfer <= 1;
                    write_transfer <= 0;
                    address <= 8'h0A;  // Z-axis register
                    auto_read_state <= WAIT_FOR_Z_DATA;
                end
                WAIT_FOR_Z_DATA: begin
                    if (adxl_done) begin
                        z_axis_data <= adxl_data_received;
                        auto_read_state <= IDLE;
                    end
                end
                default: auto_read_state <= IDLE;
            endcase
        end
    end

    // SPI controller instantiation
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

    // LED indicator for SPI busy
    assign LED16_B = adxl_busy;

    // Seven-segment display instantiation
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

    // Display X, Y, Z on the seven-segment display
    always @(*) begin
        display_val = {z_axis_data, y_axis_data, x_axis_data};
        dp = 8'd0;
    end

endmodule
