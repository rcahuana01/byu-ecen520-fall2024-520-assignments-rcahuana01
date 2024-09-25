read_verilog -sv rx.sv 
synth_design -top rx -part xc7a100tcsg324-1 -generic {PARITY=1}
