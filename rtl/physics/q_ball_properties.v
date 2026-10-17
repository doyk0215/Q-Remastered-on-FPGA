`include "q_geometry_params.vh"
`include "q_numeric_params_draft.vh"
`include "q_physics_params.vh"
// Fixed adopted ball. Static geometry selects deliberately zero inverses.
// No arithmetic request can change radius/mass or insert a world object.
module q_ball_properties(
 input wire is_static,
 output wire [31:0] mass_q16,output wire [63:0] inertia_q16,
 output wire [47:0] inverse_mass_q32,output wire [47:0] inverse_inertia_q32
);
 localparam [63:0] M=((64'd1<<`Q_DRAFT_MASS_FRAC)*`Q_BALL_MASS_NUM)/`Q_BALL_MASS_DEN;
 localparam [63:0] I=(M*`Q_BALL_RADIUS_PIX*`Q_BALL_RADIUS_PIX)/2;
 localparam [63:0] N=64'd281474976710656;
 localparam [63:0] Q=N/I;
 localparam [63:0] R=N%I;
 localparam [63:0] INV=Q+((2*R>I) || (2*R==I && Q[0]));
 localparam [63:0] MQ=N/M;
 localparam [63:0] MR=N%M;
 localparam [63:0] MINV=MQ+((2*MR>M) || (2*MR==M && MQ[0]));
 assign mass_q16=M[31:0];
 assign inertia_q16=I;
 assign inverse_mass_q32=is_static ? 48'd0 : MINV[47:0];
 assign inverse_inertia_q32=is_static ? 48'd0 : INV[47:0];
endmodule
