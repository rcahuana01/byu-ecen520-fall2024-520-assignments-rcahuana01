onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider debouncer
add wave -noupdate /tx_top_tb/tx_top/debouncer/clk
add wave -noupdate /tx_top_tb/tx_top/debouncer/rst
add wave -noupdate /tx_top_tb/tx_top/debouncer/async_in
add wave -noupdate /tx_top_tb/tx_top/debouncer/debounce_out
add wave -noupdate /tx_top_tb/tx_top/debouncer/timerDone
add wave -noupdate /tx_top_tb/tx_top/debouncer/clrTimer
add wave -noupdate /tx_top_tb/tx_top/debouncer/async_in1
add wave -noupdate /tx_top_tb/tx_top/debouncer/async_in2
add wave -noupdate /tx_top_tb/tx_top/debouncer/counter
add wave -noupdate /tx_top_tb/tx_top/debouncer/ns
add wave -noupdate /tx_top_tb/tx_top/debouncer/cs
add wave -noupdate -divider TX_TOP
add wave -noupdate /tx_top_tb/tx_top/CLK100MHZ
add wave -noupdate /tx_top_tb/tx_top/CPU_RESETN
add wave -noupdate /tx_top_tb/tx_top/SW
add wave -noupdate /tx_top_tb/tx_top/BTNC
add wave -noupdate /tx_top_tb/tx_top/LED
add wave -noupdate /tx_top_tb/tx_top/UART_RXD_OUT
add wave -noupdate /tx_top_tb/tx_top/LED16_B
add wave -noupdate /tx_top_tb/tx_top/debounce
add wave -noupdate /tx_top_tb/tx_top/debounce_out
add wave -noupdate /tx_top_tb/tx_top/debounce_out1
add wave -noupdate /tx_top_tb/tx_top/debounce_out2
add wave -noupdate /tx_top_tb/tx_top/SW_sync
add wave -noupdate /tx_top_tb/tx_top/rst1
add wave -noupdate /tx_top_tb/tx_top/rst2
add wave -noupdate /tx_top_tb/tx_top/tx_busy
add wave -noupdate /tx_top_tb/tx_top/tx_out_int
add wave -noupdate /tx_top_tb/tx_top/one_press
add wave -noupdate -divider RX_MODEL
add wave -noupdate /tx_top_tb/rx_model/clk
add wave -noupdate /tx_top_tb/rx_model/rx_in
add wave -noupdate /tx_top_tb/rx_model/rst
add wave -noupdate /tx_top_tb/rx_model/busy
add wave -noupdate /tx_top_tb/rx_model/dout
add wave -noupdate /tx_top_tb/rx_model/r_char
add wave -noupdate /tx_top_tb/rx_model/parity_calc
add wave -noupdate /tx_top_tb/rx_model/en_baud_counter
add wave -noupdate /tx_top_tb/rx_model/rst_baud_counter
add wave -noupdate /tx_top_tb/rx_model/state
add wave -noupdate -divider TX
add wave -noupdate /tx_top_tb/tx_top/transmitter/clk
add wave -noupdate /tx_top_tb/tx_top/transmitter/rst
add wave -noupdate /tx_top_tb/tx_top/transmitter/send
add wave -noupdate /tx_top_tb/tx_top/transmitter/din
add wave -noupdate /tx_top_tb/tx_top/transmitter/busy
add wave -noupdate /tx_top_tb/tx_top/transmitter/tx_out
add wave -noupdate /tx_top_tb/tx_top/transmitter/ns
add wave -noupdate /tx_top_tb/tx_top/transmitter/cs
add wave -noupdate /tx_top_tb/tx_top/transmitter/clrTimer
add wave -noupdate /tx_top_tb/tx_top/transmitter/timerDone
add wave -noupdate /tx_top_tb/tx_top/transmitter/clrBit
add wave -noupdate /tx_top_tb/tx_top/transmitter/incBit
add wave -noupdate /tx_top_tb/tx_top/transmitter/bitDone
add wave -noupdate /tx_top_tb/tx_top/transmitter/bitNum
add wave -noupdate /tx_top_tb/tx_top/transmitter/timer
add wave -noupdate /tx_top_tb/tx_top/transmitter/tx_out_int
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {61465000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 197
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
configure wave -timelineunits ps
update
WaveRestoreZoom {61388608 ps} {61541393 ps}
