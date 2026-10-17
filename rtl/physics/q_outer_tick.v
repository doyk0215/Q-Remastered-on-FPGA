`include "q_contract.vh"
// Rational clock enable. Reset starts a fresh cadence; no generated clock.
module q_outer_tick(
 input wire clk,input wire rst,output reg tick
);
 reg [26:0] accumulator;
 wire [26:0] next=accumulator+`Q_PHYSICS_HZ;
 always @(posedge clk) begin
  if(rst) begin accumulator<=0;tick<=0;end
  else if(next>=`Q_CORE_HZ) begin accumulator<=next-`Q_CORE_HZ;tick<=1;end
  else begin accumulator<=next;tick<=0;end
 end
endmodule
