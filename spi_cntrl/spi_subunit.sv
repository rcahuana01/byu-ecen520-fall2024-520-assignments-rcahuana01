// simulation model for a generic SPI subunit.
// This model will print the value received and send a 8-bit counter value that increments each transaction.

module spi_subunit (sclk, mosi, miso, cs, send_value, received_value, new_value);

    input wire logic sclk;
    input wire logic mosi;
    output miso;
    input wire logic cs;
    output logic [7:0] received_value; // Value received from the master
    input wire logic [7:0] send_value; // Value to send to the master
    output logic new_value = 0; // indicates that a new value has been received

    int transfer_count = 1;  // Initial counter value to send out on each transaction
    int bits_received = 0;
    logic active = 0;
    logic [7:0] data_out; // shift register shifting the data out (loaded on start)

    // MISO output: High impedence if there is not a transaction going on
    assign miso = active ? data_out[7] : 1'bz;

    // Process new positive edge on sclk
    always@(posedge sclk)
    begin
        if (cs == 0) begin // Only process sclks when CS is low
            received_value <= {received_value[6:0],mosi};
            bits_received <= bits_received + 1;
        end
    end

    // Reset internal state
    always@(posedge cs) begin
        active <= 1'b0;
        new_value <= 1'b0;
    end

    // Setup transfer
    always@(negedge cs) begin
        active <= 1'b1;
        bits_received <= 0;
        data_out <= send_value;
        $display("[%0tns]  SPI subunit starting transfer of 0x%h", $time/1000,
            send_value);
    end

    always@(negedge sclk && cs == 0)
    begin
        // Shift data out (and rotate data back in)
        data_out <= {data_out[6:0],data_out[7]};
        if (bits_received == 8) begin
            $display("[%0tns]  SPI subunit received byte 0x%h (#%0d)", $time/1000,
                received_value, transfer_count);
            // Increment transfer count
            transfer_count <= transfer_count + 1;
            // Reset bits received counter
            bits_received <= 0;
            new_value <= 1'b1;
        end else begin
            new_value <= 1'b0;
        end
    end

endmodule
