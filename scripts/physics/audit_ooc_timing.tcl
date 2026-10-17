# Recheck an existing routed netlist against complete synchronous boundaries.
# This repairs only missing boundary constraints, never timing paths/netlist.
set root [file normalize [file join [file dirname [info script]] ../..]]
set label [lindex $argv 0]
if {$label eq ""} { error "Supply an evidence directory suffix, e.g. q_motion_bank_final2" }
set out [file join $root build story3 synth_$label]
cd $out
open_checkpoint [file join $out routed.dcp]
source [file join $root scripts physics ooc_boundary.tcl]
set boundary [q_ooc_boundary_values [lrange $argv 1 end]]
q_apply_boundary $boundary
q_record_boundary [file join $out boundary_assumptions.txt] $boundary
if {[llength [get_timing_paths -quiet -delay_type max -slack_lesser_than 0 -max_paths 1]] > 0 ||
    [llength [get_timing_paths -quiet -delay_type min -slack_lesser_than 0 -max_paths 1]] > 0} {
    phys_opt_design
    route_design
}
set report [file join $out timing_boundary.rpt]
report_timing_summary -file $report
write_checkpoint -force [file join $out boundary_audited.dcp]
source [file join $root scripts physics assert_timing.tcl]
q_assert_timing_report $report
puts "PASS OOC timing audit: $label (complete coverage; assumed registered boundary)"
