# Generate active constraints by extracting the supplied, unchanged pin baseline.
proc q_board_pins {baseline destination header} {
    if {$header ni {JA JB JC}} { error "OLED header must be explicitly JA, JB or JC" }
    set fp [open $baseline r]
    set text [read $fp]
    close $fp
    set pins [dict create]
    foreach line [split $text \n] {
        if {[regexp {^#set_property -dict .*PACKAGE_PIN ([A-Z]+[0-9]+)} $line -> pin] &&
            [regexp {\[get_ports (.+)\]} $line -> port]} {
            set port [string trim $port "{} "]
            dict set pins $port $pin
        }
    }
    set mappings [list clk clk_100mhz Hsync vga_hsync Vsync vga_vsync \
        PS2Clk ps2_clk PS2Data ps2_data]
    foreach {old new count} {vgaRed vga_red 4 vgaGreen vga_green 4 vgaBlue vga_blue 4 led led 16} {
        for {set i 0} {$i < $count} {incr i} {
            lappend mappings [format {%s[%d]} $old $i] [format {%s[%d]} $new $i]
        }
    }
    # Header indices 0,1,2,3,4,5,6,7 are Pmod physical 1,2,3,4,7,8,9,10.
    # Physical pin 3 (NC) intentionally has no top-level port, buffer or pin drive.
    foreach {index port} {0 oled_cs 1 oled_mosi 3 oled_sck 4 oled_dc 5 oled_resn 6 oled_vccen 7 oled_pmoden} {
        lappend mappings [format {%s[%d]} $header $index] $port
    }
    file mkdir [file dirname $destination]
    set fp [open $destination w]
    puts $fp "# Generated from third_party/supplied/Basys3_Master.xdc; OLED=$header"
    foreach {source port} $mappings {
        if {![dict exists $pins $source]} { close $fp; error "Missing baseline pin: $source" }
        puts $fp [format {set_property -dict {PACKAGE_PIN %s IOSTANDARD LVCMOS33} [get_ports {%s}]} [dict get $pins $source] $port]
    }
    puts $fp {set_property PULLUP true [get_ports {ps2_clk ps2_data}]}
    puts $fp {create_clock -name board_100mhz -period 10.000 [get_ports clk_100mhz]}
    puts $fp {set_property CONFIG_VOLTAGE 3.3 [current_design]}
    puts $fp {set_property CFGBVS VCCO [current_design]}
    puts $fp {set_property BITSTREAM.CONFIG.UNUSEDPIN Pullnone [current_design]}
    close $fp
}
