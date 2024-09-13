sim_tx: tx.sv
	vlog tx.sv tx_tb.sv rx_model.sv
	vsim -c work.tx_tb -do "run -all; quit"
sim_tx_115200_even: tx.sv
	vlog -sv tx.sv tx_tb.sv rx_model.sv
	vsim -c work.tx_tb -gBAUD_RATE=115200 -gPARITY=0 -do "run -all; quit"
clean:
	rm -f transcript ./work/* *.mpf *.mti *.log *.pb *.mti *.vstf *wlft* *.wlf .nfs* tmp

