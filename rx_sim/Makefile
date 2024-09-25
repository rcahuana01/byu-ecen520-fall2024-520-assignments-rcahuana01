sim_rx: rx.sv rx_tb.sv ../tx_sim/tx.sv
	vlog -sv rx.sv rx_tb.sv ../tx_sim/tx.sv
	vsim -c work.rx_tb -do "run -all; quit"

sim_rx_115200_even: rx.sv rx_tb.sv ../tx_sim/tx.sv
	vlog -sv rx.sv rx_tb.sv ../tx_sim/tx.sv
	vsim -c work.rx_tb -gBAUD_RATE=115200 -gPARITY=0 -do "run -all; quit"

synth_rx:
	vivado -mode batch -source rx_synth.tcl -log rx_implement.log

clean:
	rm -rf transcript ./work/* 
	rm -f *.mpf *.mti *.log *.pb *.vstf *wlft* *.wlf .nfs* tmp *.bak *.jou *.rpt *.txt *.dcp
	rm -f *.Xil *.jou *.backup.log *.dcp *.txt *.rpt 