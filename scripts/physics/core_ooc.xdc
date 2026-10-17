# Fixed internal core clock. synth_story3.tcl generates configurable assumed
# boundary delays (default input1.5..2.5ns, output0.5..2.5ns) under build/.
create_clock -name core -period 10.000 [get_ports clk]
