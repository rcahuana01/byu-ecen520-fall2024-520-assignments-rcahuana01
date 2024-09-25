sim_rx: rx.sv rx_tb.sv ../tx_sim/tx.sv
	vlog -sv rx.sv rx_tb.sv ../tx_sim/tx.sv
	vsim -c work.tb_rx -do "run -all; quit"

sim_rx_115200_even: rx.sv rx_tb.sv ../tx_sim/tx.sv
	vlog -sv rx.sv rx_tb.sv ../tx_sim/tx.sv
	vsim -c work.tb_rx -gBAUD_RATE=115200 -gPARITY=0 -do "run -all; quit"

synth_rx: rx.sv
	read_verilog -sv rx.sv
	synth_design -top rx -mode out_of_context -log synth.log

clean:
	rm -rf transcript ./work/*
	rm -f *.mpf *.mti *.log *.pb *.vstf *wlft* *.wlf .nfs* tmp *.bak
