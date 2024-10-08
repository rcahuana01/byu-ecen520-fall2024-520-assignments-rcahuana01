`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ADXL362 testbench
//////////////////////////////////////////////////////////////////////////////////

module adxl362_tb ();

    logic clk, rst, tb_start, [7:0]tb_data_to_send, tb_hold_cs;
    logic tb_data_received, 
    logic [7:0] tb_din;

    parameter CLK_FREQUENCY = 100_000_000;
    parameter SCLK_FREQUENCY = 500_000;

  // Internal signals
  logic clk, rst, start, write, SPI_MISO;
  logic [7:0] data_to_send, address;
  logic SPI_SCLK, SPI_CS;
  logic [7:0] data_received;
  logic busy, done;

    //////////////////////////////////////////////////////////////////////////////////
    // Instantiate Desgin Under Test (DUT)
    //////////////////////////////////////////////////////////////////////////////////

  // Instantiate the rx module with parameter overrides
    // Instantiate the ADXL362 controller
  adxl362 #(
    .CLK_FREQUENCY(CLK_FREQUENCY),
    .SCLK_FREQUENCY(SCLK_FREQUENCY)
  ) uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .write(write),
    .data_to_send(data_to_send),
    .address(address),
    .SPI_MISO(SPI_MISO),
    .busy(busy),
    .done(done),
    .SPI_SCLK(SPI_SCLK),
    .SPI_CS(SPI_CS),
    .data_received(data_received)
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
        $display("===== ADXL362 TB =====");

        // Simulate some time with no stimulus/reset
        #100ns

        // Initialize signals
        rst = 1'b1;
        start = 1'b0;
        write = 1'b0;
        data_to_send = 8'b0;
        address = 8'b0;
        #100ns;

        //Test Reset
        $display("[%0tns] Testing Reset", $time/1000.0);
        rst = 1;
        #80ns;
        // Un reset on negative edge
        @(negedge clk)
        rst = 0;

        // Make sure tx is high
        $display("Reading DEVICEID...");
        address = 8'h00;
        start = 1'b1;
        #20ns
        start = 0;
        wait(done == 1);
        if (data_received != 8'hAD)
            $display("Error: Expected 0xAD, got %h", data_received);
        else 
            $display("Success: Read DEVICEID = %h", data_received);

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
        // Finish the simulation
        #100ns
        $finish;
    end

endmodule