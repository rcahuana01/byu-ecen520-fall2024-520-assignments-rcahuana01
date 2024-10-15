module spi_controller #(

    parameter CLK_FREQUENCY = 100_000_000,    // System clock frequency (in Hz)

    parameter SCLK_FREQUENCY = 500_000        // SPI clock frequency (in Hz)

)(

    input wire clk,                           // System clock

    input wire rst,                           // Reset signal

    input wire start,                         // Start transfer signal

    input wire [7:0] data_to_send,            // Data to send to the subunit

    input wire hold_cs,                       // Hold CS signal for multi-byte transfers

    input wire SPI_MISO,                      // SPI MISO signal

    output reg [7:0] data_received,           // Data received from the subunit

    output reg busy,                          // Controller busy signal

    output reg done,                          // Transfer done signal

    output reg SPI_SCLK,                      // SPI clock signal

    output reg SPI_MOSI,                      // SPI MOSI signal

    output reg SPI_CS                         // Chip select signal

);



    // Internal parameters

    localparam integer SCLK_HALF_PERIOD = CLK_FREQUENCY / (2 * SCLK_FREQUENCY); // Clock divider for half SCLK period



    // State machine states

    typedef enum logic[1:0] {

        IDLE,        // Idle state, waiting for start signal

        TRANSFER,    // Transferring data over SPI

        DONE         // Transfer done, waiting to return to IDLE

    } state_t; state_t current_state = IDLE, next_state = IDLE;



    // Internal signals

    reg [7:0] tx_shift_register;              // Shift register for data transmission

    reg [7:0] rx_shift_register;              // Shift register for data reception

    reg [3:0] bit_counter;                    // Counts the bits in a byte

    reg [15:0] sclk_counter;                  // SCLK clock divider counter



    /***************************************************************************

    * Sequential logic for state transitions and resets

    * The reset signal ensures the state machine returns to the idle state.

    ***************************************************************************/

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            current_state <= IDLE;            // Reset to idle state

        end else begin

            current_state <= next_state;      // Transition to the next state

        end

    end



    /***************************************************************************

    * Combinational logic for next state determination

    * This determines the transitions between states in the state machine.

    ***************************************************************************/

    always_comb begin

        next_state = current_state;

        case (current_state)

            IDLE: begin

                if (start) begin

                    next_state = TRANSFER;    // Start the transfer on start signal

                end

            end

            TRANSFER: begin

                if (bit_counter == 8) begin

                    next_state = DONE;        // Complete transfer after 8 bits

                end

            end

            DONE: begin

                next_state = IDLE;            // Return to idle after completing transfer

            end

        endcase

    end



    /***************************************************************************

    * Sequential logic for clock divider and data shifting

    * SPI clock and data signals are updated here.

    ***************************************************************************/

    always_ff @(negedge clk or posedge rst) begin

        if (rst) begin

            sclk_counter <= 0;

            SPI_SCLK <= 0;

            SPI_MOSI <= 0;

            SPI_CS <= 1;

            tx_shift_register <= 0;

            rx_shift_register <= 0;

            bit_counter <= 0;

            data_received <= 0;

            done <= 0;

            busy <= 0;

        end else begin

            case (current_state)

                IDLE: begin

                    SPI_CS <= 1;              // Deassert chip select in idle

                    SPI_SCLK <= 0;            // Set clock low

                    sclk_counter <= 0;        // Reset clock divider

                    busy <= 0;

                    done <= 0;

                    bit_counter <= 0;

                    tx_shift_register <= data_to_send;  // Load data to send

                    rx_shift_register <= 8'b0;          // Clear receive register

                    SPI_MOSI <= tx_shift_register[7];   // Load MSB first for transmission

                    if (start) begin

                        SPI_CS <= 0;          // Assert chip select on start

                        busy <= 1;            // Mark controller as busy

                    end

                end

                TRANSFER: begin

                    // Clock divider for SPI clock generation

                    if (sclk_counter == SCLK_HALF_PERIOD - 1) begin

                        sclk_counter <= 0;

                        SPI_SCLK <= ~SPI_SCLK;   // Toggle the SPI clock



                        // On falling edge, shift data and prepare for next bit

                        if (SPI_SCLK == 0) begin

                            tx_shift_register <= {tx_shift_register[6:0], 1'b0};  // Shift left

                            SPI_MOSI <= tx_shift_register[7];                     // Send next bit

                        end

                        // On rising edge, sample incoming data

                        else begin

                            rx_shift_register <= {rx_shift_register[6:0], SPI_MISO};  // Capture data from MISO

                            bit_counter <= bit_counter + 1;                           // Increment bit counter

                        end

                    end else begin

                        sclk_counter <= sclk_counter + 1;  // Increment clock divider

                    end

                end

                DONE: begin

                    data_received <= rx_shift_register;   // Capture received data

                    done <= 1;                            // Signal transfer complete

                    busy <= 0;                            // Clear busy flag

                    SPI_CS <= hold_cs ? 0 : 1;            // Release or hold chip select

                    SPI_SCLK <= 0;                        // Set clock low

                    SPI_MOSI <= 0;                        // Clear MOSI

                end

            endcase

        end

    end



endmodule