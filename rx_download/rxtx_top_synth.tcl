read_verilog -sv rxtx_top.sv ssd.sv one_shot.sv ../tx_download/debounce.sv ../tx_sim/tx.sv ../rx_sim/rx.sv ../tx_download/gen_bounce.sv

read_xdc top.xdc

synth_design -top rxtx_top -part xc7a100tcsg324-1

opt_design
place_design
route_design

write_checkpoint -force checkpoint_impl.dcp

report_io -file io.rpt
report_timing_summary -max_paths 10 -report_unconstrained -file timing_summary_routed.rpt -warn_on_violation
report_utilization -file utilization_impl.rpt
report_drc -file drc_routed.rpt

write_bitstream -force rxtx_top.bit
