// Bounded unsigned division with one final round-to-nearest, ties-to-even.
// W restoring iterations followed by one rounding cycle. Zero divisor faults.
module q_udiv_rne #(parameter W=128,parameter ROUND_NEAREST=1)(
 input wire clk, input wire rst, input wire req_valid, output wire req_ready,
 input wire [W-1:0] req_numerator, input wire [W-1:0] req_denominator,
 output reg rsp_valid, input wire rsp_ready,
 output reg [W-1:0] rsp_quotient, output reg rsp_fault
);
 reg [1:0] state;
 reg [W-1:0] numerator, denominator, quotient;
 reg [W:0] remainder;
 integer left;
 wire [W:0] shifted = (remainder<<1) | numerator[W-1];
 // remainder < denominator makes the subtract's high bit the borrow flag.
 // A single subtract replaces a serial compare-then-subtract carry chain.
 wire [W:0] difference = shifted-{1'b0,denominator};
 wire take = !difference[W];
 wire [W:0] next_rem = take ? difference : shifted;
 wire [W-1:0] next_quot = (quotient<<1) | take;
 wire round_up = ROUND_NEAREST && (((remainder<<1) > {1'b0,denominator}) ||
                (((remainder<<1)=={1'b0,denominator}) && quotient[0]));
 assign req_ready = state==0 && !rsp_valid;
 always @(posedge clk) begin
  if(rst) begin state<=0; rsp_valid<=0; rsp_quotient<=0; rsp_fault<=0; numerator<=0; denominator<=0; quotient<=0; remainder<=0; left<=0; end
  else begin
   if(rsp_valid && rsp_ready) rsp_valid<=0;
   if(req_valid && req_ready) begin
    if(req_denominator==0) begin rsp_valid<=1; rsp_fault<=1; rsp_quotient<=0; end
    else begin state<=1; numerator<=req_numerator; denominator<=req_denominator; quotient<=0; remainder<=0; left<=W; end
   end else if(state==1) begin
    numerator<=numerator<<1; quotient<=next_quot; remainder<=next_rem; left<=left-1;
    if(left==1) state<=2;
   end else if(state==2) begin
    state<=0; rsp_valid<=1; rsp_fault<=round_up && (&quotient);
    rsp_quotient<=quotient+round_up;
   end
  end
 end
endmodule
