quit -sim

.main clear

vlib work

vmap work work

vlog ./../../sources/*.v
vlog ./../*.v

vsim -voptargs=+acc work.top_tb

add wave -divider {bayer2rgb}
add wave /top_tb/u_top/u_bayer2rgb/*

run -all