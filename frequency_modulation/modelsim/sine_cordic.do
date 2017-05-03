onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/reset
add wave -noupdate /testbench/clk
add wave -noupdate -divider <NULL>
add wave -noupdate /testbench/top_inst/k_n
add wave -noupdate /testbench/top_inst/start
add wave -noupdate /testbench/top_inst/control
add wave -noupdate /testbench/top_inst/done
add wave -noupdate -divider <NULL>
add wave -noupdate /testbench/top_inst/beta
add wave -noupdate /testbench/top_inst/beta_array
add wave -noupdate -expand /testbench/top_inst/sine_array
add wave -noupdate /testbench/top_inst/cosine_array
add wave -noupdate /testbench/top_inst/mult_result
add wave -noupdate /testbench/top_inst/result
add wave -noupdate -divider <NULL>
add wave -noupdate /testbench/testcase
add wave -noupdate /testbench/comparison
add wave -noupdate /testbench/result_converted
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {65 ps} 0}
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
WaveRestoreZoom {57 ps} {247 ps}
