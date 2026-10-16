# Geometry Profile — Reference-Based Defaults

Selected from the user's supplied screenshot on 2026-10-16. The user identifies the magenta ball as the moving object that must touch the left boundary and the white curve as a user-drawn rigid body.

[Original reference](../../planning-artifacts/ux-designs/ux-q-remastered-on-fpga-2026-10-15/imports/object-scale-reference.png)

## Proportion measurement

Measure the inside of the white playfield walls, excluding the side controls, stream chat, logo and face camera. On an unobscured row, walls occupy x=243..257 and x=1592..1607, giving an interior width of 1334 pixels. The source image is 1879×1048. Ball edge antialiasing gives roughly 49–51 pixels in diameter; the central, nearly horizontal white stroke is 35 pixels thick.

Use one uniform scale based on playable width: 640/1334≈0.480. The visible height/framing differs slightly from VGA's 4:3 aspect, so do not independently stretch circles in x/y.

| Item | Reference | Width-scaled to VGA | Selected initial value |
| --- | ---: | ---: | ---: |
| Ball diameter | About 50 px | About 24 px | 24 px; radius 12 |
| Stroke thickness | About 35 px | About 16.8 px | 16 px; capsule radius 8 |

Round the stroke to an even thickness for an integer-pixel radius. These replace the earlier unadopted 20-pixel ball/6-pixel stroke proposal. They are tunable prototype defaults selected from the visual proportions, not measured gameplay-optimal values. Pixel coverage at antialiased/quantized edges is approximate.

## Shared values

Use [q_geometry_params.vh](../../../rtl/include/q_geometry_params.vh) in input/preview, physics/level admission and graphics; avoid private radius constants. [q_physics_params.vh](../../../rtl/include/q_physics_params.vh), physics profile revision 1, publishes the adopted gravity, contact coefficients, mass scale, substep count and motion budget as rational quantities or integer pixel bounds. Internal arithmetic formats remain separate G-3 work.

| Parameter | Pixels | Signed 18-bit Q6 stored value |
| --- | ---: | ---: |
| Ball radius | 12 | 768 |
| Stroke capsule radius | 8 | 512 |
| Fixed capsule minimum/default radius | 8 | 512 |

