# SPI ADXL362 Download

In this assignment, you will use your create a top-level design that communicate with the ADXL362 accelerometer on the Nexys4 board using the SPI protocol.

## Synthesis of SPI Controller Modules

Before proceeding with the top-level SPI design, it is important to make sure that your SPI controller and adxl362 controller from the previous assignment are properly synthesizable.
Create a makefile rule named `synth_adxl362_cntrl` that performs "out of context" synthesis of the adxl362 controller module from the preivous assignment (see the [instructions](../rx_sim/UART_Receiver_sim.md#receiver-synthesis) on how to do this).
Make sure all synthesis warnings and errors are resolved before proceeding with the top-level design.
If you made any changes to your modules, rerun the testbenches to make sure they operate correctly.

## SPI Top-Level Design

Create a top-level circuit that instances your SPI controller and attaches it to the accelerometer on the Nexys4 board. 
You will attach the switches, buttons, and seven segment display so you can write registers to the accelerometer and read values of the registers within the accelerometer. 
Details on how this is to be done are described below.  
Links to the Nexys4 board and the accelerometer are listed below for your convenience. 

The I/O for the top-level design should be designed as follows:
  * The left button (BTNL) should be used to initiate a write to the accelerometer
  * The right button (BTNR) should be used to initiate a read from the accelerometer
  * The lower 8 switches should be used to specify the 8-bit address of the register to read/write
  * The upper 8 switches should be used to specify the 8-bit data used for register writes
  * The 16 LEDs should follow the value of the switches to allow the user can easily verify that the address/data is properly set.
  * The accelerometer provides two interrupt pins that you do not need to use for this assignment (do not hook up these pins).
  * Instance your seven segment display controller and hook it up so that the last byte received from a register read is displayed on the _lower two digits_ of the seven segment display. The previously received bytes should be shifted up to the other seven segment display so you can still see them (with 8 digits you should be able to display the last four register read values).
  * Turn on LED16_B when your SPI controller unit is busy.

Provide the following parameters on your top-level design:

| Parameter Name | Default Value | Purpose |
| ---- | ---- | ---- |
| CLK_FREQUENCY | 100_000_000 | Specify the clock frequency of the board |
| SCLK_FREQUENCY  | 500_000 | Specify the frequency of the SCLK |
| SEGMENT_DISPLAY_US  | 1_000 | The amount of time in microseconds to display each digit (1 ms) |
| DEBOUNCE_DELAY_US | integer | 1_000 | Specifies the minimum debounce delay in micro seconds (1 ms) |

## SPI Top-Level Testbench

Create a top-level testbench of your top-level design that tests the operation of your top-level AXDL362L controller.
This testbench should be designed as follows:
* Make the top-level testbench parameterizable with the top-level parameters
* Create a free-running clock
* Instance your top-level design
* Instance the [ADXL362 simulation](./adxl362_model.sv) model
  * attach the SPI signals from the top-level design to the SPI signals of the simulation
* Perform the following sequence of events for your testbench:
  * Execute the simulation for a few clock cycles without setting any of the inputs
  * Set default values for the inputs (reset, buttons, and switchces)
  * Wait for a few clock cycle, assert the reset for a few clock cycles, deassert the reset (don't forget that the reset signal for the board is low asserted)
  * Perform the following operations within your testbench by setting the buttons and switches:
    * Read the DEVICEID register (0x0). Should get 0xad
    * Read the PARTID (0x02) to make sure you are getting consistent correct data (0xF2)
    * Read the status register (0x0b): should get 0x40 on power up (0xC0?)
    * Write the value 0x52 to register 0x1F for a soft reset

Make sure your top-level design successfully passes this testbench.
Add makefile rules named `sim_top`, using default parameters, and `sim_top_100`, that uses a 100_000 SCLK frequency, that will perform this simulation from the command line.


### Implementation and Download

At this point you are ready to implement your design, generate a bitfile and download your design to your board.
Create a new makefile rule named `gen_bit` that will generate a bitfile named `spi_adx362l.bit` for your top-level design with the default top-level parameters.
Create a new makefile rule named `gen_bit_100` that will generate a bitfile named `spi_adx362l_100.bit` with a 100_000 SCLK frequency.


Once you have created your design and downloaded it to the board, you can make sure it works by trying the following:

  * Read the DEVICEID register (0x0). Should get 0xad
  * Read the PARTID (0x02) to make sure you are getting consistent correct data (0xF2)
  * Read the status register (0x0b): should get 0x40 on power up (0xC0?)
  * Write the value 0x52 to register 0x1F for a soft reset
  * Write the value 0x00 to register 0x1F to clear the soft reset
  * Write the value 0x02 to register 0x2D to set "enable measure command"
  * Read the status register (0x0b): should get 0x41 now (you won't get any readings until the status is set to 0x41)
  * Write the value 0x14 to register 0x2C to set the Filter Control Register control register (50Hz)
  * Read the various accelerometer values to see changes in the acceleration (You can rotate the board around different axis to see changes in the readings)
    * Register 0x08 for XDATA
    * Register 0x09 for YDATA
    * Register 0x0A for ZDATA
  
## Submission and Grading

1. Required Makefile rules:
  * `synth_adxl362_cntrl`
  * `sim_top`:
  * `sim_top_100`:
  * `gen_bit`:
  * `gen_bit_100`:

