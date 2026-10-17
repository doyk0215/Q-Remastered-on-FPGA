# Parse-only declaration check; no behavioral RTL synthesis or board access.
set q_root [file normalize [file join [file dirname [info script]] ../..]]
cd $q_root
file mkdir build
set q_check [open build/planning_header_check.v w]
puts $q_check {`include "q_ports.vh"}
puts $q_check {`include "q_parallel_ports_draft.vh"}
puts $q_check {`include "q_ui_layout_draft.vh"}
puts $q_check {`include "q_numeric_params_draft.vh"}
foreach q_role {SOURCE SINK} {
    puts $q_check "module q_draft_${q_role} ("
    puts $q_check {`Q_CORE_PORTS,}
    foreach q_channel {PRESENTATION_EVENT INPUT_CONTEXT DRAW_RETIRE BLOCKED_DRAW PATH_LENGTH_REQ} {
        puts $q_check "`Q_DRAFT_${q_channel}_${q_role}_PORTS,"
    }
    puts $q_check "`Q_DRAFT_PATH_LENGTH_RSP_${q_role}_PORTS"
    puts $q_check ");"
    puts $q_check {localparam CHECK_BUDGET = `Q_DRAFT_INTEGRATION_BUDGET_Q6 + `Q_DRAFT_CORRECTION_BUDGET_Q6 + `Q_DRAFT_TRANSFORM_GUARD_Q6;}
    puts $q_check "endmodule"
}
close $q_check
create_project -in_memory q_draft_declarations -part xc7a35tcpg236-1
set_property include_dirs [list [file join $q_root rtl include]] [get_filesets sources_1]
read_verilog build/planning_header_check.v
set_property top q_draft_SOURCE [get_filesets sources_1]
check_syntax -fileset sources_1
puts "Q_DRAFT_HEADERS_PARSE=PASS"
exit
