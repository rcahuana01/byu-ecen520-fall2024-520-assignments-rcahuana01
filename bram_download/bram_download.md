# BRAM Download

In this assignment you will practice using BRAMs and interfacing them to your UART. 
You will use your BRAM to buffer data received from the UART receiver and to send over the transmitter. 
Two different BRAMs will be used in this assignment. 

## Top-Level Design

Create a top-level design that instantiates both the FIFO and the ROM modules.
Design your top-level design to operate as follows:
* Instance your UART transmitter and receiver and connect them to the top-level UART ports
* When the **left** button is pressed, the _entire_ ROM contents are sent over the UART transmitter one character at a time. Ignore any button presses that may occur until the entire ROM has been sent. You will need to implement flow control so that you don't send another character until the previous character has been sent.
* When characters are received by the UART receiver, they are placed in the BRAM FIFO.
* When the **right** button is pressed, your circuit should send each character received in the BRAM over the UART back to the host until the BRAM FIFO is empty. Ignore any button presses that may occur until the entire FIFO has been sent. After sending the full contents of the FIFO, reset your counters so that you only send the new data received after the button has been pressed (you don't want to send the data received more than once).
* Use `LED16_B` for the TX busy signal, `LED17_R` for the RX busy signal, and `LED17_G` for the RX error signal.


## BRAM Playback

Implement a UART "buffer" with a second BRAM that saves the data received from the UART receiver one character after another.
Infer a second BRAM from HDL (no instancing of primitive) that is organized as 8x4096. 
This BRAM should store each character received from the UART in one address after the next. 
Create a counter that indicates the location where to store the next UART received character (you will need to display this counter in hex on the seven segment display).
When the **right** button is pressed, your circuit should send each character received in the BRAM over the UART back to the host.
Once the data has been sent, reset your counters so that you only send the new data received after the button has been pressed (you don't want to send the data received more than once).

Your BRAM will act like a FIFO: characters received from the UART are placed in the BRAM FIFO and when the button is pressed, the BRAM fifo is read and sent over the transmitter until the FIFO has emptied.

## Testbench

Create a top-level testbench that instantiates your design and simulates the behavior of all three ways to send data over the UART.

* Hook up my UART receiver model that prints out the characters it receives.
* Instance a second copy of your transmitter in the testbench so that you can provide data for the receiver. Control this by your testbench.
* Hook up the seven segment display checker (even though we don't really care about it much)

* Initialize and reset your design
* Have your testbench transmitter send the characters "Hello World" to your receiver
* Send two characters over the transmitter by pressing BTNC
* Press buttonL to send the fight song. Send the entire sequence to make sure it stops (this may take a while)
* Have your testbench transmitter send the characters "Good Bye" to your receiver
* Press button R to send the data in your BRAM buffer out the transmitter


Create a makefile rule `sim_top` that performs this simulation from the command line. Genrics?
Create a makefile rule `gen_bit` that generates a bitstream for your top-level design. Generics?


## Submission

Report:
- Get something out of the syntehsis log (verigy number of BRAMs)
- Take a screen shot of the layout of the device. Point out the BRAMs.

Add detailed timing analysis to your README.md file.

`sim_bram_fifo`
`sim_bram_rom`

<!--
They use glbl.v file for simulation. Need to include in their repository.
Don't hard code any paths in makefile! (perhaps have an environment variable that is set so I can reuse their makefiles)
- Have them simulate the full fight song

- buffer empties when right pressed.
- start fight song with new line (make it more clear how to setup putty and what to send at the end of the line)
- Have the fight song spit out the text as fast as possible (no delays).
-->
