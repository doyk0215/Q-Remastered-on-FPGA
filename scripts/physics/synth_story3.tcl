# Isolated out-of-context evidence; does not alter the integration project.
set root [file normalize [file join [file dirname [info script]] ../..]]
set top [lindex $argv 0]
if {$top eq ""} { set top q_motion_bank }
set label [lindex $argv 1]
set suffix [expr {$label eq "" ? "" : "_$label"}]
set out [file join $root build story3 synth_${top}${suffix}]
file mkdir $out
set sources [concat [glob [file join $root rtl common *.v]] [glob [file join $root rtl physics *.v]]]
# Keep all generated Vivado files and its run-relative ROM asset under build/.
file mkdir [file join $out rtl physics]
file copy -force [file join $root rtl physics q_sine_q16.mem] [file join $out rtl physics q_sine_q16.mem]
cd $out
read_verilog $sources
set_property include_dirs [list [file join $root rtl/include] [file join $root rtl/physics]] [current_fileset]
read_xdc [file join $root scripts physics core_ooc.xdc]
source [file join $root scripts physics ooc_boundary.tcl]
set boundary [q_ooc_boundary_values [lrange $argv 2 end]]
q_write_boundary_xdc [file join $out boundary_delays.xdc] $boundary
read_xdc [file join $out boundary_delays.xdc]
synth_design -top $top -part xc7a35tcpg236-1 -mode out_of_context
q_record_boundary [file join $out boundary_assumptions.txt] $boundary
report_utilization -file [file join $out utilization.rpt]
report_timing_summary -file [file join $out timing_synth.rpt]
write_checkpoint -force [file join $out synthesized.dcp]
opt_design
place_design
route_design
report_utilization -file [file join $out utilization_routed.rpt]
report_timing_summary -file [file join $out timing_routed.rpt]
report_drc -file [file join $out drc.rpt]
write_checkpoint -force [file join $out routed.dcp]
source [file join $root scripts physics assert_timing.tcl]
q_assert_timing_report [file join $out timing_routed.rpt]
