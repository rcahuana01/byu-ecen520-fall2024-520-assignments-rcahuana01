read_verilog -sv top_spi_adxl362.sv top_spi_adxl362_tb.sv ../rx_download/ssd.sv ../spi_cntrl/adxl362_model.sv ../spi_cntrl/adxl362_controller.sv ../spi_cntrl/spi_controller.sv ../rx_download/one_shot.sv ../tx_download/debounce.sv
read_xdc top.xdc
synth_design -top top_spi_adxl362_synth -part xc7a100tcsg324-1 -generic {SCLK_FREQUENCY=100000}
opt_design
place_design
route_design
write_checkpoint -force checkpoint_impl.dcp
report_io -file io.rpt
report_timing_summary -max_paths 10 -report_unconstrained -file timing_summary_routed.rpt -warn_on_violation
report_utilization -file utilization_impl.rpt
report_drc -file drc_routed.rpt
write_bitstream -force top_spi_adxl362_100.bit
