# Simulation rule for ROM (fight_song)
sim_bram_rom:
	vlog -work work ascii_bram_rom.sv ascii_bram_rom_tb.sv
	vsim -c -do "run -all; quit" ascii_bram_rom_tb

# Simulation rule for ROM (declaration_of_independence)
sim_bram_rom_declaration:
	vlog -work work ascii_bram_rom.sv ascii_bram_rom_tb.sv
	vsim -c -do "run -all; quit" ascii_bram_rom_tb +FILENAME="declaration_of_independence.mem"

# Synthesis rule for ROM
synth_bram_rom:
	vivado -mode batch -source synth_rom.tcl
