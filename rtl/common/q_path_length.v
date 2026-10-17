`include "q_contract.vh"
`include "q_parallel_ports_draft.vh"
// The common input/admission rule: sum floor(sqrt(dx^2+dy^2)) in Q6.
module q_path_length(
 input wire clk, input wire rst,
 `Q_DRAFT_PATH_LENGTH_REQ_SINK_PORTS,
 `Q_DRAFT_PATH_LENGTH_RSP_SOURCE_PORTS
);
 reg [2:0] state;
 reg [`Q_STROKE_W-1:0] stroke;
 reg [3:0] count, segment;
 reg [23:0] total;
 reg distinct;
 reg valid, bad;
 reg [23:0] result;
 reg result_distinct;
 wire signed [17:0] ax=$signed(stroke[`Q_STROKE_POINT_LSB(segment)+:18]);
 wire signed [17:0] ay=$signed(stroke[`Q_STROKE_POINT_LSB(segment)+18+:18]);
 wire signed [17:0] bx=$signed(stroke[`Q_STROKE_POINT_LSB(segment+1)+:18]);
 wire signed [17:0] by=$signed(stroke[`Q_STROKE_POINT_LSB(segment+1)+18+:18]);
 wire signed [18:0] dx={bx[17],bx}-{ax[17],ax};
 wire signed [18:0] dy={by[17],by}-{ay[17],ay};
 reg signed [18:0] dx_reg,dy_reg;
 reg [37:0] xx,yy;
 reg [39:0] rad;
 wire sqrt_ready,sqrt_valid,sqrt_inexact;
 wire [19:0] sqrt_root;
 q_isqrt #(.ROOT_W(20)) sqrt_unit(clk,rst,state==1,sqrt_ready,rad,sqrt_valid,state==2,sqrt_root,sqrt_inexact);
 assign length_req_ready=state==0 && !valid;
 assign length_rsp_valid=valid;
 assign length_rsp_total_q6=result;
 assign length_rsp_two_distinct=result_distinct;
 assign length_rsp_bad_payload=bad;
 always @(posedge clk) begin
  if(rst) begin state<=0; stroke<=0; count<=0; segment<=0; total<=0; distinct<=0; valid<=0; bad<=0; result<=0; result_distinct<=0; end
  else begin
   if(valid && length_rsp_ready) valid<=0;
   if(length_req_valid && length_req_ready) begin
    stroke<=length_req_stroke; count<=length_req_stroke[`Q_STROKE_COUNT_LSB+:4];
    total<=0; distinct<=0; segment<=0; result<=0; result_distinct<=0; bad<=0;
    if(length_req_stroke[`Q_STROKE_COUNT_LSB+:4]>8) begin valid<=1; bad<=1; end
    else if(length_req_stroke[`Q_STROKE_COUNT_LSB+:4]<2) valid<=1;
    else state<=3;
   end else if(state==3) begin dx_reg<=dx;dy_reg<=dy;state<=4;
   end else if(state==4) begin xx<=dx_reg*dx_reg;yy<=dy_reg*dy_reg;state<=5;
   end else if(state==5) begin rad<={2'b0,xx}+{2'b0,yy};state<=1;
   end else if(state==1 && sqrt_ready) state<=2;
   else if(state==2 && sqrt_valid) begin
    total<=total+sqrt_root; distinct<=distinct || sqrt_root!=0;
    if(segment+2==count) begin result<=total+sqrt_root; result_distinct<=distinct || sqrt_root!=0; valid<=1; state<=0; end
    else begin segment<=segment+1; state<=3; end
   end
  end
 end
endmodule
