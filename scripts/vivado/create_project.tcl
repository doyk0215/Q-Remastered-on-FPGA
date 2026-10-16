# Usage: vivado -mode batch -source scripts/vivado/create_project.tcl -tclargs JA
# No default header: the physical OLED connection has not been confirmed.
if {[llength $argv] != 1 || [lindex $argv 0] ni {JA JB JC}} {
    error "Usage: create_project.tcl <JA|JB|JC>; explicitly select the wired OLED header"
}
if {[version -short] ne "2025.2"} {
    error "Q Remastered requires Vivado 2025.2; found [version -short]"
}
set q_header [lindex $argv 0]
set q_root [file normalize [file join [file dirname [info script]] ../..]]
set q_build_dir [file join $q_root build]
file mkdir $q_build_dir
create_project -force q_remastered [file join $q_build_dir vivado] -part xc7a35tcpg236-1
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property source_mgmt_mode All [current_project]
set_property include_dirs [list [file join $q_root rtl include]] [get_filesets sources_1]

# Explicit library/language and dependency order; source bytes remain unchanged.
foreach source {
    third_party/supplied/Ps2Interface.vhd
    third_party/supplied/Mouse_Control.vhd
    third_party/supplied/Oled_Display.v
    third_party/projectf/rtl/display_timings.v
    rtl/platform/q_clock_reset.v
    rtl/platform/q_mouse_adapter.v
    rtl/platform/q_oled_adapter.v
    rtl/platform/q_vga_timing.v
    rtl/q_top.v
} {
    set source_path [file join $q_root $source]
    if {![file isfile $source_path]} { error "Missing repository source: $source" }
    add_files -norecurse $source_path
    if {[file extension $source] eq ".vhd"} {
        set_property file_type VHDL [get_files $source_path]
    } else {
        set_property file_type Verilog [get_files $source_path]
    }
}
foreach header {q_contract.vh q_ports.vh q_geometry_params.vh q_physics_params.vh} {
    set header_path [file join $q_root rtl include $header]
    add_files -norecurse $header_path
    set_property file_type {Verilog Header} [get_files $header_path]
}
set_property top q_top [get_filesets sources_1]
# Timing constraints deliberately name the supplied frontend/synchronizer pins.
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
source [file join $q_root scripts vivado create_clocks.tcl]
source [file join $q_root scripts vivado board_pins.tcl]
set q_pin_xdc [file join $q_build_dir basys3_io.xdc]
q_board_pins [file join $q_root third_party supplied Basys3_Master.xdc] $q_pin_xdc $q_header
add_files -fileset constrs_1 -norecurse $q_pin_xdc
set q_timing_xdc [file join $q_root scripts vivado foundation_timing.xdc]
add_files -fileset constrs_1 -norecurse $q_timing_xdc
set_property PROCESSING_ORDER LATE [get_files $q_timing_xdc]
set_property USED_IN_SYNTHESIS false [get_files $q_timing_xdc]
update_compile_order -fileset sources_1
set fp [open [file join $q_build_dir build-selection.txt] w]
puts $fp "vivado=[version -short]\npart=xc7a35tcpg236-1\ntop=q_top\noled_header=$q_header"
close $fp
puts "Created [file join $q_build_dir vivado q_remastered.xpr]; OLED header $q_header (verify physical wiring)."
