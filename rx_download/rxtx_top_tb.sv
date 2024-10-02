`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// RX/TX top-level testbench
//////////////////////////////////////////////////////////////////////////////////

module rxtx_top_tb ();

    logic clk, rst_n, rst, btnc, btnc_bouncy;
    logic [7:0] sw, sw_d, sw_dd;
    logic [15:0] led;
    logic UART_RXD_OUT; // Transmitter output
    logic UART_TXD_IN; // Receiver input (connected to UART_RXD_OUT)
    logic LED16_B; // TX busy signal
    logic LED17_R; // RX busy signal
    logic LED17_G; // RX error signal
    logic [7:0] AN; // Seven segment display anodes
    logic [6:0] CA, CB, CC, CD, CE, CF, CG; // Seven segment display cathodes
    logic DP;

    parameter integer DEBOUNCE_TIME_US = 100;
    parameter integer BAUD_RATE = 19_200;
    parameter integer MIN_SEGMENT_DISPLAY_US = 200; // Default for testbench
    parameter logic PARITY = 1'd1;
    parameter integer NUMBER_OF_CHARS = 8;

    localparam integer CLK_FREQUENCY = 100_000_000;
    localparam integer BOUNCE_CLOCKS = CLK_FREQUENCY / 1_000_000 * DEBOUNCE_TIME_US;

    // Clock Generator
    always begin
        clk <= 1; #5ns;
        clk <= 0; #5ns;
    end

    // Reset
    assign rst = ~rst_n;

    // Debounce simulation generator
    gen_bounce #(.BOUNCE_CLOCKS_LOW_RANGE(2), .BOUNCE_CLOCKS_HIGH_RANGE(20))
    bounce_btnc (
        .clk(clk),
        .sig_in(btnc),
        .bounce_out(btnc_bouncy)
    );

    // Instantiate Top-level design
    rxtx_top #(.DEBOUNCE_TIME_US(DEBOUNCE_TIME_US), .PARITY(PARITY), .BAUD_RATE(BAUD_RATE), .MIN_SEGMENT_DISPLAY_US(MIN_SEGMENT_DISPLAY_US))
    uut (
        .CLK100MHZ(clk),
        .CPU_RESETN(rst_n),
        .SW(sw),
        .BTNC(btnc_bouncy),
        .LED(led),
        .UART_RXD_OUT(UART_RXD_OUT),
        .UART_TXD_IN(UART_RXD_OUT), // Connect TX to RX for testing
        .LED16_B(LED16_B),
        .LED17_R(LED17_R),
        .LED17_G(LED17_G),
        .AN(AN),
        .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG),
        .DP(DP)
    );

    // Task for initiating a tx transfer
    task automatic initiate_tx(input [7:0] char_value);
        // Set switches
        sw = char_value;
        repeat(100)
            @(negedge clk);

        // Press the button and wait enough clocks to get it to go through the debouncer
        $display("[%0tns] Pressing BTNC to transmit 0x%h", $time / 1000.0, char_value);
        btnc = 1;
        repeat(BOUNCE_CLOCKS * 1.1)
            @(negedge clk);
        // Wait until busy goes high
        wait (LED16_B == 1'b1);
        $display("[%0tns] Transmission started", $time / 1000.0);

        // Release the button
        btnc = 0;
        repeat(BOUNCE_CLOCKS * 1.2)
            @(negedge clk);
        // Wait until busy goes low
        wait (LED16_B == 1'b0);
    endtask

    //////////////////////////////////
    // Main Test Bench Process
    //////////////////////////////////
    initial begin
        $display("===== RX/TX Top TB =====");
        $display("BAUD_RATE=%d PARITY=%d DEBOUNCE_TIME_US %d BOUNCE_CLOCKS %d",
            BAUD_RATE, PARITY, DEBOUNCE_TIME_US, BOUNCE_CLOCKS);

        // Simulate some time with no stimulus/reset while clock is running
        #100ns;

        // Set some defaults and run some more
        rst_n = 1;
        btnc = 0;
        sw = 8'h00;
        #100ns;

        // Issue the reset
        $display("[%0tns] Reset", $time / 1000.0);
        @(negedge clk);
        rst_n = 0;
        repeat (5) @(negedge clk);
        rst_n = 1;

        // Change the switches a bit to make sure the LEDs follow
        for (int i = 0; i < 10; i++) begin
            @(negedge clk);
            sw = $urandom_range(0, 255);
            repeat(100) @(negedge clk);
        end
        sw = 8'h00;

        // Send a short signal that doesn't make it through the debouncer
        $display("[%0tns] Sending some short bounces. Should not transmit", $time / 1000.0);
        @(negedge clk);
        btnc = 1;
        repeat(BOUNCE_CLOCKS / 2) @(negedge clk);
        btnc = 0;
        repeat(10) @(negedge clk);

        // Transmit a few characters to design
        for (int i = 0; i < NUMBER_OF_CHARS; i++) begin
            initiate_tx($urandom_range(0, 255));
            repeat(10000) @(negedge clk);
        end

        $stop;
    end

    // Check that the LEDs follow the switches
    always_ff @(posedge clk) begin
        sw_d <= sw;
        sw_dd <= sw_d;
        if ((sw_d == sw) && (sw_dd == sw)) begin
            if (led[7:0] != sw)
                $display("[%0tns] ERROR: LEDs do not follow switches LED=%h != SW=%h", $time / 1000, led[7:0], sw);
        end
    end

endmodule
