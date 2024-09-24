`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// RX testbench
//////////////////////////////////////////////////////////////////////////////////

module rx_tb ();
    // Parameters
    parameter NUMBER_OF_CHARS = 10;
    parameter BAUD_RATE = 19_200;
    parameter CLOCK_PERIOD = 100_000_000;
    parameter CLOCK_PERIOD = 10;

    // Internal signals
    logic clk, rst, tb_send, tx_busy;
    logic [7:0] tb_din;
    logic [7:0] char_to_send = 0;
    logic [7:0] rx_data;
    logic odd_parity_calc = 0;
    logic rx_busy, data_strobe;

    //////////////////////////////////////////////////////////////////////////////////
    // Instantiate Desgin Under Test (DUT)
    //////////////////////////////////////////////////////////////////////////////////

    tx tx(
        .clk(clk),
        .rst(rst),
        .send(tb_send),
        .din(tb_din),
        .tx_out(tb_tx_out),
        .busy(tx_busy)
    );

    //////////////////////////////////////////////////////////////////////////////////
    // Instantiate RX simulation model
    //////////////////////////////////////////////////////////////////////////////////

    rx rx(
        .clk(clk),
        .rst(rst),
        .din(tb_tx_out),
        .dout(rx_data)
        .busy(rx_busy),
        .data_strobe(),
        .rx_error()
    );

    //////////////////////////////////////////////////////////////////////////////////
    // Clock Generator
    //////////////////////////////////////////////////////////////////////////////////
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end

    // Task for initiating a transfer
    task initiate_tx( input [7:0] char_value );

        // Initiate transfer on negative clock edge
        @(negedge clk)
        $display("[%0tns] Transmitting 0x%h", $time/1000.0, char_to_send);

        // set inputs
        tb_send = 1;
        tb_din = char_value;

        // Wait a clock
        @(negedge clk)

        // Wait until busy goes high or reset is asserted
        wait (tx_busy == 1'b1 || rst == 1'b1);

        // Deassert send
        @(negedge clk)
        tb_send = 0;
    endtask   

    //////////////////////////////////
    // Main Test Bench Process
    //////////////////////////////////
    initial begin
        int clocks_to_delay;
        $display("===== TX TB =====");

        // Simulate some time with no stimulus/reset
        #100ns

        // Set some defaults
        rst = 0;
        tb_send = 0;
        tb_din = 8'hff;
        #100ns

        //Test Reset
        $display("[%0tns] Testing Reset", $time/1000.0);
        rst = 1;
        #80ns;
        // Un reset on negative edge
        @(negedge clk)
        rst = 0;

        // Make sure tx is high
        @(negedge clk)
        if (tb_tx_out != 1'b1)
            $display("[%0tns] Warning: TX out not high after reset", $time/1000.0);

        //////////////////////////////////
        // Transmit a few characters to design
        //////////////////////////////////
        #10us;
        for(int i = 0; i < NUMBER_OF_CHARS; i++) begin
            char_to_send = $urandom_range(0,255);
            initiate_tx(char_to_send);
            // Wait until transmission is over
            wait (rx_busy == 1'b0);
            // check to see that character received is the one that was sent
            if (tx_data != char_to_send)
                $display("\[%0tns] WARNING: Received 0x%h instead of 0x%h", $time/1000,rx_data,char_to_send);

            // Delay a random amount of time
            clocks_to_delay = $urandom_range(1000,30000);
            repeat(clocks_to_delay)
                @(negedge clk);
        end

        // Issue a reset in the middle of a transmission
        initiate_tx(8'ha5);
        // Wait 4 baud periods
        repeat(BAUD_CLOCKS * 4)
            @(negedge clk);
        // Issue reset
        $display("[%0tns] Testing reset of TX in middle of transaction", $time/1000.0);
        rst = 1;
        #20ns;
        // Un reset on negative edge
        @(negedge clk)
        rst = 0;
        // Make sure tx is high and no longer busy
        repeat(2)
            @(negedge clk);
        if (tb_tx_out != 1'b1)
            $display("[%0tns] Warning: TX out not high after reset", $time/1000.0);
        if (tx_busy != 1'b0)
            $display("[%0tns] Warning: busy is high after reset", $time/1000.0);
        // Wait 4 baud periods
        repeat(BAUD_CLOCKS * 4)
            @(negedge clk);

        /*
        // Try to issue a new transaciton before the last one ends
        //$display("[%0tns] Testing issue of a new transaction before last one ends", $time/1000.0);
        char_to_send = 8'h5a;
        initiate_tx(char_to_send);
        // Wait 4 baud periods
        delay_baud(4);
        // Initiate a new transaction with a different value (should be ignoreds)
        initiate_tx(char_to_send >> 1);
        // Wait until transmission is over
        wait (tx_busy == 1'b0);
        // check to see that character received is the one that was sent
        if (r_char != char_to_send)
            $display("\[%0tns] WARNING: Received 0x%h instead of 0x%h", $time/1000,r_char,char_to_send);
        */

        $stop;
    end

endmodule