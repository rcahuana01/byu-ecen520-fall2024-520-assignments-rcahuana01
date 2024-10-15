/***************************************************************************
*
* Module: top_spi_adxl362_tb.sv
* Author: Rodrigo Cahuana
* Class: ECEN 520. Section 01, Fall2024
* Date: 10/14/2024
* Description: Testbench to verify the functionality of top level adxl362
*
****************************************************************************/
module top_spi_adxl362_tb;
    reg CLK100MHZ;
    reg CPU_RESETN;
    reg [15:0] SW;
    reg BTNL, BTNR;
    wire [15:0] LED;
    wire LED16_B;
    wire ACL_MISO, ACL_SCLK, ACL_CSN, ACL_MOSI;
    
    // Clock generation
    initial CLK100MHZ = 0;
    always #5 CLK100MHZ = ~CLK100MHZ;  // 100MHz clock
    
    initial begin
        // Initial conditions
        CPU_RESETN = 0; SW = 16'h0000; BTNL = 0; BTNR = 0;
        #100 CPU_RESETN = 1;
        
        // Simulate read/write operations
        #200 SW = 16'h000F; BTNL = 1;  // Simulate a write
        #50 BTNL = 0;
        #200 SW = 16'h0001; BTNR = 1;  // Simulate a read
        #50 BTNR = 0;
        
        // Test more operations as needed
    end

    // Instantiate top-level design
    top_spi_adxl362 uut (
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
        .ACL_MOSI(ACL_MOSI)
    );
    
endmodule
