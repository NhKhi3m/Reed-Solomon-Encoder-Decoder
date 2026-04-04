onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_rs_encoder/clk
add wave -noupdate /tb_rs_encoder/rst_n
add wave -noupdate /tb_rs_encoder/enable
add wave -noupdate /tb_rs_encoder/data_in
add wave -noupdate /tb_rs_encoder/data_out
add wave -noupdate /tb_rs_encoder/valid_out
add wave -noupdate /tb_rs_encoder/i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2239641 ps} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {2198008 ps} {2303534 ps}
