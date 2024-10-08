`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// RX testbench
//////////////////////////////////////////////////////////////////////////////////

module spi_tb ();

    logic clk, rst, tb_start, [7:0]tb_data_to_send, tb_hold_cs;
    logic tb_data_received, 
    logic [7:0] tb_din;

    parameter CLK_FREQUENCY = 100_000_000;
    parameter SCLK_FREQUENCY = 500_000;

    localparam BAUD_CLOCKS = CLOCK_PERIOD / BAUD_RATE;

    logic [7:0] char_to_send = 0;
    logic [7:0] rx_data;
    logic odd_parity_calc = 1'b0;
    logic rx_busy;

    typedef enum { UNINIT, IDLE, BUSY } receive_state_type;
    receive_state_type r_state = UNINIT;

    //////////////////////////////////////////////////////////////////////////////////
    // Instantiate Desgin Under Test (DUT)
    //////////////////////////////////////////////////////////////////////////////////

  // Instantiate the rx module with parameter overrides
  spi #(
    .CLK_FREQUENCY(CLK_FREQUENCY),  // Set clock frequency
    .SCLK_FREQUENCY(BAUD_RATE)           // Set baud rate
  ) spi (
    .clk(clk),                   // Clock input
    .rst(rst),                   // Reset input
    .start(start),               // Start transfer
    .data_to_send(data_to_send), // Data to send
    .hold_cs(hold_cs),           // Hold chip select for multi-byte transfers
    .SPI_MISO(SPI_MISO),         // SPI MISO signal
    .data_received(data_received),// Data received from the last transfer
    .busy(busy),                 // Indicates if the controller is busy
    .done(done),                 // Transfer complete signal
    .SPI_SCLK(SPI_SCLK),         // SPI clock signal
    .SPI_MOSI(SPI_MOSI),         // SPI MOSI signal
    .SPI_CS(SPI_CS)              // SPI chip select signal
  );

    //////////////////////////////////////////////////////////////////////////////////
    // Clock Generator
    //////////////////////////////////////////////////////////////////////////////////
    always
    begin
        clk <=1; #5ns;
        clk <=0; #5ns;
    end

    // Task for initiating
    task initiate_spi( input [7:0] char_value );

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
        $display("===== SPI TB =====");

        // Simulate some time with no stimulus/reset
        #100ns

        // Set some defaults
        rst = 0;
        tb_start = 0;
        tb_hold_cs = 0;
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
        initiate_spi(8'ha5);
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