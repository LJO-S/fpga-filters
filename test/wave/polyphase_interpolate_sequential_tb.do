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
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/clk
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/i_data
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/i_valid
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/o_ready
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/o_data
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/o_valid
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/coefficient_memory
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/s_phase_state
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_data
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_valid
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_valid_phase
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_valid_out
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_valid_out_d1
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_valid_out_d2
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_delay_line
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_acc
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_acc_shifted
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_acc_clip
add wave -noupdate -group {Polyphase Interpolate} /polyphase_interpolate_sequential_tb/polyphase_interpolate_sequential_inst/r_phase_counter
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {56 ps} 0}
quietly wave cursor active 1
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {38 ps}
