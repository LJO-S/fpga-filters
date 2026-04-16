onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group TB /halfband_decimate_tb/clk
add wave -noupdate -group TB /halfband_decimate_tb/i_data
add wave -noupdate -group TB /halfband_decimate_tb/i_valid
add wave -noupdate -group TB /halfband_decimate_tb/o_data
add wave -noupdate -group TB /halfband_decimate_tb/o_valid
add wave -noupdate -group TB /halfband_decimate_tb/tb_input_data_float
add wave -noupdate -group TB /halfband_decimate_tb/tb_output_data_float
add wave -noupdate -group TB /halfband_decimate_tb/tb_auto_set
add wave -noupdate -group TB /halfband_decimate_tb/tb_auto_done
add wave -noupdate -group TB /halfband_decimate_tb/auto_data_input
add wave -noupdate -group TB /halfband_decimate_tb/auto_data_valid
add wave -noupdate -expand -group {Halfband Decimate} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/clk
add wave -noupdate -expand -group {Halfband Decimate} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/i_data
add wave -noupdate -expand -group {Halfband Decimate} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/i_valid
add wave -noupdate -expand -group {Halfband Decimate} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/o_data
add wave -noupdate -expand -group {Halfband Decimate} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/o_valid
add wave -noupdate -expand -group {Halfband Decimate} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/w_stage_data_in
add wave -noupdate -expand -group {Halfband Decimate} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/w_stage_valid_in
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/clk
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/i_data
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/i_valid
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/o_data
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/o_valid
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/coefficient_memory
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_data_upper
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_data_lower
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_sel
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_valid
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_delay_line_upper
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_delay_line_lower
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_dlyline_valid
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_acc
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_acc_shifted
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_postproc_valid
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_postproc_valid_d1
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_postproc_valid_d2
add wave -noupdate -group {Stage 0} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(0)/halfband_decimate_stage_inst/r_acc_clip
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/clk
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/i_data
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/i_valid
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/o_data
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/o_valid
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/coefficient_memory
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_data_upper
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_data_lower
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_sel
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_valid
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_delay_line_upper
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_delay_line_lower
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_dlyline_valid
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_acc
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_acc_shifted
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_postproc_valid
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_postproc_valid_d1
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_postproc_valid_d2
add wave -noupdate -group {Stage 1} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(1)/halfband_decimate_stage_inst/r_acc_clip
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/clk
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/i_data
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/i_valid
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/o_data
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/o_valid
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/coefficient_memory
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_data_upper
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_data_lower
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_sel
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_valid
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_delay_line_upper
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_delay_line_lower
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_dlyline_valid
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_acc
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_acc_shifted
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_postproc_valid
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_postproc_valid_d1
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_postproc_valid_d2
add wave -noupdate -group {Stage 2} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(2)/halfband_decimate_stage_inst/r_acc_clip
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/clk
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/i_data
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/i_valid
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/o_data
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/o_valid
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/coefficient_memory
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_data_upper
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_data_lower
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_sel
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_valid
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_delay_line_upper
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_delay_line_lower
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_dlyline_valid
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_acc
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_acc_shifted
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_postproc_valid
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_postproc_valid_d1
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_postproc_valid_d2
add wave -noupdate -group {Stage 3} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(3)/halfband_decimate_stage_inst/r_acc_clip
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/clk
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/i_data
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/i_valid
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/o_data
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/o_valid
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/coefficient_memory
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_data_upper
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_data_lower
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_sel
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_valid
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_delay_line_upper
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_delay_line_lower
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_dlyline_valid
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_acc
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_acc_shifted
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_postproc_valid
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_postproc_valid_d1
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_postproc_valid_d2
add wave -noupdate -group {Stage 4} -radix decimal /halfband_decimate_tb/halfband_decimate_inst/g_generate_interpolate_stage(4)/halfband_decimate_stage_inst/r_acc_clip
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {162500 ps} 1} {{Cursor 2} {7500 ps} 1} {{Cursor 3} {42500 ps} 0}
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
WaveRestoreZoom {0 ps} {269681 ps}
