read_verilog -sv rx.sv 
synth_design -top rx -part xc7a100tcsg324-1 -generic {PARITY=1}
opt_design
place_design
route_design
write_checkpoint -force checkpoint_impl.dcp
report_io -file io.rpt
report_timing_summary -max_paths 10 -report_unconstrained -file timing_summary_routed.rpt -warn_on_violation
report_utilization -file utilization_impl.rpt
report_drc -file drc_routed.rpt
write_bitstream -force tx_top.bit
