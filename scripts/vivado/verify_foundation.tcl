# Run after create_project.tcl in Vivado 2025.2. No board programming.
set q_root [file normalize [file join [file dirname [info script]] ../..]]
cd $q_root
open_project build/vivado/q_remastered.xpr
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    launch_runs synth_1 -jobs 2
    wait_on_run synth_1
}
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} { error "Synthesis did not complete" }
open_run synth_1
# XDC itself cannot define/call custom Tcl procedures. Check its actual
# endpoints here so missing hierarchy cannot silently pass acceptance.
foreach {q_description q_objects} [list \
    core_clock [get_clocks board_100mhz] \
    pixel_clock [get_clocks -of_objects [get_pins u_clocks/u_pixel_clock/clk_out1]] \
    oled_clock [get_clocks -of_objects [get_pins u_clocks/u_oled_clock/clk_out1]] \
    locked_sync [get_pins -hier -regexp {u_clocks/(pixel|oled)_lock_sync_reg\[0\]/D}] \
    reset_assert [get_pins -hier -regexp {u_clocks/u_(core|pixel|oled)_reset/reset_pipe_reg\[[0-2]\]/PRE}] \
    ps2_capture [get_pins -hier -regexp {u_input/u_mouse/Inst_Ps2Interface/(clk_inter_reg|data_inter_reg|clk_count_reg.*|data_count_reg.*)/D}]] {
    if {[llength $q_objects] == 0} { error "Missing constraint endpoint: $q_description" }
    puts "Q_ENDPOINT $q_description: [llength $q_objects]"
}
report_utilization -file build/synth_utilization.rpt
report_clocks -file build/synth_clocks.rpt
close_design
reset_run impl_1
launch_runs impl_1 -to_step route_design -jobs 2
wait_on_run impl_1
puts "Q_IMPL_STATUS=[get_property STATUS [get_runs impl_1]]"
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} { error "Implementation did not complete" }
open_run impl_1
report_timing_summary -report_unconstrained -file build/timing_summary.rpt
report_drc -file build/drc.rpt
report_clock_interaction -file build/clock_interaction.rpt
report_cdc -file build/cdc.rpt
report_io -file build/io.rpt
puts "Q_VALIDATION_REPORTS=COMPLETE; inspect timing/CDC/DRC before acceptance"
exit
