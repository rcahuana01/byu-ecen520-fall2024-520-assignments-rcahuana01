# Name of the Assignment

Name: Rodrigo Cahuana
Hours Spent: 10

## Summarize any major challenges you had completing this assignment
* Challenge 1. 
* Challenge 2. Debugging the circuit is usually challenging

## Provide suggestions for improving this assignment (optional)
  * Suggestion 1

## Assignment Specific Responses

Assignment specific Questions:
Review the timing report and summarize the following:
Determine the "Worst Negative Slack" (or WNS).

1.760

Summarize the no_input_delay and no_output_delay section of the report.

5. checking no_input_delay (20)
-------------------------------
 There are 20 input ports with no input delay specified. (HIGH)

 There are 0 input ports with no input delay but user has a false path constraint.


6. checking no_output_delay (19)
--------------------------------
 There are 19 ports with no output delay specified. (HIGH)

 There are 0 ports with no output delay but user has a false path constraint

 There are 0 ports with no output delay but with a timing clock defined on it or propagating through it

How many total endpoints are there on your clock signal?

278

Find the first net in the Max Delay Paths section and indicate the source and destination of this maximum path.

Source:                 adxl362_inst/spi_inst/done_reg/C
                            (falling edge-triggered cell FDCE clocked by sys_clk_pin  {rise@0.000ns fall@5.000ns period=10.000ns})
  Destination:            rx_registers_reg[1][2]/CE
                            (rising edge-triggered cell FDCE clocked by sys_clk_pin  {rise@0.000ns fall@5.000ns period=10.000ns})

Indicate how many times you had to synthesize and download your bitstream before your circuit worked.

6 times. 

"I have read the ECEN 520 assignment submission process and have resolved any questions I have with this process"
