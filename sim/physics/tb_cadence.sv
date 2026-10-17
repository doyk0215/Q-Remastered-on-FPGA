`timescale 1ns/1ps
module tb_cadence;
 reg clk=0,rst=1;always #1 clk=~clk;
 wire tick;q_outer_tick dut(clk,rst,tick);
 integer cycle,last=0,ticks=0,short_intervals=0,long_intervals=0;
 initial begin
  @(negedge clk);rst=0;
  for(cycle=1;cycle<=100000000;cycle++) begin
   @(posedge clk);#0.001;
   if(tick) begin
    ticks++;
    if(cycle-last==1666666) short_intervals++;
    else if(cycle-last==1666667) long_intervals++;
    else $fatal(1,"bad cadence interval %0d",cycle-last);
    last=cycle;
   end
  end
  if(ticks!=60 || last!=100000000 || short_intervals!=20 || long_intervals!=40) $fatal(1,"bad full cadence");
  $display("PASS cadence: 60 ticks/100000000 cycles; 20 intervals of 1666666, 40 intervals of 1666667");
  $finish;
 end
endmodule
