module tb_spi_controller();

    // Parameters
    localparam CLK_FREQUENCY = 100_000_000;  // Clock frequency (100 MHz)
    localparam SCLK_FREQUENCY = 500_000;      // SCLK frequency (500 kHz)

    // Inputs and outputs
    reg clk;
    reg rst;
    reg start;
    reg hold_cs;
    reg [7:0] data_to_send;
    wire [7:0] data_received;
    wire busy;
    wire done;
    wire SPI_SCLK;
    wire SPI_MOSI;
    wire SPI_CS;
    reg SPI_MISO;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
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

        // Reset sequence
        #20 rst = 0; // Release reset after a few clock cycles

        // Perform single-byte transfers
        repeat(10) begin
            send_byte($random);  // Send random 8-bit values
            #20;
        end

        // Perform multi-byte transfers
        repeat(5) begin
            send_multi_byte($random, $random, $random);  // Send 3 random bytes
            #40;
        end

        // End simulation
        #100;
        $stop;
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
