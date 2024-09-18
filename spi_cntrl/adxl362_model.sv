// simple simulation model for the adxl345 accelerometer spi interface

module adxl362_model (sclk, mosi, miso, cs);

    input wire logic sclk;
    input wire logic mosi;
    output miso;
    input wire logic cs;

    // Command constants
    const logic [7:0] WRITE_COMMAND = 8'h0A;
    const logic [7:0] READ_COMMAND = 8'h0B;
    const logic [7:0] FIFO_COMMAND = 8'h0D;

    // Address constants
    const logic [7:0] DEVICE_ID_ADDR = 8'h00;
    const logic [7:0] DEVICE_ID_0X1D_ADDR = 8'h01;
    const logic [7:0] PART_ID_ADDR = 8'h02;
    const logic [7:0] SILICON_REV_ADDR = 8'h03;
    const logic [7:0] X_AXIS_MSB_ADDR = 8'h08;
    const logic [7:0] Y_AXIS_MSB_ADDR = 8'h09;
    const logic [7:0] Z_AXIS_MSB_ADDR = 8'h0a;
    const logic [7:0] STATUS_ADDR = 8'h0b;

    // Result constants
    const logic [7:0] DEVICE_ID = 8'hAD;
    const logic [7:0] DEVICE_ID_0X1D = 8'h1D;
    const logic [7:0] PART_ID = 8'hF2;
    const logic [7:0] SILICON_REV = 8'h02;
    const logic [7:0] DEFAULT_VAL = 8'hff;
    const logic [7:0] DEFAULT_STATUS = 8'h41;


    typedef enum {COMMAND, ADDRESS, DATA} current_byte_e;

    current_byte_e current_byte = COMMAND;
    typedef enum {WRITE_OP, READ_OP, UNKNOWN} transaction_type_e;
    transaction_type_e current_transaction;

    logic [7:0] current_address = 0;
    int current_byte_num;  // Indicates which byte is being transferred

    logic [7:0] received_value = 0;
    logic [7:0] send_value = 0;
    int bits_received = 0;
    logic active = 0;

    // High impedence if there is not a transaction going on
    assign miso = active ? send_value[7] : 1'bz;

    // Capture data coming in
    always@(posedge sclk)
    begin
        if (cs == 0) begin // Only process sclks when CS is low
            // using blocking so I have the updated values
            received_value = {received_value[6:0],mosi};
            bits_received = bits_received + 1;

            if (bits_received == 8) begin
                // First byte is the command
                if (received_value == WRITE_COMMAND) begin
                    current_transaction = WRITE_OP;
                    $display("[%0t]  ADXL362: Write operation", $time);
                end
                else if (received_value == READ_COMMAND) begin
                    current_transaction = READ_OP;
                    $display("[%0t]  ADXL362: Read operation", $time);
                end
                else begin
                    current_transaction = UNKNOWN;
                    $display("[%0t]  ADXL362: Unknown operation", $time);
                end
            end
            else if (bits_received == 16) begin
                // Second byte is the address
                current_address = received_value;
                $display("[%0t]  ADXL362: Address 0x%h", $time, current_address);
                if (current_transaction == READ_OP) begin
                    case(current_address)
                        DEVICE_ID_ADDR: send_value = DEVICE_ID; // Device ID register
                        DEVICE_ID_0X1D_ADDR: send_value = DEVICE_ID_0X1D; // Device ID 0X1D register
                        PART_ID_ADDR: send_value = PART_ID ; // PART ID register
                        SILICON_REV_ADDR: send_value = SILICON_REV; // Silicon revision register
                        X_AXIS_MSB_ADDR: send_value = $urandom_range(0,255); // X axis MSB data
                        Y_AXIS_MSB_ADDR: send_value = $urandom_range(0,255); // Y axis MSB data
                        Z_AXIS_MSB_ADDR: send_value = $urandom_range(0,255); // Z axis MSB data
                        STATUS_ADDR: send_value = DEFAULT_STATUS; // Status register
                        default: send_value = DEFAULT_VAL;
                    endcase
                    $display("[%0t]  ADXL362: Sending Value 0x%h", $time, send_value);
                end
            end
            else if (bits_received >= 24 && bits_received % 8 == 0) begin
                if (current_transaction == WRITE_OP) begin
                    $display("[%0t]  ADXL362: Received Value 0x%h", $time, received_value);
                end
            end
            else
                send_value <= {send_value[6:0],1'b0};
        end
    end

    // Reset internal state
    always@(posedge cs) begin
        active <= 1'b0;
    end

    // Setup transfer
    always@(negedge cs) begin
        active <= 1'b1;
        send_value <= 0;
        bits_received <= 0;
        current_byte = COMMAND;
    end


endmodule
