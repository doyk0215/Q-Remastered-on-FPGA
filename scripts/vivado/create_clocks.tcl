# Sourced after project creation. Generated .xci and build settings stay in build/.
# Two MMCMs avoid assuming that one legal VCO can supply both exact rates.
proc q_create_clock {name frequency multiplier divider output_divider} {
    create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 \
        -module_name $name -dir [file join $::q_build_dir ip]
    set_property -dict [list \
        CONFIG.PRIMITIVE {MMCM} \
        CONFIG.PRIM_SOURCE {No_buffer} \
        CONFIG.PRIM_IN_FREQ {100.000} \
        CONFIG.CLKIN1_JITTER_PS {100.0} \
        CONFIG.NUM_OUT_CLKS {1} \
        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $frequency \
        CONFIG.CLKOUT1_DRIVES {BUFG} \
        CONFIG.USE_LOCKED {true} \
        CONFIG.USE_RESET {true} \
        CONFIG.RESET_TYPE {ACTIVE_HIGH} \
        CONFIG.MMCM_CLKFBOUT_MULT_F $multiplier \
        CONFIG.MMCM_DIVCLK_DIVIDE $divider \
        CONFIG.MMCM_CLKOUT0_DIVIDE_F $output_divider \
    ] [get_ips $name]
    generate_target all [get_ips $name]
    set ip [get_ips $name]
    set actual [expr {100.0 * [get_property CONFIG.MMCM_CLKFBOUT_MULT_F $ip] / \
        [get_property CONFIG.MMCM_DIVCLK_DIVIDE $ip] / \
        [get_property CONFIG.MMCM_CLKOUT0_DIVIDE_F $ip]}]
    if {abs($actual - $frequency) > 0.000001} {
        error "$name resolved to $actual MHz, expected exactly $frequency MHz"
    }
    # Retain the resolved configuration as plain Tcl beside the generated XCI.
    set fp [open [file join $::q_build_dir ${name}-resolved.txt] w]
    puts $fp [report_property -return_string [get_ips $name]]
    close $fp
}
# VCO = 630 MHz; 630/25 = 25.2 MHz. VCO = 800 MHz; 800/128 = 6.25 MHz.
q_create_clock q_clk_pixel 25.200 31.500 5 25.000
q_create_clock q_clk_oled 6.250 8.000 1 128.000
