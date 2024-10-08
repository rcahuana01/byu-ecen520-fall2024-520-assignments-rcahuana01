/***************************************************************************
*
* Module: one_shot.sv
* Author: Rodrigo Cahuana
* Date: 10/1/2024
* Description: One shot detector
*
****************************************************************************/
module one_shot (
    input wire clk,         
    input wire btnc_debounced,    
    output logic one_press       
);
    // Internal signals
    logic debounce_out1, debounce_out2;    

    // Debouncing logic
    always_ff @(posedge clk) begin
        debounce_out1 <= btnc_debounced; 
        debounce_out2 <= debounce_out1;   
    end

    // Generate a one-shot pulse when the button is pressed
    assign one_press = (debounce_out1 & ~debounce_out2); 

endmodule
