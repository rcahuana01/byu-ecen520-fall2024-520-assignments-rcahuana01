sim_ssd:
	vlog ssd.sv ssd_tb.sv seven_segment_check.sv
	vsim -c work.ssd_tb -do "run -all; quit"
sim_tx_115200_even: tx.sv
	vlog -sv tx.sv tx_tb.sv rx_model.sv
	vsim -c work.tx_tb -gBAUD_RATE=115200 -gPARITY=0 -do "run -all; quit"
clean:
	rm -rf transcript ./work/*
	rm -f *.mpf *.mti *.log *.pb *.mti *.vstf *wlft* *.wlf .nfs* tmp *.bak

