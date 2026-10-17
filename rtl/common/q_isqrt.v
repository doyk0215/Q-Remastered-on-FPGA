// Unsigned floor square root. Fixed ROOT_W iterations, one outstanding result.
module q_isqrt #(parameter ROOT_W=20)(
 input wire clk, input wire rst,
 input wire req_valid, output wire req_ready,
 input wire [2*ROOT_W-1:0] req_radicand,
 output reg rsp_valid, input wire rsp_ready,
 output reg [ROOT_W-1:0] rsp_root,
 output reg rsp_inexact
);
 reg busy;
 reg [2*ROOT_W-1:0] rad;
 reg [ROOT_W+1:0] rem;
 reg [ROOT_W-1:0] root;
 integer left;
 wire [ROOT_W+1:0] shifted = (rem << 2) | (rad >> (2*ROOT_W-2));
 wire [ROOT_W+1:0] trial = ({2'b0,root} << 2) | 1'b1;
 wire take = shifted >= trial;
 wire [ROOT_W+1:0] next_rem = take ? shifted-trial : shifted;
 wire [ROOT_W-1:0] next_root = (root << 1) | take;
 assign req_ready = !busy && !rsp_valid;
 always @(posedge clk) begin
  if (rst) begin busy<=0; rsp_valid<=0; rsp_root<=0; rsp_inexact<=0; rad<=0; rem<=0; root<=0; left<=0; end
  else begin
   if (rsp_valid && rsp_ready) rsp_valid<=0;
   if (req_valid && req_ready) begin busy<=1; rad<=req_radicand; rem<=0; root<=0; left<=ROOT_W; end
   else if (busy) begin
    rad<=rad<<2; rem<=next_rem; root<=next_root; left<=left-1;
    if (left==1) begin busy<=0; rsp_valid<=1; rsp_root<=next_root; rsp_inexact<=next_rem!=0; end
   end
  end
 end
endmodule
