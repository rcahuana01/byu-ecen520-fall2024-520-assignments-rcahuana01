# Compile Verilog files
read_verilog -sv top_spi_adxl362.sv
read_verilog -sv top_spi_adxl362_tb.sv
read_verilog -sv ../rx_download/ssd.sv
read_verilog -sv ../spi_cntrl/adxl362_model.sv
read_verilog -sv ../spi_cntrl/adxl362_controller.sv
read_verilog -sv ../spi_cntrl/spi_controller.sv
read_verilog -sv ../rx_download/one_shot.sv
read_verilog -sv ../tx_download/debounce.sv

# Compile XDC
read_xdc top.xdc
# Synthesis
synth_design -top spi_adxl362 -part xc7a100tcsg324-1
# Implementation
opt_design
place_design
route_design
# Save Checkpoint
write_checkpoint -force checkpoint_impl.dcp
# Generate Reports
report_io -file io.rpt
report_timing_summary -max_paths 10 -report_unconstrained -file timing_summary_routed.rpt -warn_on_violation
report_utilization -file utilization_impl.rpt
report_drc -file drc_routed.rpt
#Generate Bitstream
write_bitstream -force spi_adxl362.bit
