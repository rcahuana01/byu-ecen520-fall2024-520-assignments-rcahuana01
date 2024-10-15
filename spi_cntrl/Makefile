sim_spi_cntrl:
	vlog -sv spi_controller.sv spi_controller_tb.sv spi_subunit.sv
	vsim -c work.spi_controller_tb -do "run -all; quit"

sim_spi_cntrl_100:
	vlog -sv spi_controller.sv spi_controller_tb.sv spi_subunit.sv
	vsim -c work.spi_controller_tb -gSCLK_FREQUENCY=100000 -do "run -all; quit"

sim_adxl362:
	vlog -sv adxl362_controller.sv adxl362_controller_tb.sv adxl362_model.sv spi_controller.sv
	vsim -c work.adxl362_controller_tb -do "run -all; quit"

sim_adxl362_100:
	vlog -sv adxl362_controller.sv adxl362_controller_tb.sv adxl362_model.sv spi_controller.sv
	vsim -c work.adxl362_controller_tb -gSCLK_FREQUENCY=100000 -do "run -all; quit"

clean:
	rm -rf transcript work
	rm -f *.mpf *.mti *.log *.pb *.vstf *wlft* *.wlf .nfs* tmp *.bak *.jou *.rpt *.txt *.dcp
	rm -f *.Xil *.jou *.backup.log *.dcp *.txt *.rpt *.do
