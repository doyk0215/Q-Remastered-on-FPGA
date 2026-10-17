# Explicit characterization assumptions, never the integrated same-core budget.
proc q_ooc_boundary_values {overrides} {
    set values {1.5 2.5 0.5 2.5}
    if {[llength $overrides] > 4} { error "Supply at most input-min input-max output-min output-max (ns)" }
    for {set i 0} {$i < [llength $overrides]} {incr i} { lset values $i [lindex $overrides $i] }
    foreach value $values {
        if {![string is double -strict $value] || $value < 0 || $value >= 10} { error "OOC arrivals/budgets must be numeric in 0..10 ns" }
    }
    lassign $values imin imax omin omax
    if {$imin > $imax || $omin > $omax} { error "OOC minimum must not exceed maximum" }
    return $values
}
proc q_write_boundary_xdc {path values} {
    lassign $values imin imax omin omax
    set handle [open $path w]
    puts $handle [format {set_input_delay -min %s -clock core [get_ports -filter {DIRECTION == IN && NAME != clk}]} $imin]
    puts $handle [format {set_input_delay -max %s -clock core [get_ports -filter {DIRECTION == IN && NAME != clk}]} $imax]
    puts $handle [format {set_output_delay -min %s -clock core [all_outputs]} $omin]
    puts $handle [format {set_output_delay -max %s -clock core [all_outputs]} $omax]
    close $handle
}
proc q_apply_boundary {values} {
    lassign $values imin imax omin omax
    set_input_delay -min $imin -clock core [get_ports -filter {DIRECTION == IN && NAME != clk}]
    set_input_delay -max $imax -clock core [get_ports -filter {DIRECTION == IN && NAME != clk}]
    set_output_delay -min $omin -clock core [all_outputs]
    set_output_delay -max $omax -clock core [all_outputs]
}
proc q_record_boundary {path values} {
    if {[get_property PERIOD [get_clocks core]] != 10.0} { error "The core period must remain 10 ns" }
    lassign $values imin imax omin omax
    set handle [open $path w]
    puts $handle "Assumed isolated synchronous boundary; core period 10 ns."
    puts $handle "Input arrival min=$imin max=$imax ns; output delay min=$omin max=$omax ns."
    puts $handle "Actual top integration must replace these with real same-core drivers and timing."
    close $handle
}
