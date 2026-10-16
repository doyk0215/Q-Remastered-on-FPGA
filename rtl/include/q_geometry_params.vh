// Q Remastered on FPGA: reference-based initial geometry profile.
// Ball/stroke sizes follow the reference; fixed-geometry minimum is user adopted.
`ifndef Q_GEOMETRY_PARAMS_VH
`define Q_GEOMETRY_PARAMS_VH
`include "q_contract.vh"

`define Q_GEOMETRY_PROFILE_REV 16'h0003
`define Q_BALL_RADIUS_PIX 12
`define Q_BALL_DIAMETER_PIX (2 * `Q_BALL_RADIUS_PIX)
`define Q_BALL_RADIUS_Q6 18'sd768
`define Q_STROKE_RADIUS_PIX 8
`define Q_STROKE_THICKNESS_PIX (2 * `Q_STROKE_RADIUS_PIX)
`define Q_STROKE_RADIUS_Q6 18'sd512
// Total final sampled path length, independent of stroke thickness.
`define Q_STROKE_MIN_LENGTH_PIX 16
`define Q_STROKE_MIN_LENGTH_Q6 18'sd1024
`define Q_STATIC_MIN_RADIUS_PIX 8
`define Q_STATIC_MIN_THICKNESS_PIX (2 * `Q_STATIC_MIN_RADIUS_PIX)
`define Q_STATIC_MIN_RADIUS_Q6 18'sd512
`define Q_STATIC_DEFAULT_RADIUS_PIX `Q_STATIC_MIN_RADIUS_PIX
`define Q_STATIC_DEFAULT_RADIUS_Q6 `Q_STATIC_MIN_RADIUS_Q6
`define Q_BACKGROUND_RGB444 12'h000
`define Q_BALL_RGB444 12'hF0F
`define Q_STROKE_RGB444 12'hFFF

`endif // Q_GEOMETRY_PARAMS_VH
