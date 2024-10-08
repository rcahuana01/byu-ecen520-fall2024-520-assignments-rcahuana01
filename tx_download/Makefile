sim_debouncer: debounce.sv
	vlog -sv debounce.sv debounce_tb.sv
	vsim -c work.debounce_tb -do "run -all; quit"

sim_tx_top: tx_top.sv
	vlog -sv tx_top.sv tx_top_tb.sv ../tx_sim/tx.sv gen_bounce.sv debounce.sv ../tx_sim/rx_model.sv
	vsim -c work.tx_top_tb -do "run -all; quit"

sim_tx_top_115200_even: tx_top.sv
	vlog -sv tx_top.sv tx_top_tb.sv ../tx_sim/tx.sv gen_bounce.sv debounce.sv ../tx_sim/rx_model.sv
	vsim -c work.tx_top_tb -gBAUD_RATE=115200 -gPARITY=0 -do "run -all; quit"

gen_tx_bit:
	vivado -mode batch -source tx_top_synth.tcl 

gen_tx_bit_115200_even:
	vivado -mode batch -source tx_top_115200_even_synth.tcl 

clean:
	rm -rf transcript work
	rm -f *.mpf *.mti *.log *.pb *.vstf *wlft* *.wlf .nfs* tmp *.bak *.jou *.rpt *.txt *.dcp
	rm -f *.Xil *.jou *.backup.log *.dcp *.txt *.rpt 
