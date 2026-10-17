`include "q_contract.vh"
`include "q_geometry_params.vh"
`include "q_numeric_params_draft.vh"
// Private arithmetic helper; this does not insert a body or allocate an ID.
// Local vertices have x in bits 32*i+:32 and y in bits 32*i+256+:32.
module q_body_properties(
 input wire clk,input wire rst,input wire req_valid,output wire req_ready,
 input wire [`Q_STROKE_W-1:0] req_stroke,
 output reg rsp_valid,input wire rsp_ready,output reg rsp_rejected,output reg rsp_fault,
 output reg [23:0] rsp_length_q6,output reg [31:0] rsp_mass_q16,
 output reg signed [47:0] rsp_center_x_q24,output reg signed [47:0] rsp_center_y_q24,
 output reg [511:0] rsp_local_xy_q16,output reg [31:0] rsp_extent_q16,
 output reg [63:0] rsp_inertia_q16,
 output reg [47:0] rsp_inverse_mass_q32,output reg [47:0] rsp_inverse_inertia_q32
);
 `include "q_numeric_functions.vh"
 localparam IDLE=0,LREQ=1,LWAIT=2,SREQ=3,SWAIT=4,DREQ=5,DWAIT=6,
            LOCAL=7,MOMENT=8,EXTREQ=9,EXTWAIT=10,FINAL=11,
            MPRODUCTS=12,DOTMUL=13,DOTACCUM=14,MWEIGHT=15,MACCUM=16,
            SETSEG=17,SPRODUCTS=18,SRAD=19,COMADD=20,COMDIV=21,EXTSET=22,EXTPROD=23,EXTRAD=24,
            EXTSETY=25,EXTPRODY=26;
 reg [4:0] state;
 reg [`Q_STROKE_W-1:0] stroke;
 reg [3:0] count,index;
 reg [19:0] lengths[0:6];
 reg [23:0] length;
 reg signed [31:0] cx,cy,lx[0:7],ly[0:7];
 reg signed [63:0] wx,wy;
 reg signed [95:0] moment;
 reg [2:0] divide_kind;
 reg [95:0] numerator,denominator;
 reg negative;
 reg [31:0] extent;
 wire lready,lvalid,ldist,lbad;
 wire [23:0] ltotal;
 q_path_length length_unit(clk,rst,state==LREQ,lready,stroke,lvalid,state==LWAIT,ltotal,ldist,lbad);
 wire signed [17:0] ax=$signed(stroke[`Q_STROKE_POINT_LSB(index)+:18]);
 wire signed [17:0] ay=$signed(stroke[`Q_STROKE_POINT_LSB(index)+18+:18]);
 wire signed [17:0] bx=$signed(stroke[`Q_STROKE_POINT_LSB(index+1)+:18]);
 wire signed [17:0] by=$signed(stroke[`Q_STROKE_POINT_LSB(index+1)+18+:18]);
 wire signed [18:0] dx={bx[17],bx}-{ax[17],ax};
 wire signed [18:0] dy={by[17],by}-{ay[17],ay};
 reg signed [18:0] dx_reg,dy_reg;
 reg [37:0] xx,yy;
 reg [39:0] segment_rad;
 wire sready,svalid,sinexact;
 wire [19:0] sroot;
 q_isqrt #(.ROOT_W(20)) segment_sqrt(clk,rst,state==SREQ,sready,segment_rad,svalid,state==SWAIT,sroot,sinexact);
 wire dready,dvalid,dfault;
 wire [95:0] quotient;
 // Check the unsigned magnitude before a 33-bit sign restore. Performing a
 // 96-bit negate then a 128-bit range comparison creates an avoidable path.
 wire com_bad=(|quotient[95:32]) || (!negative && quotient[31]) ||
              (negative && quotient[31] && (|quotient[30:0]));
 wire signed [32:0] signed_com=negative ? -$signed({1'b0,quotient[31:0]}) : $signed({1'b0,quotient[31:0]});
 q_udiv_rne #(.W(96)) divider(clk,rst,state==DREQ,dready,numerator,denominator,dvalid,state==DWAIT,quotient,dfault);
 wire signed [32:0] sumx=($signed({{15{ax[17]}},ax})+$signed({{15{bx[17]}},bx}))<<<10;
 wire signed [32:0] sumy=($signed({{15{ay[17]}},ay})+$signed({{15{by[17]}},by}))<<<10;
 reg signed [32:0] sumx_reg,sumy_reg;
 reg signed [53:0] weighted_x,weighted_y;
 reg signed [31:0] maxx,mayy,mbxx,mbyy;
 reg signed [31:0] mul_a,mul_b;
 wire signed [63:0] mul_product=mul_a*mul_b;
 reg signed [63:0] product_reg;
 reg [2:0] dot_term;
 reg signed [66:0] quadratic;
 wire signed [91:0] weighted_moment=quadratic*$signed({1'b0,lengths[index],4'b0});
 reg signed [91:0] weighted_reg;
 reg [63:0] local_xx,local_yy;
 reg [65:0] extent_rad;
 wire eready,evalid,einexact;
 wire [32:0] eroot;
 wire [33:0] point_extent={1'b0,eroot}+einexact+({16'b0,stroke[`Q_STROKE_RADIUS_LSB+:18]}<<10);
 q_isqrt #(.ROOT_W(33)) extent_sqrt(clk,rst,state==EXTREQ,eready,extent_rad,evalid,state==EXTWAIT,eroot,einexact);
 reg signed [127:0] temp;
 integer k;
 assign req_ready=state==IDLE && !rsp_valid;
 always @(posedge clk) begin
  if(rst) begin
   state<=IDLE; rsp_valid<=0; rsp_rejected<=0; rsp_fault<=0;
   rsp_length_q6<=0; rsp_mass_q16<=0; rsp_center_x_q24<=0; rsp_center_y_q24<=0;
   rsp_local_xy_q16<=0; rsp_extent_q16<=0; rsp_inertia_q16<=0;
   rsp_inverse_mass_q32<=0; rsp_inverse_inertia_q32<=0;
   stroke<=0; count<=0; index<=0; length<=0; cx<=0; cy<=0;
   wx<=0;wy<=0;moment<=0;divide_kind<=0;numerator<=0;denominator<=0;negative<=0;extent<=0;
   for(k=0;k<8;k=k+1) begin lx[k]<=0;ly[k]<=0;end
   for(k=0;k<7;k=k+1) lengths[k]<=0;
  end else begin
   if(rsp_valid && rsp_ready) rsp_valid<=0;
   case(state)
    IDLE: if(req_valid && req_ready) begin
     stroke<=req_stroke; count<=req_stroke[`Q_STROKE_COUNT_LSB+:4];
     rsp_rejected<=0; rsp_fault<=0; rsp_length_q6<=0; rsp_mass_q16<=0;
     rsp_center_x_q24<=0; rsp_center_y_q24<=0; rsp_local_xy_q16<=0;
     rsp_extent_q16<=0; rsp_inertia_q16<=0; rsp_inverse_mass_q32<=0; rsp_inverse_inertia_q32<=0;
     wx<=0;wy<=0;moment<=0;extent<=0;index<=0;state<=LREQ;
    end
    LREQ: if(lready) state<=LWAIT;
    LWAIT: if(lvalid) begin
     length<=ltotal; rsp_length_q6<=ltotal;
     if(lbad || !ldist || ltotal<`Q_STROKE_MIN_LENGTH_Q6 || $signed(stroke[`Q_STROKE_RADIUS_LSB+:18])<=0) begin rsp_rejected<=1;state<=FINAL;end
     else begin rsp_mass_q16<=ltotal<<4;state<=SETSEG;end
    end
    SETSEG:begin dx_reg<=dx;dy_reg<=dy;sumx_reg<=sumx;sumy_reg<=sumy;state<=SPRODUCTS;end
    SPRODUCTS:begin xx<=dx_reg*dx_reg;yy<=dy_reg*dy_reg;state<=SRAD;end
    SRAD:begin segment_rad<={2'b0,xx}+{2'b0,yy};state<=SREQ;end
    SREQ: if(sready) state<=SWAIT;
    SWAIT: if(svalid) begin
     lengths[index]<=sroot;
     weighted_x<=$signed({1'b0,sroot})*sumx_reg;weighted_y<=$signed({1'b0,sroot})*sumy_reg;state<=COMADD;
    end
    COMADD:begin
     wx<=wx+weighted_x;wy<=wy+weighted_y;
     if(index+2==count) begin
      state<=COMDIV;
     end else begin index<=index+1;state<=SETSEG;end
    end
    COMDIV:begin numerator<=wx[63] ? -wx : wx;negative<=wx[63];denominator<={71'b0,length,1'b0};divide_kind<=0;state<=DREQ;end
    DREQ: if(dready) state<=DWAIT;
    DWAIT: if(dvalid) begin
     if(dfault) begin rsp_fault<=1;state<=FINAL;end
     else case(divide_kind)
      0: begin
       if(com_bad) begin rsp_fault<=1;state<=FINAL;end
       else begin cx<=signed_com[31:0];rsp_center_x_q24<=$signed({{15{signed_com[32]}},signed_com})<<<8;
       numerator<=wy[63] ? -wy : wy;negative<=wy[63];divide_kind<=1;state<=DREQ;end
      end
      1: begin
       if(com_bad) begin rsp_fault<=1;state<=FINAL;end
       else begin cy<=signed_com[31:0];rsp_center_y_q24<=$signed({{15{signed_com[32]}},signed_com})<<<8;index<=0;state<=LOCAL;end
      end
      2: begin
       if(|quotient[95:64]) begin rsp_fault<=1;state<=FINAL;end
       else begin
        rsp_inertia_q16<=quotient<`Q_DRAFT_INERTIA_FLOOR_Q16 ? `Q_DRAFT_INERTIA_FLOOR_Q16 : quotient[63:0];
        numerator<=128'd281474976710656;denominator<=rsp_mass_q16;divide_kind<=3;state<=DREQ;
       end
      end
      3: begin
       if(|quotient[95:48] || quotient==0) begin rsp_fault<=1;state<=FINAL;end
       else begin rsp_inverse_mass_q32<=quotient[47:0];numerator<=128'd281474976710656;denominator<=rsp_inertia_q16;divide_kind<=4;state<=DREQ;end
      end
      4: begin
       if(|quotient[95:48] || quotient==0) rsp_fault<=1;
       else rsp_inverse_inertia_q32<=quotient[47:0];
       state<=FINAL;
      end
      default: begin rsp_fault<=1;state<=FINAL;end
     endcase
    end
    LOCAL: begin
     // Original Q6 endpoints convert exactly to Q16. COM is within their hull.
     temp=($signed({{110{ax[17]}},ax})<<<10)-cx;
     lx[index]<=temp[31:0];rsp_local_xy_q16[32*index+:32]<=temp[31:0];
     temp=($signed({{110{ay[17]}},ay})<<<10)-cy;
     ly[index]<=temp[31:0];rsp_local_xy_q16[256+32*index+:32]<=temp[31:0];
     if(index+1==count) begin index<=0;state<=MOMENT;end else index<=index+1;
    end
    MOMENT: begin
     maxx<=lx[index];mayy<=ly[index];mbxx<=lx[index+1];mbyy<=ly[index+1];
     quadratic<=0;dot_term<=0;state<=MPRODUCTS;
    end
    MPRODUCTS:begin
     // One shared multiply lane evaluates aa, ab, bb in x and then y.
     case(dot_term)
      0:begin mul_a<=maxx;mul_b<=maxx;end
      1:begin mul_a<=maxx;mul_b<=mbxx;end
      2:begin mul_a<=mbxx;mul_b<=mbxx;end
      3:begin mul_a<=mayy;mul_b<=mayy;end
      4:begin mul_a<=mayy;mul_b<=mbyy;end
      default:begin mul_a<=mbyy;mul_b<=mbyy;end
     endcase
     state<=DOTMUL;
    end
    DOTMUL:begin product_reg<=mul_product;state<=DOTACCUM;end
    DOTACCUM:begin
     quadratic<=quadratic+$signed({{3{product_reg[63]}},product_reg});
     if(dot_term==5) state<=MWEIGHT;
     else begin dot_term<=dot_term+1;state<=MPRODUCTS;end
    end
    MWEIGHT:begin weighted_reg<=weighted_moment;state<=MACCUM;end
    MACCUM:begin
     if(quadratic<0) begin rsp_fault<=1;state<=FINAL;end
     else begin
      moment<=moment+weighted_reg;
      if(index+2==count) begin index<=0;state<=EXTSET;end else begin index<=index+1;state<=MOMENT;end
     end
    end
    EXTSET:begin mul_a<=lx[index];mul_b<=lx[index];state<=EXTPROD;end
    EXTPROD:begin local_xx<=mul_product;state<=EXTSETY;end
    EXTSETY:begin mul_a<=ly[index];mul_b<=ly[index];state<=EXTPRODY;end
    EXTPRODY:begin local_yy<=mul_product;state<=EXTRAD;end
    EXTRAD:begin extent_rad<={2'b0,local_xx}+{2'b0,local_yy};state<=EXTREQ;end
    EXTREQ: if(eready) state<=EXTWAIT;
    EXTWAIT: if(evalid) begin
     if(point_extent>(34'd1*`Q_DRAFT_MAX_EXTENT_PIX<<16)) begin rsp_rejected<=1;state<=FINAL;end
     else begin
      if(point_extent>extent) extent<=point_extent[31:0];
      if(index+1==count) begin
       rsp_extent_q16<=point_extent>extent ? point_extent[31:0] : extent;
       numerator<=moment;denominator<=128'd3<<32;divide_kind<=2;state<=DREQ;
      end else begin index<=index+1;state<=EXTSET;end
     end
    end
    FINAL: begin rsp_valid<=1;state<=IDLE;end
    default: begin state<=FINAL;rsp_fault<=1;end
   endcase
  end
 end
endmodule
