`include "q_contract.vh"
// Complete local-sample transform. Results are held until retirement; faults
// return zero geometry so callers cannot accidentally publish a partial shape.
module q_transform #(parameter MEM_FILE="rtl/physics/q_sine_q16.mem")(
 input wire clk,input wire rst,input wire req_valid,output wire req_ready,
 input wire [3:0] req_count,input wire signed [17:0] req_radius_q6,
 input wire [511:0] req_local_xy_q16,
 input wire signed [47:0] req_center_x_q24,input wire signed [47:0] req_center_y_q24,
 input wire [31:0] req_phase,
 output reg rsp_valid,input wire rsp_ready,output reg rsp_fault,
 output reg [`Q_STROKE_W-1:0] rsp_stroke
);
 `include "q_numeric_functions.vh"
 reg [3:0] state;
 reg [3:0] count,index;
 reg [511:0] local_xy;
 reg signed [47:0] cx,cy;
 reg [31:0] phase;
 reg signed [17:0] radius,sine,cosine;
 reg [`Q_STROKE_W-1:0] staged;
 wire tr,tv;
 wire signed [17:0] ts,tc;
 q_sincos #(.MEM_FILE(MEM_FILE)) trig(clk,rst,state==1,tr,phase,tv,state==2,ts,tc);
 reg signed [31:0] lx,ly;
 reg signed [49:0] xc,ys,xs,yc;
 reg signed [50:0] rx,ry;
 reg signed [42:0] rot_x,rot_y;
 reg signed [48:0] world_x,world_y;
 reg signed [30:0] xq,yq;
 assign req_ready=state==0 && !rsp_valid;
 always @(posedge clk) begin
  if(rst) begin state<=0;rsp_valid<=0;rsp_fault<=0;rsp_stroke<=0;count<=0;index<=0;local_xy<=0;cx<=0;cy<=0;phase<=0;radius<=0;sine<=0;cosine<=0;staged<=0;end
  else begin
   if(rsp_valid && rsp_ready) rsp_valid<=0;
   case(state)
    0:if(req_valid && req_ready) begin
     count<=req_count;index<=0;local_xy<=req_local_xy_q16;cx<=req_center_x_q24;cy<=req_center_y_q24;
     phase<=req_phase;radius<=req_radius_q6;staged<=0;rsp_fault<=0;rsp_stroke<=0;
     if(req_count<2 || req_count>8 || req_radius_q6<=0) begin rsp_fault<=1;state<=5;end else state<=1;
    end
    1:if(tr) state<=2;
    2:if(tv) begin sine<=ts;cosine<=tc;staged[`Q_STROKE_COUNT_LSB+:4]<=count;staged[`Q_STROKE_RADIUS_LSB+:18]<=radius;state<=3;end
    3:begin
     lx<=$signed(local_xy[32*index+:32]);ly<=$signed(local_xy[256+32*index+:32]);state<=6;
    end
    6:begin xc<=lx*cosine;ys<=ly*sine;xs<=lx*sine;yc<=ly*cosine;state<=7;end
    7:begin rx<=$signed({xc[49],xc})-$signed({ys[49],ys});ry<=$signed({xs[49],xs})+$signed({yc[49],yc});state<=8;end
    8:begin
     rot_x<=(rx>>>8)+$signed({1'b0,((rx[7:0]>8'h80)||((rx[7:0]==8'h80)&&rx[8]))});
     rot_y<=(ry>>>8)+$signed({1'b0,((ry[7:0]>8'h80)||((ry[7:0]==8'h80)&&ry[8]))});state<=10;
    end
    10:begin world_x<=$signed({cx[47],cx})+$signed({{6{rot_x[42]}},rot_x});world_y<=$signed({cy[47],cy})+$signed({{6{rot_y[42]}},rot_y});state<=9;end
    9:begin
     xq=(world_x>>>18)+$signed({1'b0,((world_x[17:0]>18'h20000)||((world_x[17:0]==18'h20000)&&world_x[18]))});
     yq=(world_y>>>18)+$signed({1'b0,((world_y[17:0]>18'h20000)||((world_y[17:0]==18'h20000)&&world_y[18]))});
     if(xq[30:17]!={14{xq[17]}} || yq[30:17]!={14{yq[17]}}) begin rsp_fault<=1;state<=5;end
     else begin
      staged[`Q_STROKE_POINT_LSB(index)+:18]<=xq[17:0];staged[`Q_STROKE_POINT_LSB(index)+18+:18]<=yq[17:0];
      if(index+1==count) state<=4;else begin index<=index+1;state<=3;end
     end
    end
    4:begin rsp_stroke<=staged;state<=5;end
    5:begin rsp_valid<=1;state<=0;end
    default:begin rsp_fault<=1;rsp_stroke<=0;state<=5;end
   endcase
  end
 end
endmodule
