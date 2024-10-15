sim_ssd:
	vlog ssd.sv ssd_tb.sv seven_segment_check.sv
	vsim -c work.ssd_tb -do "run -all; quit"

synth_ssd:
	read_verilog -sv ssd.sv
	synth_desig -top ssd -mode out_of_context
sim_rx_top:
	vlog rxtx_top.sv rxtx_top_tb.sv one_shot.sv ../tx_download/debounce.sv ../tx_sim/tx.sv ../rx_sim/rx.sv ../tx_download/gen_bounce.sv
	vsim -c work.rxtx_top_tb -do "run -all; quit"


sim_rx_top_115200_even:
	vlog rxtx_top.sv rxtx_top_tb.sv one_shot.sv ../tx_download/debounce.sv  
	vsim -c work.rx_top_tb -gBAUD_RATE=115200 -gPARITY=0 -do "run -all; quit"
gen_bit:
	vivado -mode batch -source rxtx_top_synth.tcl 

gen_bit_115200_even:
	vivado -mode batch -source rxtx_top_115200_even_synth.tcl 
clean:
	rm -rf transcript work
	rm -f *.mpf *.mti *.log *.pb *.vstf *wlft* *.wlf .nfs* tmp *.bak *.jou *.rpt *.txt *.dcp
	rm -f *.Xil *.jou *.backup.log *.dcp *.txt *.rpt *.do testvcd

