synth_adxl362_cntrl:
	read_verilog -sv top_spi_adxl362.sv
	synth_desig -top top_spi_adxl362 -mode out_of_context
	
sim_top:
	vlog -sv top_spi_adxl362.sv top_spi_adxl362_tb.sv ../spi_cntrl/adxl362.sv 
	vsim -c work.top_spi_adxl362_tb -do "run -all; quit"

sim_top_100:
	vlog -sv top_spi_adxl362.sv top_spi_adxl362_tb.sv ../spi_cntrl/adxl362.sv 
	vsim -c work.tx_top_tb -gSCLK_FREQUENCY=100000 -do "run -all; quit"

gen_bit:
	vivado -mode batch -source gen_bit.tcl

gen_bit_100:
	vivado -mode batch -source gen_bit_100.tcl

clean:
	rm -rf transcript work
	rm -f *.mpf *.mti *.log *.pb *.vstf *wlft* *.wlf .nfs* tmp *.bak *.jou *.rpt *.txt *.dcp
	rm -f *.Xil *.jou *.backup.log *.dcp *.txt *.rpt *.do