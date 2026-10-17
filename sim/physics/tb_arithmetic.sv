`timescale 1ns/1ps
module tb_arithmetic;
 reg clk=0,rst=1;always #5 clk=~clk;
 reg valid=0,ready=0;reg [7:0] numerator,denominator;
 wire rr,rf,vr,vf,fr,ff;wire [7:0] qr,qf;
 q_udiv_rne #(.W(8)) nearest(clk,rst,valid,rr,numerator,denominator,vr,ready,qr,fr);
 q_udiv_rne #(.W(8),.ROUND_NEAREST(0)) floor_div(clk,rst,valid,rf,numerator,denominator,vf,ready,qf,ff);
 `include "q_numeric_functions.vh"
 reg wide_valid=0,wide_ready=0;reg [95:0] wide_n,wide_d;
 wire ready64,ready96,valid64,valid96,fault64,fault96;wire ready64f,valid64f,fault64f;wire [63:0] result64,result64f;wire [95:0] result96;
 q_udiv_rne #(.W(64)) div64(clk,rst,wide_valid,ready64,wide_n[63:0],wide_d[63:0],valid64,wide_ready,result64,fault64);
 q_udiv_rne #(.W(64),.ROUND_NEAREST(0)) div64_floor(clk,rst,wide_valid,ready64f,wide_n[63:0],wide_d[63:0],valid64f,wide_ready,result64f,fault64f);
 q_udiv_rne #(.W(96)) div96(clk,rst,wide_valid,ready96,wide_n,wide_d,valid96,wide_ready,result96,fault96);
 reg sqrt_valid=0,sqrt_ready=0;reg [127:0] radicand;
 wire sqrt_req_ready,sqrt_rsp_valid,sqrt_inexact;wire [63:0] sqrt_root;
 q_isqrt #(.ROOT_W(64)) sqrt64(clk,rst,sqrt_valid,sqrt_req_ready,radicand,sqrt_rsp_valid,sqrt_ready,sqrt_root,sqrt_inexact);
 task wide_case(input [95:0] numerator_value,input [95:0] denominator_value);
  reg [127:0] wn,wd,wq,wr,answer;
  integer width_case,wait_cycles;
  begin
   while(!ready64 || !ready96 || !ready64f) @(negedge clk);
   wide_n=numerator_value;wide_d=denominator_value;wide_valid=1;@(negedge clk);wide_valid=0;
   wide_n=~wide_n;wide_d=~wide_d;wait_cycles=0;
   while(!valid64 || !valid96 || !valid64f) begin @(negedge clk);wait_cycles++;if(wait_cycles>100) $fatal(1,"wide divider timeout");end
   for(width_case=0;width_case<2;width_case++) begin
    wn=width_case ? numerator_value : numerator_value[63:0];wd=width_case ? denominator_value : denominator_value[63:0];
    if(wd==0) begin
     if(width_case ? (!fault96 || result96!=0) : (!fault64 || result64!=0 || !fault64f || result64f!=0)) $fatal(1,"wide zero divisor");
    end else begin
     wq=wn/wd;wr=wn%wd;answer=wq+((2*wr>wd) || (2*wr==wd && wq[0]));
     if(!width_case && (fault64f || result64f!==wq[63:0])) $fatal(1,"64-bit floor division mismatch");
     if(width_case ? (fault96 || result96!==answer[95:0]) : (fault64 || result64!==answer[63:0])) $fatal(1,"wide RNE mismatch width%0d",width_case ? 96 : 64);
    end
   end
   wide_ready=1;@(negedge clk);wide_ready=0;
  end
 endtask
 task reset_arithmetic;begin
  rst=1;@(negedge clk);rst=0;@(negedge clk);
  if(valid64 || valid96 || valid64f || sqrt_rsp_valid || !ready64 || !ready96 || !ready64f || !sqrt_req_ready) $fatal(1,"arithmetic reset cancellation");
 end endtask
 integer a,b,q,r,expected,cycles,shift,mag,sign_value;
 initial begin
  for(a=-2048;a<2048;a++) for(shift=1;shift<=8;shift++) begin
   mag=a<0 ? -a : a;sign_value=a<0 ? -1 : 1;q=mag/(1<<shift);r=mag%(1<<shift);
   expected=sign_value*(q+((2*r>(1<<shift)) || (2*r==(1<<shift) && q%2)));
   if(q_rne_shift(a,shift)!==expected) $fatal(1,"signed RNE %0d shift%0d",a,shift);
  end
  repeat(3) @(negedge clk);rst=0;
  // Reset during calculation and while results are held, followed each time
  // by a checked correct request (both long production divider widths).
  for(a=0;a<2;a++) begin
   wide_n=96'hffffffffffffffffffffffff;wide_d=3;wide_valid=1;@(negedge clk);wide_valid=0;
   if(a==0) repeat(5) @(negedge clk);else while(!valid64 || !valid96 || !valid64f) @(negedge clk);
   reset_arithmetic();wide_case(96'd15,96'd2);
   radicand=128'd81;sqrt_valid=1;@(negedge clk);sqrt_valid=0;
   if(a==0) repeat(5) @(negedge clk);else while(!sqrt_rsp_valid) @(negedge clk);
   reset_arithmetic();
   radicand=128'd81;sqrt_valid=1;@(negedge clk);sqrt_valid=0;cycles=0;
   while(!sqrt_rsp_valid) begin @(negedge clk);cycles++;if(cycles>66) $fatal(1,"sqrt recovery timeout");end
   if(sqrt_root!=9 || sqrt_inexact) $fatal(1,"sqrt reset recovery result");
   sqrt_ready=1;@(negedge clk);sqrt_ready=0;
  end
  wide_case(96'hffffffffffffffffffffffff,96'h800000000000000000000001);
  wide_case(96'hfffffffffffffffffffffffe,96'h555555555555555555555555);
  wide_case(96'hffffffffffffffffffffffff,96'h000000008000000000000001);
  wide_case(96'h00000000ffffffffffffffff,96'h000000008000000000000001);
  wide_case(96'h00000000fffffffffffffffd,96'h000000007fffffffffffffff);
  // Halfway cases with even/odd retained quotient and a high denominator.
  wide_case(96'h000000005000000000000000,96'h000000002000000000000000);
  wide_case(96'h000000007000000000000000,96'h000000002000000000000000);
  wide_case(96'h500000000000000000000000,96'h200000000000000000000000);
  wide_case(96'h700000000000000000000000,96'h200000000000000000000000);
  wide_case(96'hffffffffffffffffffffffff,96'd1);
  wide_case(96'hffffffffffffffffffffffff,96'd0);
  for(a=0;a<256;a++) for(b=0;b<256;b++) begin
   numerator=a;denominator=b;valid=1;@(negedge clk);valid=0;cycles=0;
   while(!vr || !vf) begin @(negedge clk);cycles++;if(cycles>12) $fatal(1,"divider timeout");end
   if(b==0) begin if(!fr || !ff || qr!=0 || qf!=0) $fatal(1,"zero divisor");end
   else begin
    q=a/b;r=a%b;expected=q+((2*r>b) || (2*r==b && q%2));
    if(fr || ff || qr!=expected || qf!=q) $fatal(1,"divider mismatch %0d/%0d",a,b);
   end
   @(negedge clk);if(rr || rf || !vr || !vf) $fatal(1,"divider stall");
   ready=1;@(negedge clk);ready=0;
  end
  $display("PASS arithmetic: exhaustive 65536 unsigned divisions in both modes; 32768 signed RNE cases; directed 64/96-bit division and divider/sqrt reset recovery");$finish;
 end
 initial begin #10000000;$fatal(1,"arithmetic global timeout");end
endmodule
