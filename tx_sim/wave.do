onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider TB
add wave -noupdate /tx_tb/clk
add wave -noupdate /tx_tb/rst
add wave -noupdate /tx_tb/tb_send
add wave -noupdate /tx_tb/tb_tx_out
add wave -noupdate /tx_tb/tx_busy
add wave -noupdate /tx_tb/tb_din
add wave -noupdate /tx_tb/char_to_send
add wave -noupdate /tx_tb/rx_data
add wave -noupdate /tx_tb/odd_parity_calc
add wave -noupdate /tx_tb/rx_busy
add wave -noupdate /tx_tb/r_state
add wave -noupdate -divider TX
add wave -noupdate /tx_tb/tx/clk
add wave -noupdate /tx_tb/tx/rst
add wave -noupdate /tx_tb/tx/send
add wave -noupdate /tx_tb/tx/din
add wave -noupdate /tx_tb/tx/busy
add wave -noupdate /tx_tb/tx/tx_out
add wave -noupdate /tx_tb/tx/ns
add wave -noupdate /tx_tb/tx/cs
add wave -noupdate /tx_tb/tx/clrTimer
add wave -noupdate /tx_tb/tx/timerDone
add wave -noupdate /tx_tb/tx/clrBit
add wave -noupdate /tx_tb/tx/incBit
add wave -noupdate /tx_tb/tx/bitDone
add wave -noupdate /tx_tb/tx/startBit
add wave -noupdate /tx_tb/tx/dataBit
add wave -noupdate /tx_tb/tx/parityBit
add wave -noupdate /tx_tb/tx/stopBit
add wave -noupdate /tx_tb/tx/bitNum
add wave -noupdate /tx_tb/tx/timer
add wave -noupdate /tx_tb/tx/bitCount
add wave -noupdate /tx_tb/tx/tx_out_int
add wave -noupdate -divider RX
add wave -noupdate /tx_tb/rx_model/clk
add wave -noupdate /tx_tb/rx_model/rx_in
add wave -noupdate /tx_tb/rx_model/rst
add wave -noupdate /tx_tb/rx_model/busy
add wave -noupdate /tx_tb/rx_model/dout
add wave -noupdate /tx_tb/rx_model/r_char
add wave -noupdate /tx_tb/rx_model/parity_calc
add wave -noupdate /tx_tb/rx_model/en_baud_counter
add wave -noupdate /tx_tb/rx_model/rst_baud_counter
add wave -noupdate /tx_tb/rx_model/state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {582 ps}
