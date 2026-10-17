# Consume Vivado's check_timing summary, failing closed if coverage is missing.
proc q_assert_timing_report {report_path} {
    set handle [open $report_path r]
    set text [read $handle]
    close $handle
    foreach check {no_clock unconstrained_internal_endpoints no_input_delay no_output_delay} {
        set pattern [format {checking %s \(([0-9]+)\)} $check]
        if {![regexp $pattern $text ignored count]} {
            error "Missing timing-coverage check $check in $report_path"
        }
        if {$count != 0} { error "Timing coverage failed: $check=$count in $report_path" }
    }
    q_report_internal_timing [file dirname $report_path]
    if {[llength [get_timing_paths -quiet -delay_type max -slack_lesser_than 0 -max_paths 1]] > 0} {
        error "Isolated setup timing failed; inspect $report_path"
    }
    if {[llength [get_timing_paths -quiet -delay_type min -slack_lesser_than 0 -max_paths 1]] > 0} {
        error "Isolated hold timing failed; inspect $report_path"
    }
}
proc q_report_internal_timing {out} {
    set registers [all_registers]
    set handle [open [file join $out internal_slack.txt] w]
    foreach delay {max min} name {setup hold} {
        set paths [get_timing_paths -quiet -from $registers -to $registers -delay_type $delay -max_paths 1]
        if {[llength $paths] == 0} { close $handle; error "No internal register-to-register $name paths found" }
        set slack [get_property SLACK [lindex $paths 0]]
        puts $handle "Internal register-to-register $name slack: $slack ns"
        report_timing -from $registers -to $registers -delay_type $delay -max_paths 10 -file [file join $out timing_internal_$name.rpt]
    }
    close $handle
}
