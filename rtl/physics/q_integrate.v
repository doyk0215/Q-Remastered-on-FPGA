`include "q_numeric_params_draft.vh"
`include "q_physics_params.vh"
`include "q_geometry_params.vh"
// One semi-implicit half-update. Impulses must already be included in velocity.
// Contact correction is deliberately reserved for Story 4 (<=1/2 pixel total).
module q_integrate(
 input wire clk,input wire rst,input wire req_valid,output wire req_ready,
 input wire req_advance,input wire req_ball,
 input wire signed [47:0] req_x_q24,input wire signed [47:0] req_y_q24,
 input wire signed [39:0] req_vx_q24,input wire signed [39:0] req_vy_q24,
 input wire signed [31:0] req_omega_q24,input wire [31:0] req_phase,
 input wire [31:0] req_extent_q16,
 output reg rsp_valid,input wire rsp_ready,output reg rsp_fault,
 output reg signed [47:0] rsp_x_q24,output reg signed [47:0] rsp_y_q24,
 output reg signed [39:0] rsp_vx_q24,output reg signed [39:0] rsp_vy_q24,
 output reg signed [31:0] rsp_omega_q24,output reg [31:0] rsp_phase,
 output reg [49:0] rsp_motion_bound_q24
);
 `include "q_numeric_functions.vh"
 localparam IDLE=0,BALL=1,SREQ=2,SWAIT=3,BOUND=4,DREQ=5,DWAIT=6,SCALE=7,INTEGRATE=8,FINISH=9,
            ROTATION=10,SQUARES=11,NORM=12,SCALE_PRODUCTS=13,PHASE_PRODUCT=14,ROTROUND=15,ABS_OMEGA=16;
 // 27/8 pixels per half-update, expressed as outer-update velocity.
 localparam [49:0] LIMIT=(50'd1*`Q_DRAFT_INTEGRATION_BUDGET_Q6)<<19;
 localparam [49:0] CLAMP_LIMIT=LIMIT-50'd2048;
 localparam [49:0] BALL_LIMIT=(50'd1*`Q_MAX_POINT_TRAVEL_OUTER_PIX)<<24;
 localparam [49:0] BALL_CLAMP_LIMIT=BALL_LIMIT-50'd1024;
 reg [4:0] state;
 reg ball,ball_divide;
 reg [1:0] attempts;
 reg signed [47:0] x,y;
 reg signed [40:0] vx,vy;
 reg signed [32:0] omega;
 reg [31:0] phase,extent;
 reg [41:0] norm;
 reg [24:0] scale;
 reg [63:0] numerator,denominator;
 reg [32:0] abs_omega;
 reg [64:0] rotation_product;
 reg [49:0] rotation_bound;
 wire [49:0] demand={8'b0,norm}+(ball ? 50'd0 : rotation_bound);
 reg [81:0] vx2,vy2;
 reg [83:0] norm_rad;
 wire sr,sv,si;
 wire [41:0] root;
 q_isqrt #(.ROOT_W(42)) norm_sqrt(clk,rst,state==SREQ,sr,norm_rad,sv,state==SWAIT,root,si);
 wire dr,dv,df;
 wire [63:0] quotient;
 q_udiv_rne #(.W(64),.ROUND_NEAREST(0)) divider(clk,rst,state==DREQ,dr,numerator,denominator,dv,state==DWAIT,quotient,df);
 reg signed [66:0] scaled_vx,scaled_vy;
 reg signed [58:0] scaled_omega;
 reg signed [65:0] phase_product;
 wire signed [42:0] rounded_vx=(scaled_vx>>>24)+$signed({1'b0,((scaled_vx[23:0]>24'h800000)||((scaled_vx[23:0]==24'h800000)&&scaled_vx[24]))});
 wire signed [42:0] rounded_vy=(scaled_vy>>>24)+$signed({1'b0,((scaled_vy[23:0]>24'h800000)||((scaled_vy[23:0]==24'h800000)&&scaled_vy[24]))});
 wire signed [34:0] rounded_omega=(scaled_omega>>>24)+$signed({1'b0,((scaled_omega[23:0]>24'h800000)||((scaled_omega[23:0]==24'h800000)&&scaled_omega[24]))});
 wire signed [40:0] half_vx=(vx>>>1)+$signed({1'b0,(vx[0]&&vx[1])});
 wire signed [40:0] half_vy=(vy>>>1)+$signed({1'b0,(vy[0]&&vy[1])});
 wire signed [48:0] integrated_x=$signed({x[47],x})+$signed({{8{half_vx[40]}},half_vx});
 wire signed [48:0] integrated_y=$signed({y[47],y})+$signed({{8{half_vy[40]}},half_vy});
 wire signed [40:0] phase_delta=(phase_product>>>25)+$signed({1'b0,((phase_product[24:0]>25'h1000000)||((phase_product[24:0]==25'h1000000)&&phase_product[25]))});
 assign req_ready=state==IDLE && !rsp_valid;
 always @(posedge clk) begin
  if(rst) begin
   state<=IDLE;rsp_valid<=0;rsp_fault<=0;rsp_x_q24<=0;rsp_y_q24<=0;
   rsp_vx_q24<=0;rsp_vy_q24<=0;rsp_omega_q24<=0;rsp_phase<=0;rsp_motion_bound_q24<=0;
   ball<=0;ball_divide<=0;attempts<=0;x<=0;y<=0;vx<=0;vy<=0;omega<=0;abs_omega<=0;phase<=0;extent<=0;norm<=0;scale<=0;numerator<=0;denominator<=0;
  end else begin
   if(rsp_valid && rsp_ready) rsp_valid<=0;
   case(state)
    IDLE:if(req_valid && req_ready) begin
     x<=req_x_q24;y<=req_y_q24;vx<=req_vx_q24;
     vy<=$signed({req_vy_q24[39],req_vy_q24})+$signed({1'b0,`Q_DRAFT_GRAVITY_SUBSTEP_Q24});
     omega<=req_omega_q24;phase<=req_phase;extent<=req_extent_q16;ball<=req_ball;attempts<=0;
     rsp_fault<=0;rsp_x_q24<=req_x_q24;rsp_y_q24<=req_y_q24;
     rsp_vx_q24<=req_vx_q24;rsp_vy_q24<=req_vy_q24;rsp_omega_q24<=req_omega_q24;rsp_phase<=req_phase;rsp_motion_bound_q24<=0;
     if(!req_advance) state<=FINISH;
     else if(req_extent_q16<((req_ball ? 32'd1*`Q_BALL_RADIUS_PIX : 32'd1*`Q_STROKE_RADIUS_PIX)<<16) ||
             req_extent_q16>(32'd1*`Q_DRAFT_MAX_EXTENT_PIX<<16)) begin rsp_fault<=1;state<=FINISH;end
     else state<=ABS_OMEGA;
    end
    ABS_OMEGA:begin abs_omega<=omega[32] ? -omega : omega;state<=ROTATION;end
    ROTATION:begin rotation_product<=abs_omega*extent;state<=ROTROUND;end
    ROTROUND:begin rotation_bound<=(rotation_product>>16)+(|rotation_product[15:0]);state<=BALL;end
    BALL:begin
     if(ball && rotation_bound>BALL_LIMIT) begin
      if(attempts==2) begin rsp_fault<=1;state<=FINISH;end
      else begin numerator<={78'b0,BALL_CLAMP_LIMIT}<<24;denominator<=rotation_bound;ball_divide<=1;state<=DREQ;end
     end else state<=SQUARES;
    end
    SQUARES:begin vx2<=vx*vx;vy2<=vy*vy;state<=NORM;end
    NORM:begin norm_rad<={2'b0,vx2}+{2'b0,vy2};state<=SREQ;end
    SREQ:if(sr) state<=SWAIT;
    SWAIT:if(sv) begin norm<=root+si;state<=BOUND;end
    BOUND:begin
     if(demand>LIMIT) begin
      if(attempts==2) begin rsp_fault<=1;state<=FINISH;end
      // 2048 raw Q24 units cover the rounding of both velocity components
      // and omega*R at the maximum extent. Rechecking remains mandatory.
      else begin numerator<={78'b0,CLAMP_LIMIT}<<24;denominator<=demand;ball_divide<=0;state<=DREQ;end
     end else begin rsp_motion_bound_q24<=demand;state<=PHASE_PRODUCT;end
    end
    DREQ:if(dr) state<=DWAIT;
    DWAIT:if(dv) begin
     if(df || quotient>128'd16777216) begin rsp_fault<=1;state<=FINISH;end
     else begin scale<=quotient[24:0];state<=SCALE_PRODUCTS;end
    end
    SCALE_PRODUCTS:begin
     scaled_vx<=vx*$signed({1'b0,scale});scaled_vy<=vy*$signed({1'b0,scale});
     scaled_omega<=omega*$signed({1'b0,scale});state<=SCALE;
    end
    SCALE:begin
     omega<=rounded_omega[32:0];
     if(!ball_divide) begin
      vx<=rounded_vx[40:0];vy<=rounded_vy[40:0];
     end
     attempts<=attempts+1;
     // Recompute the conservative norm after every rounded scaling operation.
     state<=ABS_OMEGA;
    end
    PHASE_PRODUCT:begin phase_product<=omega*$signed({1'b0,`Q_DRAFT_INV_TWO_PI_Q32});state<=INTEGRATE;end
    INTEGRATE:begin
     if(integrated_x[48]!=integrated_x[47] || integrated_y[48]!=integrated_y[47] ||
        vx[40]!=vx[39] || vy[40]!=vy[39] || omega[32]!=omega[31]) rsp_fault<=1;
     else begin
      rsp_x_q24<=integrated_x[47:0];rsp_y_q24<=integrated_y[47:0];rsp_vx_q24<=vx[39:0];rsp_vy_q24<=vy[39:0];
      rsp_omega_q24<=omega[31:0];rsp_phase<=phase+phase_delta[31:0];
     end
     state<=FINISH;
    end
    FINISH:begin rsp_valid<=1;state<=IDLE;end
    default:begin rsp_fault<=1;state<=FINISH;end
   endcase
  end
 end
endmodule
