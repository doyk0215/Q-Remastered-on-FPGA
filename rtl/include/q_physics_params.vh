// Q Remastered on FPGA: user-adopted initial physics tuning.
// Rational quantities below are not a universal internal fixed-point format.
// Consuming arithmetic, clamps and contact solver remain to be implemented.
`ifndef Q_PHYSICS_PARAMS_VH
`define Q_PHYSICS_PARAMS_VH
`include "q_contract.vh"

`define Q_PHYSICS_PROFILE_REV 16'h0001
`define Q_PHYSICS_SUBSTEPS 2

// Gravity: downward pixels per (1/Q_PHYSICS_HZ second outer update)^2.
// Divide its velocity increment by SUBSTEPS with fractional precision retained.
`define Q_GRAVITY_NUM 9
`define Q_GRAVITY_DEN 64

// Dimensionless contact coefficients; low-speed bounce threshold is still open.
`define Q_RESTITUTION_NUM 1
`define Q_RESTITUTION_DEN 8
`define Q_FRICTION_NUM 1
`define Q_FRICTION_DEN 2

// Relative mass: ball=1; uniform stroke wire mass=total length in pixels/64.
`define Q_BALL_MASS_NUM 1
`define Q_BALL_MASS_DEN 1
`define Q_STROKE_MASS_PER_PIXEL_NUM 1
`define Q_STROKE_MASS_PER_PIXEL_DEN 64

// One combined translation/rotation geometric point-travel budget.
`define Q_MAX_POINT_TRAVEL_SUBSTEP_PIX 4
`define Q_MAX_POINT_TRAVEL_OUTER_PIX \
    (`Q_MAX_POINT_TRAVEL_SUBSTEP_PIX * `Q_PHYSICS_SUBSTEPS)

`endif // Q_PHYSICS_PARAMS_VH
