vdel -all -lib work
vlib work
vlog quartus_gf28_mult.v
vlog syndrome_calc.v
vlog berlekamp_massey.v
vlog chien_search.v
vlog forney_calc.v
vlog rs_encoder.v
vlog rs_decoder.v
vlog tb_rs_decoder.v
vlog tb_forney_calc.v
vsim -t 1ps work.tb_rs_decoder
do wave.do
run 6600ns
wave zoom full
