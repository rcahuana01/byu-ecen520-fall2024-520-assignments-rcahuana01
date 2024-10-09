sim_spi_cntrl:
	vlog -sv spi.sv spi_tb.sv spi_subunit.sv
	vsim -c work.spi_tb -do "run -all; quit"

sim_spi_cntrl_100:
	vlog -sv spi.sv spi_tb.sv spi_subunit.sv
	vsim -c work.spi_tb -gSCLK_FREQUENCY=100000 -do "run -all; quit"

sim_adxl362:
	vlog -sv adxl362.sv adxl362_tb.sv 
	vsim -c work.adxl362_tb -do "run -all; quit"

sim_adxl362_100:
	vlog -sv adxl362.sv adxl362_tb.sv 
	vsim -c work.adxl362_tb -gSCLK_FREQUENCY=100000 -do "run -all; quit"

clean:
	rm -rf transcript work
	rm -f *.mpf *.mti *.log *.pb *.vstf *wlft* *.wlf .nfs* tmp *.bak *.jou *.rpt *.txt *.dcp
	rm -f *.Xil *.jou *.backup.log *.dcp *.txt *.rpt *.do
