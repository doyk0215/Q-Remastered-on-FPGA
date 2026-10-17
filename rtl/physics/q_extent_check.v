`include "q_numeric_params_draft.vh"
// Verify a controlled local sample set against its declared conservative extent.
// One shared signed 32x32 square, scheduled for bound, x and y in turn.
module q_extent_check(
 input wire clk,input wire rst,input wire req_valid,output wire req_ready,
 input wire [3:0] req_count,input wire signed [17:0] req_radius_q6,
 input wire [31:0] req_extent_q16,input wire [511:0] req_local_xy_q16,
 output reg rsp_valid,input wire rsp_ready,output reg rsp_fault
);
 reg [3:0] state,count,index;
 reg [511:0] local_xy;
 reg signed [31:0] operand;
 wire signed [63:0] square=operand*operand;
 reg [63:0] limit,x_square,y_square;
 wire [64:0] norm_squared={1'b0,x_square}+{1'b0,y_square};
 assign req_ready=state==0 && !rsp_valid;
 always @(posedge clk) begin
  if(rst) begin state<=0;count<=0;index<=0;local_xy<=0;operand<=0;limit<=0;x_square<=0;y_square<=0;rsp_valid<=0;rsp_fault<=0;end
  else begin
   if(rsp_valid && rsp_ready) rsp_valid<=0;
   case(state)
    0:if(req_valid && req_ready) begin
     count<=req_count;index<=0;local_xy<=req_local_xy_q16;rsp_fault<=0;
     if(req_count<2 || req_count>8 || req_radius_q6<=0 || req_extent_q16>(32'd1*`Q_DRAFT_MAX_EXTENT_PIX<<16) ||
        {16'b0,req_radius_q6}<<10>req_extent_q16) begin rsp_fault<=1;state<=7;end
     else begin operand<=req_extent_q16-({14'b0,req_radius_q6}<<10);state<=1;end
    end
    1:begin limit<=square;state<=2;end
    2:begin operand<=$signed(local_xy[32*index+:32]);state<=3;end
    3:begin x_square<=square;operand<=$signed(local_xy[256+32*index+:32]);state<=4;end
    4:begin y_square<=square;state<=5;end
    5:begin
     if(norm_squared>{1'b0,limit}) begin rsp_fault<=1;state<=7;end
     else if(index+1==count) state<=7;
     else begin index<=index+1;state<=2;end
    end
    7:begin rsp_valid<=1;state<=0;end
    default:begin rsp_fault<=1;state<=7;end
   endcase
  end
 end
endmodule
