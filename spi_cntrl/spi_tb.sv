module tb_spi_controller;

    // Parameters
    localparam CLK_PERIOD = 10; // Clock period in time units

    // Signal Definitions
    reg clk;
    reg reset;
    reg [7:0] data_to_send;
    wire [7:0] data_received; // This should be driven by the SPI subunit
    reg start;
    wire done; // Signal indicating transaction completion

    // Instantiate SPI Subunit
    spi_subunit spi_sub (
        .sclk(SPI_SCLK),
        .mosi(SPI_MOSI),
        .miso(SPI_MISO),
        .cs(SPI_CS),
        .send_value(data_to_send),
        .received_value(data_received),
        .new_value() // Ensure to connect all necessary ports
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk; // Toggle clock
    end

    // Reset Generation
    initial begin
        reset = 1;
        #(2 * CLK_PERIOD) reset = 0; // Release reset after some time
    end

    // Test Sequence
    initial begin
        // Wait for reset
        wait(!reset);
        
        // Test case 1: Send byte 0xA5
        data_to_send = 8'hA5;
        start = 1;
        @(posedge clk);
        start = 0;
        wait(done); // Wait for transaction to complete
        $display("Test Case 1: Sent 0xA5, Received: 0x%h", data_received);
        
        // Test case 2: Send byte 0x3C
        data_to_send = 8'h3C;
        start = 1;
        @(posedge clk);
        start = 0;
        wait(done); // Wait for transaction to complete
        $display("Test Case 2: Sent 0x3C, Received: 0x%h", data_received);
        
        // Add more test cases as needed

        // Finish simulation
        $finish;
    end

    // Monitor Signals (Optional)
    initial begin
        $monitor("Time: %0t | Sent: 0x%h | Received: 0x%h", $time, data_to_send, data_received);
    end

endmodule
