/***************************************************************************
*
* Module: top_spi_adxl362_tb.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall 2024
* Date: 10/14/2024
* Description: Testbench for SPI Top-Level ADXL362 Controller
*
****************************************************************************/
module top_spi_adxl362_tb;

	// Parameters
	parameter CLK_FREQUENCY = 100_000_000;
	parameter SCLK_FREQUENCY = 1_000_000;

	// Testbench signals
	logic CLK100MHZ;
	logic CPU_RESETN;
	logic [15:0] SW;
	logic BTNL;
	logic BTNR;
	logic [15:0] LED;
	logic LED16_B;
	logic ACL_MISO;
	logic ACL_SCLK;
	logic ACL_CSN;
	logic ACL_MOSI;
	logic [7:0] AN;
	logic CA, CB, CC, CD, CE, CF, CG;
	logic DP;

	// Instance of the top-level design
	top_spi_adxl362 #(
		.CLK_FREQUENCY(CLK_FREQUENCY),
		.SCLK_FREQUENCY(SCLK_FREQUENCY)
	) dut (
		.CLK100MHZ(CLK100MHZ),
		.CPU_RESETN(CPU_RESETN),
		.SW(SW),
		.BTNL(BTNL),
		.BTNR(BTNR),
		.LED(LED),
		.LED16_B(LED16_B),
		.ACL_MISO(ACL_MISO),
		.ACL_SCLK(ACL_SCLK),
		.ACL_CSN(ACL_CSN),
		.ACL_MOSI(ACL_MOSI),
		.AN(AN),
		.CA(CA),
		.CB(CB),
		.CC(CC),
		.CD(CD),
		.CE(CE),
		.CF(CF),
		.CG(CG),
		.DP(DP)
	);

	// Instance of the ADXL362 simulation model
	adxl362_model adxl362_sim_inst (
		.miso(ACL_MISO),
		.sclk(ACL_SCLK),
		.cs(ACL_CSN),
		.mosi(ACL_MOSI)
	);

	// Clock generation
	initial begin
		CLK100MHZ = 0;
		forever #5 CLK100MHZ = ~CLK100MHZ;  // Generate a clock with 10ns period
	end

	// Test sequence
	initial begin
		// Initialize inputs
		CPU_RESETN = 0;
		SW = 16'h0000;
		BTNL = 0;
		BTNR = 0;

		// Wait for a few clock cycles
		#20;

		// Assert reset for a few clock cycles
		CPU_RESETN = 0;
		#10;
		CPU_RESETN = 1;  // Deassert reset
		#20;

		// Read DEVICEID register (0x0)
		SW = 16'h0000;  // Address 0x0
		BTNR = 1;       // Initiate read
		#10;
		BTNR = 0;       // Clear read button

		// Wait for a few cycles to allow read to complete
		#20;

		// Read PARTID register (0x02)
		SW = 16'h0002;  // Address 0x02
		BTNR = 1;       // Initiate read
		#10;
		BTNR = 0;       // Clear read button

		// Wait for a few cycles to allow read to complete
		#20;

		// Read status register (0x0B)
		SW = 16'h000B;  // Address 0x0B
		BTNR = 1;       // Initiate read
		#10;
		BTNR = 0;       // Clear read button

		// Wait for a few cycles to allow read to complete
		#20;

		// Write value 0x52 to register 0x1F for soft reset
		SW = {8'h52, 8'h1F};  // Data 0x52, Address 0x1F
		BTNL = 1;             // Initiate write
		#10;
		BTNL = 0;             // Clear write button

		// Wait for a few cycles
		#20;

		// End the simulation
		$finish;
	end

endmodule
