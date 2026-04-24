onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group TB /cic_interpolate_sequential_tb/clk
add wave -noupdate -group TB /cic_interpolate_sequential_tb/i_data
add wave -noupdate -group TB /cic_interpolate_sequential_tb/i_valid
add wave -noupdate -group TB /cic_interpolate_sequential_tb/o_ready
add wave -noupdate -group TB /cic_interpolate_sequential_tb/o_data
add wave -noupdate -group TB /cic_interpolate_sequential_tb/o_valid
add wave -noupdate -group TB /cic_interpolate_sequential_tb/tb_input_data_float
add wave -noupdate -group TB /cic_interpolate_sequential_tb/tb_output_data_float
add wave -noupdate -group TB /cic_interpolate_sequential_tb/tb_auto_set
add wave -noupdate -group TB /cic_interpolate_sequential_tb/tb_auto_done
add wave -noupdate -group TB /cic_interpolate_sequential_tb/auto_data_input
add wave -noupdate -group TB /cic_interpolate_sequential_tb/auto_data_valid
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/clk
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/i_data
add wave -noupdate -expand -group {CIC Intepolate} -expand -group Analog -format Analog-Step -height 84 -max 16384.0 -min -16384.0 -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/i_data
add wave -noupdate -expand -group {CIC Intepolate} -expand -group Analog -format Analog-Step -height 84 -min -25783.0 -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/o_data
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/i_valid
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/o_ready
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/o_data
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/o_valid
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_ready_out
add wave -noupdate -expand -group {CIC Intepolate} -radix unsigned /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_ready_counter
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/w_fir_data_in
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/w_fir_valid_in
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_integrator_sum_array
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_integrator_valid_slv
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_comb_delay_array
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_comb_diff_array
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_comb_valid_slv
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_interpolate_counter
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_interpolate_data
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_interpolate_valid
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_norm_data
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/r_norm_valid
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/w_fir_comp_data_out
add wave -noupdate -expand -group {CIC Intepolate} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/w_fir_comp_valid_out
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/clk
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/i_data
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/i_valid
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/o_data
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/o_valid
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/coefficient_memory
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/r_delay_line
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/r_dlyline_valid
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/r_dlyline_shifted
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/r_valid_post_proc
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/r_acc_clip
add wave -noupdate -expand -group {FIR Compensation Filter} -radix decimal /cic_interpolate_sequential_tb/cic_interpolate_sequential_inst/fir_compensation_filter_inst/r_valid_post_proc_d1
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {37224 ps} 0}
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {134445 ps}
