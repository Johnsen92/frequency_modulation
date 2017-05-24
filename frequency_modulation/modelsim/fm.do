onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench_fm/in_r
add wave -noupdate /testbench_fm/fm/sample_flag
add wave -noupdate /testbench_fm/out_r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{0 1} {1295310000 ps} 1} {{0 2} {1545230000 ps} 1} {{0 3} {1795150000 ps} 1} {{0 4} {2045070000 ps} 1} {{.75 1} {2340430000 ps} 1} {{.75 2} {2476750000 ps} 1} {{.75 3} {2635790000 ps} 1} {{.75 4} {2772110000 ps} 1} {{-.75 1} {3044750000 ps} 1} {{-.75 2} {4044430000 ps} 1} {{-.75 3} {5044110000 ps} 1} {{-.75 4} {6043790000 ps} 1}
quietly wave cursor active 12
configure wave -namecolwidth 103
configure wave -valuecolwidth 96
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
WaveRestoreZoom {3414027737 ps} {8431060601 ps}
