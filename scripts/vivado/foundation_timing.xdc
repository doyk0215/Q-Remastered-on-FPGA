# Read late, after clock-wizard XDC. Wizard MMCM/BUFG outputs supply generated
# clocks automatically. All domains retain their relationship to board_100mhz;
# there is deliberately no set_clock_groups or all-register false path.
# XDC permits only a subset of Tcl; endpoint assertions belong in the
# validation script, not in a custom procedure embedded in this file.
set q_core_clock [get_clocks board_100mhz]
set q_pix_clock [get_clocks -of_objects [get_pins u_clocks/u_pixel_clock/clk_out1]]
set q_oled_clock [get_clocks -of_objects [get_pins u_clocks/u_oled_clock/clk_out1]]

# Board-level budgets, pending electrical/board evidence: 5 ns VGA, 10 ns OLED.
# OLED's internal rising-edge pixel register -> falling-edge driver capture
# remains timed as a normal half-cycle path (80 ns); never false-path that bus.
set q_vga_ports [get_ports {vga_red[*] vga_green[*] vga_blue[*] vga_hsync vga_vsync}]
set q_oled_ports [get_ports {oled_cs oled_mosi oled_sck oled_dc oled_resn oled_vccen oled_pmoden}]
set_output_delay -clock $q_pix_clock -max 5.000 $q_vga_ports
set_output_delay -clock $q_pix_clock -min 0.000 $q_vga_ports
set_output_delay -clock $q_oled_clock -clock_fall -max 10.000 $q_oled_ports
set_output_delay -clock $q_oled_clock -clock_fall -min 0.000 $q_oled_ports

# LOCKED is asynchronous to the board-clock recovery supervisor. Only its first
# sampling flop is exempt; second stages remain timed and carry ASYNC_REG.
set q_lock_first [get_pins -hier -regexp {u_clocks/(pixel|oled)_lock_sync_reg\[0\]/D}]
set_false_path -to $q_lock_first
# Async assertion to the three reset synchronizers is intentional. Their
# synchronous release and downstream reset recovery/removal remain timed.
set q_reset_assert [get_pins -hier -regexp {u_clocks/u_(core|pixel|oled)_reset/reset_pipe_reg\[[0-2]\]/PRE}]
set_false_path -to $q_reset_assert

# Supplied PS/2 frontend samples asynchronous, open-drain lines into its
# deglitch capture/counter logic, then synchronizes the debounced signals.
# Scope the exemption to those frontend D pins, preserving all later timing.
set q_ps2_capture [get_pins -hier -regexp {u_input/u_mouse/Inst_Ps2Interface/(clk_inter_reg|data_inter_reg|clk_count_reg.*|data_count_reg.*)/D}]
set_false_path -from [get_ports {ps2_clk ps2_data}] -to $q_ps2_capture
# Host-to-mouse outputs are asynchronous protocol controls, bounded locally to
# 10 ns routing/logic delay; there is no external synchronous receiver clock.
set_max_delay -datapath_only 10.000 -from [all_registers -clock $q_core_clock] -to [get_ports {ps2_clk ps2_data}]
