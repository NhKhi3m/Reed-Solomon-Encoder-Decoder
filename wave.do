onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider SYSTEM
add wave -noupdate /tb_rs_decoder/clk
add wave -noupdate /tb_rs_decoder/rst_n
add wave -noupdate /tb_rs_decoder/enable
add wave -noupdate -divider DATA
add wave -noupdate -radix hexadecimal /tb_rs_decoder/data_in
add wave -noupdate -radix hexadecimal /tb_rs_decoder/encoded_data
add wave -noupdate -radix hexadecimal /tb_rs_decoder/error_mask
add wave -noupdate -radix hexadecimal /tb_rs_decoder/noisy_data
add wave -noupdate -radix unsigned /tb_rs_decoder/decoded_data
add wave -noupdate -divider {PIPELINE CONTROL}
add wave -noupdate /tb_rs_decoder/u_decoder/syn_valid
add wave -noupdate /tb_rs_decoder/u_decoder/bm_done
add wave -noupdate /tb_rs_decoder/u_decoder/chien_done
add wave -noupdate -radix unsigned /tb_rs_decoder/u_decoder/err_count
add wave -noupdate -divider {CHIEN SEARCH}
add wave -noupdate /tb_rs_decoder/u_decoder/u_chien/active
add wave -noupdate -radix unsigned /tb_rs_decoder/u_decoder/u_chien/cycle_cnt
add wave -noupdate /tb_rs_decoder/u_decoder/error_flag
add wave -noupdate -radix unsigned /tb_rs_decoder/u_decoder/u_chien/err_pos
add wave -noupdate -divider {FORNEY CALC}
add wave -noupdate -radix hexadecimal /tb_rs_decoder/u_decoder/u_forney/omega_sum
add wave -noupdate -radix hexadecimal /tb_rs_decoder/u_decoder/u_forney/lambda_prime_sum
add wave -noupdate -radix hexadecimal /tb_rs_decoder/u_decoder/u_forney/error_mag
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3990415 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 283
configure wave -valuecolwidth 40
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
WaveRestoreZoom {3883377 ps} {4246065 ps}
