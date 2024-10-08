sim_tx: tx.sv
	vlog tx.sv tx_tb.sv rx_model.sv
	vsim -c work.tx_tb -do "run -all; quit"
sim_tx_115200_even: tx.sv
	vlog -sv tx.sv tx_tb.sv rx_model.sv
	vsim -c work.tx_tb -gBAUD_RATE=115200 -gPARITY=0 -do "run -all; quit"
clean:
	rm -rf transcript work
	rm -f *.mpf *.mti *.log *.pb *.vstf *wlft* *.wlf .nfs* tmp *.bak *.jou *.rpt *.txt *.dcp
	rm -f *.Xil *.jou *.backup.log *.dcp *.txt *.rpt *.do

