# Simulation rule for ROM (fight_song)
sim_bram_rom:
	vlog -sv ascii_bram_rom.sv ascii_bram_rom_tb.sv
	vsim -c work.top_spi_adxl362_tb -do "run -all; quit"

# Simulation rule for ROM (declaration_of_independence)
sim_bram_rom_declaration:
	vlog -sv ascii_bram_rom.sv ascii_bram_rom_tb.sv
	vsim -c work.top_spi_adxl362_tb -do "run -all; quit"

# Synthesis rule for ROM
synth_bram_rom:
	vivado -mode batch -source synth_rom.tcl
