# Memories

In this lecture we will discuss the memory architecture on the Xilinx 7-series FPGAs.
We will discuss different ways of insantiating memories within HDL code and how to infer memories from HDL code.

## Reading
  * [7 Series Memory Resources](https://www.xilinx.com/support/documentation/user_guides/ug473_7Series_Memory_Resources.pdf)
  * [Xilinx Synthesis Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2019_2/ug901-vivado-synthesis.pdf)
  * [Xilinx Libraries Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2019_1/ug953-vivado-7series-libraries.pdf)

## Key Concepts

  * Understand how a memory array differs from a register file
  * What are block memories used for
  * Understand the various modes of operation: WRITE_FIRST, READ_FIRST, and NO_CHANGE_MODE
  * Use the BRAM in different address/data width configurations
  * Timing parameters of a BRAM
  * How to instance a BRAM as a module
  * How to infer BRAMs from HDL
  * What is a FIFO and why is it used
