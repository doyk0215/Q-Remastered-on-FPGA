# Prototype Gates

Derived from architecture AD-12 and its Deferred and Prototype Gates. These are future evidence checkpoints. No prototype execution, code tests, synthesis, routing or board acceptance was performed by creating this spec.

## G-1 — Adopt and implement the published common definition

- **Owner:** Integration with input, controller, physics and graphics.
- **Published:** [q_contract.vh](../../../rtl/include/q_contract.vh) and [q_ports.vh](../../../rtl/include/q_ports.vh), revision 2. Verilog-2001 packing, widths/IDs/enums, core ready/valid channels, separate create/control slots, terminal results, counter-retirement policy and frame/epoch/OLED mailbox semantics are in module-contracts.md.
- **Before:** Independent interface RTL uses the common declarations; integration-dependent stories implement the corresponding protocol.
- **Remaining evidence:** All consuming modules include this revision, use exact roles/fields and demonstrate receipt/completion distinction, arbitration, cancellation/drain, duplicate accounting, coherent joins, startup and safe bank release. q_geometry_params.vh publishes the reference-based ball/stroke dimensions, and FramePacket carries matching magenta-ball geometry. No consuming module/CDC/reset behavior has been implemented or compiled by publishing these declarations.
- **Parameter dependency:** Ball/stroke defaults and the fixed-capsule minimum/default radius 8px are published in geometry-profile.md/q_geometry_params.vh (geometry profile revision 3). q_physics_params.vh (physics profile revision 1) now publishes adopted gravity 9/64, restitution 1/8, friction 1/2, mass scale, two substeps and 4px point-motion budget. Internal gravity/contact/mass/motion-limit arithmetic, thicker per-stage obstacle radii and UI sampling/layout still come from G-3/G-4. Publish them centrally before dependent integration; do not invent defaults or privately hard-code values.
- **Completion boundary:** Declarations are ready for implementation review; G-1 behavioral acceptance and the later hardware gates remain open.

## G-2 — Establish peripheral and clock readiness

- **Owner:** Integration and relevant adapter owner.
- **Before:** Peripheral/scanout integration and hardware claims.
- **Produce:** Supplied-driver baselines matching adopted hashes; exact imported third-party commits/licenses, HDL/build mode, clock/reset circuit and active XDC.
- **Acceptance evidence:** Mouse runs its supplied 100 MHz protocol pair with explicit cursor initialization and bounds 639/479, preserves 12-bit interfaces and accounts for 40 reports/s. Activate/audit PS/2 clock/data pull-ups. OLED is the supplied 96×64 colour/16-bit driver at 6.25 MHz with its negedge pixel timing satisfied. VGA is 640×480p60/25.2 MHz through the external active converter. Clock generation/global routes and constraints are explicit; do not assume one MMCM suffices.
- **Open:** Exact Logitech/converter models and physical compatibility; source pins; reset/CDC primitives and build manifest. Driver presence and an empty supplied top are not integration evidence.

## G-3 — Bound physics and numerical behavior

- **Owner:** Physics with integration.
- **Before:** Physics RTL contract freeze and dependent level/render integration.
- **Produce:** One parameter/scaling set using the selected ball radius 12, stroke radius 8 and relative mass scale (ball=1; stroke=total polyline length in pixels/64), using adopted gravity 9/64 pixels per outer-update², restitution 1/8 and contact friction 1/2, plus any static radii above the selected 8px minimum/default, the adopted minimum sampled path length 16px/Q6=1024, positive mass/inertia floors, inverse properties, phase/trig/normal/impulse widths, rounding/rescaling/saturation, speed limits, contact tolerances/seam handling, contact storage/overflow, solver/correction limits and warm-start policy.
- **Acceptance evidence:** Signed Q6 geometry is consistent externally; widen accumulated polyline length and mass moments. Physics transforms the same local samples used for collision and display after every pose change. Low-bounce/friction response supports containment, rolling/contact and visible stroke rotation. Shared kernels complete the bounded schedule at 60 Hz without hidden unbounded iterations or dropped necessary contacts.
- **Load profile:** Five strokes × seven segments plus eight static capsules yields 813 candidate pairs per full scan, excluding walls; one admission adds at most 259. Two complete substep scans yield 1626 plus admission before solver work. Include boundaries, integration, transforms, corrections, event publication and any shared arithmetic arbitration. Counts are not cycle measurements.
- **Seed:** Two internal steps per 60 Hz outer tick and lookup rotation. The adopted motion budget is 4px per substep for the ball center or any occupied stroke point, combining translation and rotation (||v||+|omega|R ≤ 8px per outer-update). Enforce after force/impulse changes with numeric guards; ball angular limits and correction-motion accounting remain open. Check against the adopted 16px minimum fixed-feature thickness, actual stage geometry and intended contacts. Discrete substeps do not guarantee every grazing contact; revisit swept collision if intended stages still tunnel.
- **Failure rule:** Do not start overlapping world updates or enlarge the timestep to hide lateness. Retain the last complete world and expose diagnostics; sustained misses fail the 60 Hz acceptance target.

## G-4 — Freeze capture and common UI geometry

