`timescale 1ns/1ps
`include "q_contract.vh"
`include "q_body_state.vh"
`include "vector_counts.vh"
module tb_story3;
 `include "q_numeric_functions.vh"
 reg clk=0;always #5 clk=~clk;
 reg rst=1;
 integer i,j,k,n,cycles,bank_cycles=0,max_length=0,max_body=0,max_transform=0,max_motion=0;
 reg [335:0] length_vectors[0:`LENGTH_CASES-1];
 reg [1165:0] body_vectors[0:`BODY_CASES-1];
 reg [971:0] transform_vectors[0:`TRANSFORM_CASES-1];
 reg [309:0] bank_vectors[0:4];
 reg [67:0] trig_vectors[0:`TRIG_CASES-1];
 reg [562:0] motion_vectors[0:`MOTION_CASES-1];
 reg trig_valid=0,trig_ready=0;reg [31:0] trig_phase;wire trig_req_ready,trig_rsp_valid;
 wire signed [17:0] trig_sin,trig_cos;
 q_sincos #(.MEM_FILE("../../rtl/physics/q_sine_q16.mem")) trig_unit(clk,rst,trig_valid,trig_req_ready,trig_phase,trig_rsp_valid,trig_ready,trig_sin,trig_cos);

 task check(input bit okay,input string reason);begin if(!okay) $fatal(1,"%s case %0d",reason,i);end endtask
 reg lv=0,lrsp_ready=0;wire lr,lrv;reg [309:0] ls;wire [23:0] ll;wire ld,lb;
 q_path_length length_unit(clk,rst,lv,lr,ls,lrv,lrsp_ready,ll,ld,lb);
 reg bv=0,brsp_ready=0;wire br,brv,b_reject,b_fault;reg [309:0] bs;
 wire [23:0] bl;wire [31:0] bm,be;wire signed [47:0] bcx,bcy;wire [511:0] bxy;
 wire [63:0] bi;wire [47:0] bim,bii;
 q_body_properties properties(clk,rst,bv,br,bs,brv,brsp_ready,b_reject,b_fault,bl,bm,bcx,bcy,bxy,be,bi,bim,bii);
 reg tv=0,trsp_ready=0;wire tr,trv,tf;reg [3:0] tc;reg signed [17:0] radius;
 reg [511:0] xy;reg signed [47:0] cx,cy;reg [31:0] phase;wire [309:0] result;
 q_transform #(.MEM_FILE("../../rtl/physics/q_sine_q16.mem")) transform_unit(clk,rst,tv,tr,tc,radius,xy,cx,cy,phase,trv,trsp_ready,tf,result);
 reg mv=0,mrsp_ready=0;wire mr,mrv,mf;reg advance=1,ball=0;
 reg signed [47:0] mx=0,my=0;reg signed [39:0] vx=0,vy=0;reg signed [31:0] omega=0;reg [31:0] mp=0,extent=16<<16;
 wire signed [47:0] ox,oy;wire signed [39:0] ovx,ovy;wire signed [31:0] ow;wire [31:0] op;wire [49:0] bound;
 q_integrate integration(clk,rst,mv,mr,advance,ball,mx,my,vx,vy,omega,mp,extent,mrv,mrsp_ready,mf,ox,oy,ovx,ovy,ow,op,bound);
 task motion_request;begin
  while(!mr) @(negedge clk);mv=1;@(negedge clk);mv=0;cycles=0;
  while(!mrv) begin @(negedge clk);cycles++;check(cycles<1000,"motion timeout");end
  if(cycles>max_motion) max_motion=cycles;
 end endtask
 task motion_retire;begin mrsp_ready=1;@(negedge clk);mrsp_ready=0;end endtask
 reg active=1,tick=0,load=0;wire load_ready,busy,commit;
 reg [2:0] load_count=6;reg [`Q_BS_TABLE_W-1:0] seed=0;
 wire [31:0] revision;wire [7:0] faults;wire [2:0] count;
 wire [`Q_BS_TABLE_W-1:0] bank;wire [`Q_BALL_W-1:0] bg;wire [`Q_STROKES_W-1:0] sg;
 reg [`Q_BS_TABLE_W-1:0] prior;
 reg [`Q_BALL_W-1:0] prior_bg;reg [`Q_STROKES_W-1:0] prior_sg;reg [31:0] prior_rev;
 reg static_geometry=0;wire [31:0] ball_mass;wire [63:0] ball_inertia;wire [47:0] ball_im,ball_ii;
 q_ball_properties fixed_properties(static_geometry,ball_mass,ball_inertia,ball_im,ball_ii);
 q_motion_bank #(.MEM_FILE("../../rtl/physics/q_sine_q16.mem")) bank_unit(clk,rst,active,tick,load,load_ready,load_count,seed,busy,commit,revision,faults,count,bank,bg,sg);
 task pulse_tick;begin tick=1;@(negedge clk);tick=0;end endtask
 task wait_commit;begin
  cycles=0;while(!commit) begin @(negedge clk);cycles++;check(cycles<10000,"bank timeout");end
 end endtask
 task reset_helpers;begin
  rst=1;@(negedge clk);rst=0;@(negedge clk);
  check(!brv && !trv && !mrv && br && tr && mr,"reset cancellation/readiness");
 end endtask
 initial begin
  $readmemh("length_vectors.mem",length_vectors);
  $readmemh("body_vectors.mem",body_vectors);
  $readmemh("transform_vectors.mem",transform_vectors);
  $readmemh("bank_geometry.mem",bank_vectors);
  $readmemh("trig_vectors.mem",trig_vectors);
  $readmemh("motion_vectors.mem",motion_vectors);
  repeat(4) @(negedge clk);rst=0;
  check(ball_mass==65536 && ball_inertia==4718592 && ball_im==48'd4294967296 && ball_ii==59652324,"solid disk properties");
  static_geometry=1;@(negedge clk);check(ball_im==0 && ball_ii==0,"static inverse properties");
  for(i=0;i<`LENGTH_CASES;i++) begin
   ls=length_vectors[i][335:26];lv=1;@(negedge clk);lv=0;cycles=0;
   while(!lrv) begin @(negedge clk);cycles++;check(cycles<256,"length timeout");end
   if(cycles>max_length) max_length=cycles;
   check({ll,ld,lb}===length_vectors[i][25:0],"length mismatch");
   // Live input can change while result is blocked, without corrupting it.
   ls=~ls;repeat(3) begin @(negedge clk);check(!lr && lrv && {ll,ld,lb}===length_vectors[i][25:0],"length result stall");end
   lrsp_ready=1;@(negedge clk);lrsp_ready=0;
  end
  // Reset both an active transaction and a blocked result; the golden loop
  // immediately afterwards verifies successful recovery with captured payloads.
  for(j=0;j<2;j++) begin
   bs=body_vectors[0][1165:856];bv=1;@(negedge clk);bv=0;
   if(j==0) repeat(7) @(negedge clk);else begin while(!brv) @(negedge clk);check(!b_reject && !b_fault && {bl,bm,bcx,bcy,bxy,be,bi,bim,bii}===body_vectors[0][855:0],"property processing-reset recovery");end
   reset_helpers();
  end
  for(i=0;i<`BODY_CASES;i++) begin
   bs=body_vectors[i][1165:856];bv=1;@(negedge clk);bv=0;bs=~bs;cycles=0;
   while(!brv) begin @(negedge clk);cycles++;check(cycles<4096,"body timeout");end
   if(cycles>max_body) max_body=cycles;
   check(!b_reject && !b_fault,"property unexpected rejection/fault");
   if({bl,bm,bcx,bcy,bxy,be,bi,bim,bii}!==body_vectors[i][855:0]) begin
    $display("actual len/mass/com/extent/inertia/inv=%h %h %h %h %h %h %h %h",bl,bm,bcx,bcy,be,bi,bim,bii);
    $display("expected=%h",body_vectors[i][855:0]);$fatal(1,"property mismatch case %0d",i);
   end
   repeat(3) begin @(negedge clk);check(brv && !br,"property result stall");end
   brsp_ready=1;@(negedge clk);brsp_ready=0;
  end
  // Short and fully duplicate paths are rejected without reciprocal division.
  for(i=0;i<3;i++) begin
   bs=0;bs[3:0]=2;bs[4+:18]=512;bs[`Q_STROKE_POINT_LSB(1)+:18]=(i==0 ? 1023 : 0);
   if(i==2) bs[3:0]=9;
   bv=1;@(negedge clk);bv=0;cycles=0;
   while(!brv) begin @(negedge clk);cycles++;check(cycles<4096,"reject timeout");end
   check(b_reject && !b_fault && bim==0 && bii==0,"short/duplicate/count rejection");
   brsp_ready=1;@(negedge clk);brsp_ready=0;
  end
  bs=0;bs[3:0]=2;bs[4+:18]=512;
  bs[`Q_STROKE_POINT_LSB(0)+:18]=-18'sd131072;bs[`Q_STROKE_POINT_LSB(0)+18+:18]=-18'sd131072;
  bs[`Q_STROKE_POINT_LSB(1)+:18]=18'sd131071;bs[`Q_STROKE_POINT_LSB(1)+18+:18]=18'sd131071;
  bv=1;@(negedge clk);bv=0;cycles=0;
  while(!brv) begin @(negedge clk);cycles++;check(cycles<4096,"extreme property timeout");end
  check(b_reject && !b_fault,"excess-extent property rejection");brsp_ready=1;@(negedge clk);brsp_ready=0;
  for(i=0;i<`TRIG_CASES;i++) begin
   trig_phase=trig_vectors[i][67:36];trig_valid=1;@(negedge clk);trig_valid=0;trig_phase=~trig_phase;
   cycles=0;while(!trig_rsp_valid) begin @(negedge clk);cycles++;check(cycles<20,"trig timeout");end
   check({trig_sin,trig_cos}===trig_vectors[i][35:0],"complete coefficient RNE/quadrant/last-entry interpolation");
   trig_ready=1;@(negedge clk);trig_ready=0;
  end
  for(j=0;j<2;j++) begin
   {tc,radius,xy,cx,cy,phase}=transform_vectors[0][971:310];tv=1;@(negedge clk);tv=0;
   if(j==0) repeat(4) @(negedge clk);else begin while(!trv) @(negedge clk);check(!tf && result===transform_vectors[0][309:0],"transform processing-reset recovery");end
   reset_helpers();
  end
  for(i=0;i<`TRANSFORM_CASES;i++) begin
   {tc,radius,xy,cx,cy,phase}=transform_vectors[i][971:310];tv=1;@(negedge clk);tv=0;{tc,radius,xy,cx,cy,phase}=~transform_vectors[i][971:310];cycles=0;
   while(!trv) begin @(negedge clk);cycles++;check(cycles<100,"transform timeout");end
   if(cycles>max_transform) max_transform=cycles;
   check(!tf && result===transform_vectors[i][309:0],"transform mismatch");
   repeat(2) begin @(negedge clk);check(trv && !tr && result===transform_vectors[i][309:0],"transform stall");end
   trsp_ready=1;@(negedge clk);trsp_ready=0;
  end
  // First out-of-range Q6 coordinate on either side of the signed interval.
  for(i=0;i<4;i++) begin
   tc=2;radius=512;xy=0;phase=0;
   cx=i<2 ? (i[0] ? -48'sd131073 : 48'sd131072)*262144 : 0;
   cy=i>=2 ? (i[0] ? -48'sd131073 : 48'sd131072)*262144 : 0;
   tv=1;@(negedge clk);tv=0;while(!trv) @(negedge clk);
   check(tf && result==0,"first signed-Q6 transform overflow");trsp_ready=1;@(negedge clk);trsp_ready=0;
  end
  tc=2;radius=512;xy=0;phase=0;cx=48'sd3000<<24;cy=0;tv=1;@(negedge clk);tv=0;
  while(!trv) @(negedge clk);check(tf && result==0,"transform overflow must not return partial geometry");
  trsp_ready=1;@(negedge clk);trsp_ready=0;
  for(j=0;j<2;j++) begin
   mx=0;my=0;vx=0;vy=-1179648;omega=0;mp=0;extent=16<<16;ball=0;
   mv=1;@(negedge clk);mv=0;
   if(j==0) repeat(4) @(negedge clk);else begin while(!mrv) @(negedge clk);check(!mf && ox==0 && oy==0 && ovx==0 && ovy==0 && ow==0 && op==0,"integrator processing-reset recovery");end
   reset_helpers();
  end
  // Each limiter vector uses an independent integer reference, and all live
  // payload fields change immediately after acceptance.
  for(i=0;i<`MOTION_CASES;i++) begin
   {ball,mx,my,vx,vy,omega,mp,extent}=motion_vectors[i][562:290];advance=1;
   while(!mr) @(negedge clk);mv=1;@(negedge clk);mv=0;
   {ball,mx,my,vx,vy,omega,mp,extent}=~motion_vectors[i][562:290];advance=0;
   cycles=0;while(!mrv) begin @(negedge clk);cycles++;check(cycles<400,"limiter reference timeout");end
   check(!mf && {ox,oy,ovx,ovy,ow,op,bound}===motion_vectors[i][289:0],"exact signed limiter state/pose/phase/bound");
   check(ovx!=0 || ovy!=0 || ow!=0,"limiter cannot erase motion");motion_retire();
  end
  advance=1;ball=0;mx=0;my=0;vx=0;vy=0;omega=0;mp=0;extent=16<<16;
  // Exact fractional-gravity trajectory through twenty half-updates from rest.
  for(i=1;i<=20;i++) begin
   motion_request();check(!mf,"gravity fault");
   check(ovy==i*1179648 && oy==589824*i*(i+1)/2 && ox==0,"fractional gravity trajectory");
   mx=ox;my=oy;vx=ovx;vy=ovy;mp=op;motion_retire();
  end
  advance=0;motion_request();check(!mf && ox==mx && oy==my && ovy==vy && op==mp,"unchanged controlled state");motion_retire();advance=1;
  for(i=-3;i<=3;i++) begin
   mx=0;my=0;vx=i;vy=-1179648;omega=0;mp=0;extent=16<<16;ball=0;
   motion_request();
   check(!mf && ox==q_rne_shift(i,1) && oy==0 && ovx==i && ovy==0,"signed half-velocity RNE including negative odd ties");
   motion_retire();
  end
  for(i=0;i<4;i++) begin
   mx=0;my=0;vx=0;vy=-1179648;omega=i[0] ? -1048576 : 1048576;
   mp=i<2 ? 0 : (i[0] ? 32'h00000010 : 32'hfffffff0);extent=16<<16;ball=0;
   motion_request();
   // Independent known value: RNE(1048576*683565276/33554432)=21361415.
   check(!mf && ow==omega && op==32'(mp+(i[0] ? -64'sd21361415 : 64'sd21361415)),"known positive/negative angular phase and wrap");
   motion_retire();
  end
  for(i=0;i<8;i++) begin
   mx=0;my=0;vx=i[0] ? -40'sd549755813888 : 40'sd134217728;
   vy=i[1] ? -40'sd134217728 : 0;omega=i[2] ? -32'sd2147483648 : 32'sd16777216;
   extent=1024<<16;ball=0;motion_request();
   check(!mf && bound<=113246208,"combined translation/rotation clamp");
   check(op==32'(mp+q_rne_shift($signed(ow)*128'sd683565276,25)),"signed angular phase integration");
   check(ovx!=vx && ow!=omega,"coupled limiter must scale both components");motion_retire();
  end
  ball=1;extent=12<<16;vx=0;vy=0;omega=32'sd2147483647;
  motion_request();check(!mf && $signed(ow)*64'sd12<=64'sd134217728,"ball angular cap");motion_retire();
  extent=1049573;omega=8380640;
  motion_request();check(!mf && ow!=omega && (($signed(ow)*64'sd1049573+65535)>>>16)<=134217728,"ball RNE stasis regression");motion_retire();
  ball=0;extent=16<<16;omega=32'sd1048576;vx=0;vy=0;mp=32'hfffffff0;
  motion_request();check(!mf && op==32'(mp+q_rne_shift($signed(ow)*128'sd683565276,25)),"turn phase wrap");motion_retire();
  extent=0;motion_request();check(mf && ox==mx && oy==my && ovx==vx && ow==omega,"numeric fault retains original state");motion_retire();
  // Late position overflow with a valid extent must preserve every field.
  extent=16<<16;mx=48'sh7fffffffffff;my=-48'sd12345;vx=2;vy=-1179648;omega=-123;mp=32'h87654321;
  motion_request();check(mf && ox==mx && oy==my && ovx==vx && ovy==vy && ow==omega && op==mp,"late position overflow full rollback");motion_retire();
  // Seed the maximum six-body controlled table, then verify atomic publication.
  for(j=0;j<6;j++) begin
   seed[j*`Q_BS_W+`Q_BS_RADIUS+:18]=(j==0 ? 768 : 512);
   seed[j*`Q_BS_W+`Q_BS_X+:48]=(100+j*32)*16777216;
   seed[j*`Q_BS_W+`Q_BS_Y+:48]=100*16777216;
   seed[j*`Q_BS_W+`Q_BS_EXTENT+:32]=(j==0 ? 12 : 16)*65536;
   if(j!=0) begin
    seed[j*`Q_BS_W+`Q_BS_COUNT+:4]=8;
    for(k=0;k<8;k++) seed[j*`Q_BS_W+`Q_BS_LOCAL+32*k+:32]=k[0] ? 32'sd524288 : -32'sd524288;
    if(j==1) seed[j*`Q_BS_W+`Q_BS_OMEGA+:32]=1048576;
    if(j==2) seed[j*`Q_BS_W+`Q_BS_OMEGA+:32]=-1048576;
   end
  end
  load=1;@(negedge clk);load=0;wait_commit();check(revision==1 && count==6 && faults==0,"maximum-bank load");
  for(j=0;j<5;j++) check(sg[j*`Q_STROKE_W+:4]==8 && sg[j*`Q_STROKE_W+`Q_STROKE_POINT_LSB(7)+:36]!=0,"eight retained vertices in every stroke");
  prior=bank;prior_bg=bg;prior_sg=sg;prior_rev=revision;
  pulse_tick();while(!commit) begin @(negedge clk);bank_cycles++;if(!commit) check(bank===prior && bg===prior_bg && sg===prior_sg,"partial publication");end
  check(revision==2 && $signed(bank[`Q_BS_VY+:40])==2359296 && $signed(bank[`Q_BS_Y+:48])==100*16777216+1769472,"two-half-update commit");
  check(bank[`Q_BS_W+`Q_BS_PHASE+:32]==42722830 && bank[2*`Q_BS_W+`Q_BS_PHASE+:32]==32'(-64'sd42722830),"committed bank angular poses");
  for(j=0;j<5;j++) check(sg[j*`Q_STROKE_W+:`Q_STROKE_W]===bank_vectors[j],"committed geometry matches translated/rotated pose");
  prior=bank;prior_bg=bg;prior_sg=sg;prior_rev=revision;
  active=0;repeat(5) pulse_tick();check(bank===prior && revision==prior_rev,"paused cadence");active=1;
  pulse_tick();check(busy,"busy start");pulse_tick();repeat(4) @(negedge clk);
  check(!busy && faults[`Q_FAULT_PHYSICS_DEADLINE_BIT] && bank===prior && revision==prior_rev,"busy tick rollback");
  seed[`Q_BS_W+`Q_BS_EXTENT+:32]=8*65536;
  load=1;@(negedge clk);load=0;while(busy) @(negedge clk);
  check(faults[`Q_FAULT_NUMERIC_OVERFLOW_BIT] && bank===prior && revision==prior_rev,"under-declared extent must not load");
  seed[`Q_BS_W+`Q_BS_EXTENT+:32]=16*65536;
  seed[`Q_BS_X+:48]=48'sd3000<<24;load=1;@(negedge clk);load=0;
  while(busy) @(negedge clk);
  check(faults[`Q_FAULT_NUMERIC_OVERFLOW_BIT] && bank===prior && bg===prior_bg && sg===prior_sg && revision==prior_rev,"numeric bank rollback");
  // Exercise nonzero local y and the full Euclidean norm at controlled load.
  seed[`Q_BS_X+:48]=100*16777216;
  for(i=0;i<4;i++) begin
   // First two pass: vertical radius 8 and a 6/8 diagonal inside extent18.
   // Last two fail: y-only radius9 declared16; (6,8) declared17.
   for(k=0;k<8;k++) begin
    seed[`Q_BS_W+`Q_BS_LOCAL+32*k+:32]=(i==0 || i==2 ? 0 : (k[0] ? 6 : -6)*65536);
    seed[`Q_BS_W+`Q_BS_LOCAL+256+32*k+:32]=(k[0] ? 1 : -1)*(i==2 ? 9 : 8)*65536;
   end
   seed[`Q_BS_W+`Q_BS_EXTENT+:32]=(i==1 ? 18 : i==3 ? 17 : 16)*65536;
   prior=bank;prior_bg=bg;prior_sg=sg;prior_rev=revision;
   load=1;@(negedge clk);load=0;cycles=0;
   while(busy) begin @(negedge clk);cycles++;check(cycles<10000,"extent load timeout");end
   if(i<2) check(revision==prior_rev+1 && bank===seed,"valid vertical/diagonal controlled load");
   else check(faults[`Q_FAULT_NUMERIC_OVERFLOW_BIT] && bank===prior && bg===prior_bg && sg===prior_sg && revision==prior_rev && count==6,"y-only/combined-norm rejection retains whole bank");
  end
  prior=bank;
  force bank_unit.revision=32'hffffffff;@(negedge clk);release bank_unit.revision;
  pulse_tick();repeat(3) @(negedge clk);
  check(faults[`Q_FAULT_COUNTER_BIT] && !load_ready && !busy && bank===prior && revision==32'hffffffff,"counter exhaustion quiesces without wrap");
  $display("PASS story3: length=%0d properties=%0d transforms=%0d vectors; max processing cycles length=%0d properties=%0d transform=%0d motion=%0d; six-body outer=%0d",`LENGTH_CASES,`BODY_CASES,`TRANSFORM_CASES,max_length,max_body,max_transform,max_motion,bank_cycles);
  $finish;
 end
 initial begin #100000000;$fatal(1,"global timeout");end
endmodule
