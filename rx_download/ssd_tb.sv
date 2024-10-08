module seven_segment (
    input logic clk,
    input logic rst,
    input logic [31:0] display_val,
    input logic [7:0] dp,
    input logic blank,
    output logic [6:0] segments,
    output logic dp_out,
    output logic [7:0] an_out
);

    parameter CLK_FREQUENCY = 100_000_000;
    parameter MIN_SEGMENT_DISPLAY_US = 10_000;

    logic [2:0] current_digit; // 3 bits for 8 digits
    logic [23:0] counter;       // Counter for timing

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_digit <= 0;
            counter <= 0;
        end else begin
            // Increment counter
            if (counter < (CLK_FREQUENCY * MIN_SEGMENT_DISPLAY_US / 1_000_000) - 1) begin
                counter <= counter + 1;
            end else begin
                counter <= 0;
                current_digit <= (current_digit + 1) % 8; // Round-robin
            end
        end
    end

    always_comb begin
        // Default outputs
        segments = 7'b1111111; // All segments off
        dp_out = 1'b1; // Decimal point off
        an_out = 8'b11111111; // All anodes off (high)

        if (!blank) begin
            an_out[current_digit] = 1'b0; // Enable current digit
            dp_out = dp[current_digit]; // Control decimal point for current digit

            // Display the corresponding digit on the segments
            case (display_val[(current_digit * 4) +: 4]) // Extract 4 bits for the digit
                4'h0: segments = 7'b0000001; // 0
                4'h1: segments = 7'b1001111; // 1
                4'h2: segments = 7'b0010010; // 2
                4'h3: segments = 7'b0000110; // 3
                4'h4: segments = 7'b1001100; // 4
                4'h5: segments = 7'b0100100; // 5
                4'h6: segments = 7'b0100000; // 6
                4'h7: segments = 7'b0001111; // 7
                4'h8: segments = 7'b0000000; // 8
                4'h9: segments = 7'b0000100; // 9
                4'hA: segments = 7'b0001000; // A
                4'hB: segments = 7'b1100000; // B
                4'hC: segments = 7'b0110001; // C
                4'hD: segments = 7'b1000010; // D
                4'hE: segments = 7'b0110000; // E
                4'hF: segments = 7'b0111000; // F
                default: segments = 7'b1111111; // Default off
            endcase
        end
    end
endmodule