- **Owner:** Input and graphics with controller/physics.
- **Before:** Input/display stories that depend on sampling, thresholds or hit regions.
- **Produce:** Deterministic endpoint-preserving simplification/tie-breaking, duplicate/short-stroke handling for the selected 16px minimum path length, deterministic length/threshold rounding, sampling threshold, shared fonts/hit regions/layout and invalid-input feedback.
- **Acceptance evidence:** At most eight displayed/submitted vertices; fine-detail loss is visible during capture; the admitted samples/radius equal the proposed preview. Final sampled path length below 16px or fewer than two distinct points rejects without charge; exact equality passes the length criterion, subject to other admission rules. UI press/release is consumed once and cannot become a stroke. Held-left pause is disabled and never queued; draw release over the icon does not pause.
- **UX floor:** Black/white/magenta retro arcade, pixel bitmap headings/readable labels, non-colour distinctions for goal/ball/stroke/cursor/preview/status, top-left two-bar pause icon, full VGA view without a permanent status strip. OLED objective wraps where needed; do not assume a 19-character string fits one 96-pixel line.

## G-5 — Bound image generation and frame transfer

- **Owner:** Graphics with integration and controller.
- **Before:** Graphics implementation tasks are finalized.
- **Produce:** Bank packing/ports, clear/rasterization schedule, bounded magenta ball/UI logic, frame-local snapshot/overlay assembly, ownership handshake and pixel/sync alignment.
- **Acceptance evidence:** No front-bank writes; only complete matched frames swap. The magenta ball is composited from FramePacket.ball/has_ball matched to that bank, never from live physics coordinates. UI/world revision barrier and presented view identity work for active play, paused UI refresh, reset and stale commands. Feedback lifetime starts on visible presentation; slow rendering repeats the prior complete image while physics retains ownership.
- **Memory seed:** Two 640×480 one-bit banks contain 75 KiB of image data; actual BRAM allocation is larger. A 4096×18 table adds 9 KiB payload. Budget contact records, tables, fonts, status and all allocation overhead together against raw 225 KiB board BRAM. A single 12-bit image would need 450 KiB; two 2-bit palette banks would need 150 KiB, not 300 KiB.
- **Revisit:** If resources/throughput fail, reassess working buffer/rotation seeds while preserving shared units, snapshot semantics and approved visual behavior. A complex preview may be a distinguishable white pattern; magenta overlay does not imply a second full arbitrary-colour image.

## G-6 — Select the rotation fixture and validate stages

- **Owner:** Level/controller and physics.
- **Before:** Use the adopted off-centre beam-drop demonstration target in rotation-fixture.md for story planning; establish repeatability and validate all stage solutions before demo acceptance.
- **Selected fixture:** rotation-fixture.md specifies the adopted method and an unvalidated initial coordinate seed. Contact must generate the beam's angular motion and intended ball impact; no scripted rotation or hinge. The seed is a development fixture, not an additional selectable stage or proven solution.
- **Stage draft:** stage-layouts.md records all three adopted concepts and proposed scenes: Stage 1 push/ramp (two fixed capsules), Stage 2 supported bridge (five) and Stage 3 off-centre beam drop toward the left goal (three). Nudge/settling/contact/rotation transfers, joins and full solutions remain unvalidated.
- **Produce:** Three initial ball/obstacle layouts using shared units and limits, each with the ball at rest on a fixed support platform (zero initial linear velocity/spin), plus recorded solution/rotation conditions. Gravity remains active; stable contact provides support.
- **Acceptance evidence:** All stages are selectable/solvable; each has one ball, at most eight fixed capsules, five accepted strokes and the same left-boundary goal. Show a repeatable collision changing a stroke's angular motion and orientation.
- **Open:** All three gameplay stages and the development rotation fixture have proposed coordinates only; final coordinates/support lengths, any thicker obstacle radii and demonstrated solutions remain open; minimum/default fixed radius is selected as 8px; the supported-at-rest ball start and zero initial velocity are selected; the common ball/stroke radii are in geometry-profile.md. Exact scene choices are engineering input, not invented completed levels in this spec.

## G-7 — Establish integrated board evidence

- **Owner:** Integration with all subsystem owners.
- **Before:** Final capability/performance claims or release.
- **Produce:** One working bitstream; achieved cursor/drawing/render/update responsiveness, aggregate LUT/FF/DSP/BRAM utilization and timing reports, worst-case physics/admission/frame measurements and peripheral compatibility evidence.
- **Acceptance evidence:** Lobby → draw/admit → gravity/contact/rotation → goal, pause/resume, rejected strokes, exhausted allowance, reset/lobby and all victory choices work together without board reset or reprogramming. Pause works only from a fresh click after release. Reset and stale events cannot charge a new attempt; goal tangency survives correction. Other edges/strokes do not win. OLED/LED status agrees with the controller.
- **First milestone:** One drawn object falls/collides with the ball and triggers a left-edge goal check in the same bitstream; the complete scope also needs visible rotation.
- **Scope guard:** Preserve a reliable working integrated build rather than add unproven stages, strokes or effects.

## G-8 — Release the assessed project

- **Owner:** Team release coordinator.
- **Before:** Submission and the course demonstration.
- **Produce/accept:** Complete the concrete obligations in delivery-requirements.md using the G-7 bitstream and measured evidence.

