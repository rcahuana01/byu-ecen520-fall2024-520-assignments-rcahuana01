synth_adxl362_cntrl:
	vivado -mode batch -source adxl362_synth.tcl

sim_top:
	vlog -sv top_spi_adxl362.sv top_spi_adxl362_tb.sv ../rx_download/ssd.sv ../spi_cntrl/adxl362_model.sv ../spi_cntrl/adxl362_controller.sv ../spi_cntrl/spi_controller.sv ../rx_download/one_shot.sv ../tx_download/debounce.sv
	vsim -c work.top_spi_adxl362_tb -do "run -all; quit"

sim_top_100:
	vlog -sv top_spi_adxl362.sv top_spi_adxl362_tb.sv ../rx_download/ssd.sv ../spi_cntrl/adxl362_model.sv ../spi_cntrl/adxl362_controller.sv ../spi_cntrl/spi_controller.sv ../rx_download/one_shot.sv ../tx_download/debounce.sv
	vsim -c work.top_spi_adxl362_tb -gSCLK_FREQUENCY=100000 -do "run -all; quit"

gen_bit:
	vivado -mode batch -source gen_bit_synth.tcl

gen_bit_100:
	vivado -mode batch -source gen_bit_100_synth.tcl

clean:
	rm -rf transcript work
	rm -f *.mpf *.mti *.log *.pb *.vstf *wlft* *.wlf .nfs* tmp *.bak *.jou *.rpt *.txt *.dcp
	rm -f *.Xil *.jou *.backup.log *.dcp *.txt *.rpt *.do