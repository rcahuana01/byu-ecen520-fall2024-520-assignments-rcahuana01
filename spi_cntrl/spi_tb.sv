module tb_spi_controller();

    // Parameters
    parameter CLK_FREQUENCY = 100_000_000;  // Clock frequency (100 MHz)
    parameter SCLK_FREQUENCY = 500_000;      // SCLK frequency (500 kHz)

    // Inputs and outputs
    logic clk;
    logic rst;
    logic start;
    logic hold_cs;
    logic [7:0] data_to_send;
    logic [7:0] data_received;
    logic busy;
    logic done;
    logic SPI_SCLK;
    logic SPI_MOSI;
    logic SPI_CS;
    logic SPI_MISO;

    // Clock generation
    always
    begin
        #5ns clk <=1;
        #5ns clk <=0;
    end

    // Instantiate the SPI controller
    spi #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .SCLK_FREQUENCY(SCLK_FREQUENCY)
    ) spi_cntrl (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_to_send(data_to_send),
        .hold_cs(hold_cs),
        .SPI_MISO(SPI_MISO),
        .data_received(data_received),
        .busy(busy),
        .done(done),
        .SPI_SCLK(SPI_SCLK),
        .SPI_MOSI(SPI_MOSI),
        .SPI_CS(SPI_CS)
    );

    // Instantiate the SPI subunit model
    spi_subunit spi_sub (
        .sclk(SPI_SCLK),
        .mosi(SPI_MOSI),
        .miso(SPI_MISO),
        .cs(SPI_CS),
        .send_value({8'h00}), // Sending a dummy value initially
        .received_value(data_received)
    );

    // Test sequence
    initial begin
        // Initialize signals
        rst = 1;
        start = 0;
        data_to_send = 8'h00;
        hold_cs = 0;

        //Test Reset
        $display("[%0t] Testing Reset", $time);
        rst = 1;
        #80ns;
        // Un reset on negative edge
        @(negedge clk)
        rst = 0;
    end

    // Task to send a single byte
    task send_byte(input [7:0] data_byte);
        begin
            wait(~busy);  // Wait until controller is not busy
            data_to_send = data_byte;
            start = 1;
            @(posedge clk);
            start = 0;
            wait(done);  // Wait for transaction to complete
            $display("Sent: 0x%02X, Received: 0x%02X", data_byte, data_received);
            if (data_received == data_byte)
                $display("Data matched!");
            else
                $display("Error: Data mismatch!");
        end
    endtask

    // Task to send multiple bytes
    task send_multi_byte(input [7:0] data_byte1, data_byte2, data_byte3);
        begin
            hold_cs = 1;  // Keep CS low for multi-byte transaction

            send_byte(data_byte1);  // Send first byte
            send_byte(data_byte2);  // Send second byte
            send_byte(data_byte3);  // Send third byte

            hold_cs = 0;  // End transaction by raising CS
        end
    endtask

endmodule
