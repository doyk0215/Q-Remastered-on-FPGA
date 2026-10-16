# Rotation Fixture — Off-Centre Beam Drop

## Decision and status

The user adopted the off-centre beam drop as the prototype rotation demonstration. The coordinates below are an initial engineering seed for implementation review. Dynamic behavior, repeatability and ball impact remain unvalidated. This development fixture does not add a selectable fourth stage or establish a solution to the left-edge goal.

## Initial geometry

Use the shared 640×480 coordinate system (x right, y down); integer pixel values become Q6 by multiplying by 64. All radii follow geometry-profile.md.

| Item | Geometry in pixels | Initial state |
| --- | --- | --- |
| Pedestal | Capsule (304,320) → (336,320), radius 8 | Fixed |
| Ball support | Capsule (416,372) → (480,372), radius 8 | Fixed |
| Ball | Centre (432,352), radius 12 | At rest; mass 1 |
| Player beam | Two-point stroke (272,240) → (432,240), radius 8 | Submit through ordinary stroke admission; fixture seed uses zero release velocity/spin |

Both supports count toward the maximum eight fixed capsules. The beam uses one accepted stroke, leaving four of the five allowance. Use the specified final two-point geometry for deterministic reproduction; manual tracing is an approximation until capture/simplification thresholds are finalized.

### Derived beam properties

- Sampled centerline length: 160 pixels.
- Mass: 160/64 = 2.5 ball-mass units.
- Centre of mass: (352,240); local endpoints (-80,0) and (80,0).
- Uniform-wire inertia about that centre: mL²/12 = 16000/3 mass-pixel², before the selected internal representation/rounding.
- The pedestal's straight top section ends at x=336, to the left of the beam's mass centre x=352. The intended initial support impulse is off-centre.

The ball starts tangent to its support: centreline separation 372−352=20 pixels equals radius sum 8+12. The beam begins 64 pixels clear of the pedestal surfaces: 320−240−8−8. These are design calculations, not a simulation result.

## Intended sequence

1. Begin with the ball supported at rest and the two fixed capsules loaded.
2. Admit the horizontal beam through the same validation/accounting path as a player stroke.
3. Gravity brings the beam onto the pedestal. The off-centre contact should change its angular velocity and tip its right end downward.
4. The right end is intended to strike the ball, transferring momentum while the beam continues to translate/rotate.

The pedestal is a collision body, not a hinge. The solver may allow sliding or contact changes; the proposed coordinates must demonstrate the intended sequence before being treated as reproducible. Rotation comes from physical contact impulses, not a scripted pose change or preset angular kick.

## Evidence required later

- Admission accepts non-overlapping geometry and consumes exactly one stroke.
- Record the beam pose/angular velocity immediately before and after off-centre contact; show visible rotation from an initially nonrotating stroke.
- Show an actual subsequent beam/ball contact and corresponding ball motion. Revise the coordinate seed if contact does not occur reliably.
- Enforce the adopted shared translation/rotation limit of 4 pixels per substep, with containment and coherent snapshots.
- Repeated identical initial data and accepted samples produce a consistent result under the deterministic solver order.
- Any future measured trajectory records the gravity, contact coefficients, internal precision, speed-limit handling and solver settings used.

Use adopted initial gravity 9/64 pixels per 60-Hz outer-update², restitution 1/8 and friction 1/2 from q_physics_params.vh; record any subsequent tuning. The fixture's 160-pixel sampled beam exceeds the adopted 16-pixel minimum stroke length. Numerical floors, ball angular limit, contact tolerances, correction/solver bounds and hardware timing remain G-3 obligations. Successful rotation does not establish a left-edge win or validate all three stages.

No tests, simulation, synthesis or board execution were performed when specifying this fixture.
