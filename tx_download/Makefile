sim_debounce: debounce.sv
	vlog -sv debounce.sv debounce_tb.sv
	vsim -c work.tx_tb -do "run -all; quit"
sim_tx_top: tx_top.sv
	vlog -sv tx_top.sv tx_top_tb.sv
	vsim -c work.tx_tb -do "run -all; quit"
sim_tx_top_115200_even: tx_top.sv
	vlog -sv tx_top.sv tx_top_tb.sv
	vsim -c work.tx_tb -gBAUD_RATE=115200 -gPARITY=0 -do "run -all; quit"
#sim_tx_bit_115200_even: tx.sv

clean:
	rm -rf transcript ./work/*
	rm -f *.mpf *.mti *.log *.pb *.mti *.vstf *wlft* *.wlf .nfs* tmp *.bak