The ball is magenta (#FF00FF; RGB444 F0F); accepted user strokes are white (#FFFFFF; RGB444 FFF) on black. Each adjacent sampled-point pair remains a capsule, and the whole stroke remains one rigid body with at most eight vertices. The screenshot's smooth curve does not remove that simplification limit.

## Adopted fixed-geometry thickness

Fixed platforms and ramps use capsule radius **at least 8 pixels** (minimum full thickness **16 pixels**), with radius 8 as the default. Stages may use thicker capsules; collision, display and admission use each obstacle's actual radius.

The minimum/default is published in q_geometry_params.vh, geometry profile revision 3: Q_STATIC_MIN_RADIUS_PIX=8, Q_STATIC_MIN_RADIUS_Q6=512 and Q_STATIC_DEFAULT_RADIUS_PIX=8. This does not change the revision 2 packed-message layout. Stage endpoints, support lengths and any thicker per-obstacle radii remain to be selected. The minimum applies to fixed capsules, not decorative boundary pixels or the stroke's centerline length.

## Magenta ball with monochrome banks

- Keep the two one-bit banks for white strokes, fixed geometry and background; image payload remains 75 KiB.
- Draw the ball as a simple magenta circle using the same snapshot's center and radius. FramePacket now includes ball geometry plus has_ball, making its revision 2 width 626 bits instead of 571.
- Omit the moving ball from the white mask so differing base/overlay coverage cannot leave a white halo. Compose its circle before goal/control/menu/feedback/cursor layers, respecting the adopted overlay priority.
- Hold this ball metadata with the bank until frame presentation/ownership acknowledgement. Never use live physics coordinates on an older completed frame.
- The initial profile does not require a second colour framebuffer. Circle coverage, subpixel rounding and pipeline throughput still need the graphics prototype.

## Initial stage setup

The user adopted a ball initially at rest on a fixed support platform. All MVP stage definitions use zero initial linear velocity; initial spin is also zero. The support keeps the ball in place through ordinary contacts while gravity remains active, giving the player time to draw. Choose stable support geometry without initial penetration or left-edge goal contact. Coordinates and support lengths remain open; supports obey the selected 16-pixel minimum thickness. This is not a completed level layout.

## Adopted minimum stroke length

The final admitted sampled-polyline path must have total length **at least 16 pixels** (Q6 length 1024). Sum segment lengths; do not use endpoint separation, vertex count, mouse travel before simplification or the stroke's thickness.

Input/preview and authoritative physics admission use Q_STROKE_MIN_LENGTH_PIX/Q6 from q_geometry_params.vh, geometry profile revision 3. Reject paths below the threshold, or fewer than two distinct points, without inserting a body, applying an admission impulse or consuming allowance. Use the existing REJECTED/DEGENERATE result. The equality case is valid with respect to length; overlap/state/allowance rules still apply.

The adopted mass scale gives a 16-pixel path mass 0.25 before internal arithmetic representation. This does not select inertia floors or prove stability. Shared deterministic length approximation/rounding and threshold-edge handling remain G-3/G-4 implementation work.

## Adopted relative mass scale

Normalize ball mass to 1. A stroke's mass is its total admitted sampled-polyline length in pixels divided by 64: uniform wire density is 1/64 ball-mass units per pixel.

| Object | Relative mass |
| --- | ---: |
| Ball | 1 |
| 64-pixel stroke | 1 |
| 128-pixel stroke | 2 |
| 256-pixel stroke | 4 |

Use total segment length, not endpoint separation or vertex count. Retain the architecture's length-weighted center of mass and shape-derived wire inertia, computed once at admission. Static geometry has zero inverse mass/inertia. This is an adopted prototype density scale, not a recovered video setting. Minimum accepted length is 16 pixels; positive mass/inertia floors, reciprocal representation, arithmetic widths and rounding still require G-3 decisions. The scale alone does not establish a safe range of mass ratios.

## Adopted geometric motion limit

The prototype allows at most **4 pixels of integrated point travel per 1/120-second substep**, with two substeps per 60 Hz outer update. Apply this to the ball center and every occupied point of a rotating stroke.

- Translation and rotation share one budget. A conservative bound is ||v|| + |omega|R ≤ 8 pixels per outer-update, where omega is in radians per outer-update and R bounds collision extent about the stroke's center of mass.
- Pure translation may reach 8 pixels per outer-update (480 pixels/s). Do not grant both full translation and full rotational point travel independently.
- Include gravity and collision-induced velocity changes before integration. Retain numeric guard margins for transforms, rescaling and rounding. Implementing the clamp and accounting for correction-induced motion remain G-3 work.
- Circle spin does not change the ball's occupied geometry; a separate ball angular/contact-stability limit remains open.
- Two moving bodies can have up to 8 pixels of relative integrated point travel per substep. Compare against actual collision feature thickness, including the adopted 16-pixel minimum for fixed capsules.
- This is an adopted prototype budget. It reduces large discrete movements but does not prove all grazing contacts will be detected. Stage validation may require stricter limits or swept collision; the [Box2D discussion of tunneling](https://box2d.org/documentation/md_simulation.html#bullets) describes the underlying discrete-motion issue.

## Video reference and adopted starting physics tuning

[User-supplied gameplay video — Q.5 around 3:07–3:09](https://www.youtube.com/watch?v=LJtO2IOzxjU&t=187s), inspected in Chrome after the Mac was unlocked. The curved drawn body visibly rotates and lifts the ball, followed by airborne motion. Reproduce momentum transfer through rotating rigid-body contacts; a strong upward launch need not imply high restitution.

### Rough gravity estimate

YouTube playback statistics reported 1920×1080 at 60 fps. Step 15 frames per sample, confirming 0.25-second timestamp spacing. Approximate manually read ball-center positions on the same fixed screenshot view were:

| Video time (seconds) | Screenshot center y (pixels, downward) |
| ---: | ---: |
| 188.67 | 1243 |
| 188.92 | 1181 |
| 189.17 | 1219 |

The interior playfield was about 2016 screenshot pixels wide. For this airborne portion, infer constant downward acceleration from the second difference:

- Screenshot second difference: 1243 − 2×1181 + 1219 = 100 pixels.
- Normalize to VGA width: 100 × (640/2016) / 0.25² ≈ 508 pixels/s².
- Report this as **roughly 500 pixels/s²**, not a recovered engine constant. Manual position readings, video edits/capture timing and the short observation window limit precision; this does not establish the original engine or its solver.

### Adopted tunable starting values

| Parameter | Initial value | Basis |
| --- | --- | --- |
| Downward gravity | 9/64 = 0.140625 pixels per outer-update² | At 60 Hz this is 506.25 pixels/s², near the rough video estimate. |
| Restitution | 1/8 = 0.125 | Engineering seed for the existing low-bounce requirement; not measured from this video. |
| Common contact friction | 1/2 = 0.5 | Engineering seed for moderate friction; not measured from this video. |

The idealized continuous-time fall from rest over 200 pixels takes sqrt(2×200/506.25) ≈ 0.89 seconds before contact or speed limiting. The adopted gravity replaces the earlier 0.7-second fall suggestion. The idealized time is a reference calculation, not a required measured trajectory. The constants are published in q_physics_params.vh; no consuming physics implementation is established by that declaration.

For two equal substeps, the gravity-induced velocity increment per substep is 9/128 pixels per outer-update. Retain sufficient internal precision or fractional remainders; rounding that increment independently to whole Q6 units would change gravity. Wider physics calculations remain G-3 work and do not change the published 18-bit Q6 interface.

The [Box2D simulation documentation](https://box2d.org/documentation/md_simulation.html) supports using a fixed timestep and distinguishes contact friction, bounce/restitution and damping. It does not identify the video's physics engine or prescribe these selected values. The relative mass scale above is adopted; mass-ratio bounds and minimum-length arithmetic, friction/restitution response validation, motion-limit enforcement and ball angular limits, damping, contact tolerances and solver bounds remain open.

## Still open

The relative mass scale is selected independently of the reference. Fixed-platform/ramp endpoints, lengths and any thicker radii, gravity/contact arithmetic and response validation, minimum-stroke-length arithmetic, mass/inertia floors and motion-limit enforcement/ball angular limits remain open. Set them at G-3 using these selected ball/stroke radii and actual minimum collision feature thickness. Boundary decoration remains visual; the left goal is still x=0, and only the ball can win. The screenshot's incidental UI does not add keyboard controls or change the approved mouse gestures.

No compilation, simulation, synthesis or board validation is claimed by this profile.
