# BRAM

In this assignment you will practice using BRAMs and interfacing them to your UART. 
You will use your BRAM to buffer data received from the UART receiver and to send over the transmitter. 
Two different BRAMs will be used in this assignment. 

## Synchronous FIFO

Create a module that implements a simple synchronous FIFO for ascii bytes (this will be used with the UART).
The ports of this module should be as follows:

| Port Name | Direction | Width | Function |
| ---- | ---- | ---- | ----  |
| clk | Input | 1 | Clock |
| rst | Input | 1 | Synchronous Reset |
| we | Input | 1 | Write enable |
| re | Input | 1 | Read enable |
| din | Input | 8 | Data In |
| dout | Output | 8 | Data Out |
| full | Output | 1 | Indicates FIFO is full |
| empty | Output | 1 | Indicates FIFO is empty |

Your FIFO should be created by as follows:
* Create a "write address" counter and a "read address" counter that indicate which address to write to and read from, respectively.
  * Every time a byte is written to the FIFO (i.e., when 'we' is asserted), the write address should increment by one. The address should roll over if you reach the limit. 
  * You should read from the memory every clock cycle. Increment this address every time the 're' signal is asserted.
* Perform a write to the memory when the 'we' signal is asserted.
* Create an 'empty' signal that is asserted when the read address is equal to the write address.
* Create a 'full' signal that is asserted when the write address is one less than the read address.
* Instance a `RAMB36E1` primitive into your design using an 8-bit data bus. You will need to carefully read the details about this primitive in the [7 Series Memory Resources (UG473)](https://docs.amd.com/v/u/en-US/ug473_7Series_Memory_Resources) (see page 25).
  * Make sure all inputs are wired up. Many inputs are not needed but every input should have a constant if it is not used.
  * Use the 'A' port for writing to the BRAM and the 'B' port for reading from the BRAM. 
  * To configure each of the ports to 8 bits, set the `READ_WIDTH_B` parameter to 9  and the `WRITE_WIDTH_A` to 9.
  * Set the `WRITE_MODE_A` parameter to "READ_FIRST"
  * Connect the following ports appropriately. Make sure you connect all the bits of each of the port (see the datasheet for details):
    * `DIADI` and `DOBDO` (32-bit data ports)
    * `ADDRARDADDR` and `ADDRBWRADDR` (16 bits) It is tricky to hook up the address ports appropriately. Read the data sheet carefully to understand how to connect this port.
    * `WEA` (4 bit write enable).
    * `ENARDEN`

Create a simple testbench that demonstrates writing a few bytes, reading/writing a few bytes, and the full/empty signals working properly.
Use a SystemVerilog 'queue' to store the values of the FIFO so you can check that the order you write is the order that you read.
To simulate the `RAMB36E1` primitive you will need to include the 'unisim' library in your simulation.
This precompiled library contains all the simulation models of the Xilinx primitives.
Follow these steps to include this library in your simulation environment:
* Add the following line to your `modelsim.ini` file: `unisim = /tools/Xilinx/Vivado/2024.1/data/questa/unisim`. Note that the path for this library is based on the computers in the digital lab. You may need to adjust this path if you are using a different computer.
* Add the flag `-L unisim` to your `vlog` command in your simulation script.
Create a makefile rule named `sim_bram_fifo` that runs this simulation from the command line.

<!--
* `vlib unisim`
* `vmap unisim <Simulation library path>`. For the computers in the digital lab, the simulation path is: 
-->

## ASCII BRAM ROM

Create a second module that implements a "ROM" that stores a set of ASCII characters that can be read out one character at a time.
This module will be used to store a message sent over the UART.
The ports of this module should be as follows:

| Port Name | Direction | Width | Function |
| ---- | ---- | ---- | ----  |
| clk | Input | 1 | Clock |
| rst | Input | 1 | Synchronous Reset |
| init | Input | 1 | Return pointer to zero |
| re | Input | 1 | Read enable |
| dout | Output | 8 | Data Out |
| rom_end | Output | 1 | Indicates the buffer is empty  |

| Parameter | Type | Function |
| ---- | ---- | ---- |
| FILENAME | string | File name of the ASCII file to read |

Design your module to operate as follows:
* Create an "inferred" memory that is 8 bits x 4096 (i.e., don't instance the BRAM primitive but use the inferred memory in your HDL).
* Provide a parameter that contains a file name that contains the data to be stored in the ROM. Create an initial block that performs this initialization.
* Create a read pointer that indicates which address to read from
* Increment this pointer every time `re` is asserted
* Reset the pointer when `init` is asserted
* Assert the 'end' signal when the value of the memory output is zero

Create a testbench that demonstrates the ability to read all the contents of the ROM until the `end` signal is asserted.
Make sure you provide a couple of clock cycles between each read.
Create a makefile rule named `sim_bram_rom` that runs this simulation from the command line.

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
