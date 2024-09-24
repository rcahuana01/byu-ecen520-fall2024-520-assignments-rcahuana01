sim_rx: rx.sv
	vlog -sv rx.sv rx_tb.sv
	vsim -c work.rx_tb -do "run -all; quit"

sim_rx_115200_even: rx.sv
	vlog -sv rx.sv rx_tb.sv
	vsim -c work.rx_tb -gBAUD_RATE=115200 -gPARITY=0 -do "run -all; quit"

synth_rx:
	read_verilog -sv rx.sv
	synth_desig -top rx -mode out_of_context
clean:
	rm -rf transcript ./work/*
	rm -f *.mpf *.mti *.log *.pb *.mti *.vstf *wlft* *.wlf .nfs* tmp *.bak
