# Name of the Assignment

Name: Rodrigo Cahuana
Hours Spent: 10

## Summarize any major challenges you had completing this assignment
* Challenge 1. Calculating the debounce clocks took me while to understand the math
* Challenge 2. Debugging the mutiple signals and levels took a while and it had to be very focus on where the signal changes

## Provide suggestions for improving this assignment (optional)
  * Suggestion 1

## Assignment Specific Responses

Assignment specific Questions:
-The synthesis log will summarize any state machines that it created. Provide a table listing the state and the encoding that the synthesis tool used for your transmitter state machine.

---------------------------------------------------------------------------------------------------
                   State |                     New Encoding |                Previous Encoding 
---------------------------------------------------------------------------------------------------
                    IDLE |                              000 |                              000
                   START |                              001 |                              001
                    BITS |                              010 |                              010
                     PAR |                              011 |                              011
                    STOP |                              100 |                              100
---------------------------------------------------------------------------------------------------


-Provide a table summarizing the resources your design uses. Use the template table below. You can get this information from the implementation utilization report.

+------+------+------+
|      |Cell  |Count |
+------+------+------+
|1     |BUFG  |     1|
|2     |LUT1  |     1|
|3     |LUT3  |     3|
|4     |LUT4  |     8|
|5     |LUT5  |     3|
|6     |LUT6  |     3|
|7     |MUXF7 |     1|
|8     |FDCE  |     7|
|9     |FDPE  |     1|
|10    |FDRE  |    10|
|11    |LDP   |     1|
|12    |IBUF  |    10|
|13    |OBUF  |    10|
+------+------+------+
Baud rate = 19200
Parity even
Debounce delay = 10ms
-Determine the "Worst Negative Slack" (or WNS). This is found in the timing report and indicates how much timing you slack you have with the current clocking (we will discuss this later in the semester).
0.389ns 
-Indicate how many times you had to synthesize and download your bitstream before your circuit worked.
4 times
"I have read the ECEN 520 assignment submission process and have resolved any questions I have with this process"
