`include "q_contract.vh"
`include "q_geometry_params.vh"
`include "q_numeric_params_draft.vh"
`include "q_body_state.vh"
// Isolated controlled foundation: two half-updates over up to six bodies.
// The integration owner must insert Story 4 contact work between each half-step
// before using this scheduler for gameplay. No collision/admission is claimed.
// A busy eligible tick cancels all staged work and retains the complete bank.
module q_motion_bank #(parameter MEM_FILE="rtl/physics/q_sine_q16.mem")(
 input wire clk,input wire rst,input wire active,input wire outer_tick,
 input wire load_valid,output wire load_ready,
 input wire [2:0] load_body_count,input wire [`Q_BS_TABLE_W-1:0] load_bodies,
 output reg busy,output reg commit,
 output reg [31:0] revision,output reg [`Q_FAULT_W-1:0] fault_flags,
 output reg [2:0] body_count,output reg [`Q_BS_TABLE_W-1:0] bodies,
 output reg [`Q_BALL_W-1:0] ball_geometry,
 output reg [`Q_STROKES_W-1:0] stroke_geometry
);
 `include "q_numeric_functions.vh"
 localparam IDLE=0,IREQ=1,IWAIT=2,TREQ=3,TWAIT=4,NEXT=5,PUBLISH=6,DRAIN=7,VREQ=8,VWAIT=9,BROUND=10,BCHECK=11;
 reg [3:0] state;
 reg [2:0] index,count;
 reg half,loading,invalidated;
 reg [`Q_BS_W-1:0] staged[0:5];
 reg [`Q_BALL_W-1:0] staged_ball;
 reg [`Q_STROKE_W-1:0] staged_strokes[0:4];
 wire [`Q_BS_W-1:0] selected=staged[index];
 wire ir,iv,ifault;
 wire signed [47:0] ix,iy;
 wire signed [39:0] ivx,ivy;
 wire signed [31:0] iw;
 wire [31:0] ip;
 wire [49:0] ibound;
 // Local reset cancels helper transactions on a missed deadline/load failure.
 wire helpers_reset=rst || state==DRAIN;
 q_integrate integrator(clk,helpers_reset,state==IREQ,ir,1'b1,index==0,
  $signed(selected[`Q_BS_X+:48]),$signed(selected[`Q_BS_Y+:48]),
  $signed(selected[`Q_BS_VX+:40]),$signed(selected[`Q_BS_VY+:40]),
  $signed(selected[`Q_BS_OMEGA+:32]),selected[`Q_BS_PHASE+:32],selected[`Q_BS_EXTENT+:32],
  iv,state==IWAIT,ifault,ix,iy,ivx,ivy,iw,ip,ibound);
 wire tr,tv,tfault;
 wire [`Q_STROKE_W-1:0] transformed;
 q_transform #(.MEM_FILE(MEM_FILE)) transformer(clk,helpers_reset,state==TREQ && index!=0,tr,
  selected[`Q_BS_COUNT+:4],$signed(selected[`Q_BS_RADIUS+:18]),selected[`Q_BS_LOCAL+:512],
  $signed(selected[`Q_BS_X+:48]),$signed(selected[`Q_BS_Y+:48]),selected[`Q_BS_PHASE+:32],
  tv,state==TWAIT,tfault,transformed);
 wire er,ev,ef;
 q_extent_check extent_validator(clk,helpers_reset,state==VREQ,er,
  selected[`Q_BS_COUNT+:4],$signed(selected[`Q_BS_RADIUS+:18]),selected[`Q_BS_EXTENT+:32],selected[`Q_BS_LOCAL+:512],
  ev,state==VWAIT,ef);
 reg signed [29:0] qx,qy;
 wire signed [47:0] selected_x=$signed(staged[0][`Q_BS_X+:48]);
 wire signed [47:0] selected_y=$signed(staged[0][`Q_BS_Y+:48]);
 integer k;
 assign load_ready=state==IDLE && !busy && revision!=32'hffffffff && !fault_flags[`Q_FAULT_COUNTER_BIT];
 always @(posedge clk) begin
  if(rst) begin
   busy<=0;commit<=0;revision<=0;fault_flags<=0;body_count<=0;bodies<=0;ball_geometry<=0;stroke_geometry<=0;
   state<=IDLE;index<=0;count<=0;half<=0;loading<=0;invalidated<=0;staged_ball<=0;
   qx<=0;qy<=0;
   for(k=0;k<6;k=k+1) staged[k]<=0;
   for(k=0;k<5;k=k+1) staged_strokes[k]<=0;
  end else begin
   commit<=0;
   if(outer_tick && active && busy) begin
    fault_flags[`Q_FAULT_PHYSICS_DEADLINE_BIT]<=1;invalidated<=1;state<=DRAIN;
   end else case(state)
    IDLE:begin
     if(revision==32'hffffffff) fault_flags[`Q_FAULT_COUNTER_BIT]<=1;
     else if(load_valid && load_ready) begin
      if(load_body_count<1 || load_body_count>6) fault_flags[`Q_FAULT_NUMERIC_OVERFLOW_BIT]<=1;
      else begin
       for(k=0;k<6;k=k+1) staged[k]<=k<load_body_count ? load_bodies[k*`Q_BS_W+:`Q_BS_W] : {`Q_BS_W{1'b0}};
       for(k=0;k<5;k=k+1) staged_strokes[k]<=0;
       count<=load_body_count;index<=0;half<=1;loading<=1;invalidated<=0;busy<=1;staged_ball<=0;state<=TREQ;
      end
     end else if(outer_tick && active && body_count!=0) begin
      for(k=0;k<6;k=k+1) staged[k]<=bodies[k*`Q_BS_W+:`Q_BS_W];
      count<=body_count;index<=0;half<=0;loading<=0;invalidated<=0;busy<=1;state<=IREQ;
     end
    end
    IREQ:if(ir) state<=IWAIT;
    IWAIT:if(iv) begin
     if(ifault) begin fault_flags[`Q_FAULT_NUMERIC_OVERFLOW_BIT]<=1;state<=DRAIN;end
     else begin
      staged[index][`Q_BS_X+:48]<=ix;staged[index][`Q_BS_Y+:48]<=iy;
      staged[index][`Q_BS_VX+:40]<=ivx;staged[index][`Q_BS_VY+:40]<=ivy;
      staged[index][`Q_BS_OMEGA+:32]<=iw;staged[index][`Q_BS_PHASE+:32]<=ip;state<=TREQ;
     end
    end
    TREQ:begin
     if(selected[`Q_BS_EXTENT+:32]==0 || selected[`Q_BS_EXTENT+:32]>(32'd1*`Q_DRAFT_MAX_EXTENT_PIX<<16) ||
        selected[`Q_BS_EXTENT+:32]<((index==0 ? 32'd1*`Q_BALL_RADIUS_PIX : 32'd1*`Q_STROKE_RADIUS_PIX)<<16) ||
        (index==0 && $signed(selected[`Q_BS_RADIUS+:18])!=`Q_BALL_RADIUS_Q6) ||
        (index!=0 && $signed(selected[`Q_BS_RADIUS+:18])!=`Q_STROKE_RADIUS_Q6)) begin
      fault_flags[`Q_FAULT_NUMERIC_OVERFLOW_BIT]<=1;state<=DRAIN;
     end else if(index==0) state<=BROUND;
     else if(tr) state<=TWAIT;
    end
    BROUND:begin
     qx<=(selected_x>>>18)+$signed({1'b0,((selected_x[17:0]>18'h20000)||((selected_x[17:0]==18'h20000)&&selected_x[18]))});
     qy<=(selected_y>>>18)+$signed({1'b0,((selected_y[17:0]>18'h20000)||((selected_y[17:0]==18'h20000)&&selected_y[18]))});state<=BCHECK;
    end
    BCHECK:begin
      if(qx[29:17]!={13{qx[17]}} || qy[29:17]!={13{qy[17]}}) begin
       fault_flags[`Q_FAULT_NUMERIC_OVERFLOW_BIT]<=1;state<=DRAIN;
      end else begin
       staged_ball[`Q_BALL_CENTER_LSB+:18]<=qx[17:0];staged_ball[`Q_BALL_CENTER_LSB+18+:18]<=qy[17:0];
       staged_ball[`Q_BALL_RADIUS_LSB+:18]<=`Q_BALL_RADIUS_Q6;state<=NEXT;
      end
    end
    TWAIT:if(tv) begin
     if(tfault) begin fault_flags[`Q_FAULT_NUMERIC_OVERFLOW_BIT]<=1;state<=DRAIN;end
     else begin staged_strokes[index-1]<=transformed;state<=NEXT;end
    end
    NEXT:begin
     if(index+1<count) begin index<=index+1;state<=loading ? VREQ : IREQ;end
     else if(!half) begin half<=1;index<=0;state<=IREQ;end
     else state<=PUBLISH;
    end
    VREQ:if(er) state<=VWAIT;
    VWAIT:if(ev) begin
     if(ef) begin fault_flags[`Q_FAULT_NUMERIC_OVERFLOW_BIT]<=1;state<=DRAIN;end
     else state<=TREQ;
    end
    PUBLISH:begin
     if(revision==32'hffffffff) begin fault_flags[`Q_FAULT_COUNTER_BIT]<=1;state<=DRAIN;end
     else if(!invalidated) begin
      for(k=0;k<6;k=k+1) bodies[k*`Q_BS_W+:`Q_BS_W]<=staged[k];
      for(k=0;k<5;k=k+1) stroke_geometry[k*`Q_STROKE_W+:`Q_STROKE_W]<=staged_strokes[k];
      body_count<=count;ball_geometry<=staged_ball;
      revision<=revision+1;commit<=1;busy<=0;state<=IDLE;
     end else state<=DRAIN;
    end
    DRAIN:begin busy<=0;state<=IDLE;end
    default:begin fault_flags[`Q_FAULT_NUMERIC_OVERFLOW_BIT]<=1;state<=DRAIN;end
   endcase
  end
 end
endmodule
