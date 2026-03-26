onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/clk
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/i_data
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/i_valid
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/o_ready
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/o_data
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/o_valid
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/tb_input_data_float
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/tb_output_data_float
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/tb_auto_set
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/tb_auto_done
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/auto_data_input
add wave -noupdate -group TB /polyphase_interpolate_sequential_tb/auto_data_valid
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/clk
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/i_data
add wave -noupdate -expand -group {Polyphase Interpolate} -format Analog-Step -height 84 -max 16384.0 -min -16384.0 -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/i_data
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/i_valid
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/o_ready
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/o_data
add wave -noupdate -expand -group {Polyphase Interpolate} -format Analog-Step -height 84 -max 16534.0 -min -16851.0 -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/o_data
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/o_valid
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/coefficient_memory
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/s_phase_state
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_data
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_valid
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_valid_out
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_valid_post_proc
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_valid_post_proc_d1
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_valid_post_proc_d2
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_delay_line
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_acc
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_acc_shifted
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_acc_clip
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_phase_counter
add wave -noupdate -expand -group {Polyphase Interpolate} -radix decimal /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/w_ready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 4} {22500 ps} 1} {{Cursor 5} {57500 ps} 1} {{Cursor 6} {56890 ps} 0}
quietly wave cursor active 3
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {5777087 ps} {15223404 ps}
