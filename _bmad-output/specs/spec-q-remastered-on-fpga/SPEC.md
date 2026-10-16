---
id: SPEC-q-remastered-on-fpga
created: 2026-10-16
updated: 2026-10-16
companions:
  - module-contracts.md
  - geometry-profile.md
  - rotation-fixture.md
  - stage-layouts.md
  - prototype-gates.md
  - delivery-requirements.md
  - ../../planning-artifacts/architectures/architecture-Q-Remastered-on-FPGA-2026-10-15/ARCHITECTURE-SPINE.md
  - ../../planning-artifacts/ux-designs/ux-q-remastered-on-fpga-2026-10-15/EXPERIENCE.md
  - ../../planning-artifacts/ux-designs/ux-q-remastered-on-fpga-2026-10-15/DESIGN.md
sources:
  - ../../planning-artifacts/prds/prd-Q-Remastered-on-FPGA-2026-10-15/prd.md
  - ../../planning-artifacts/prds/prd-Q-Remastered-on-FPGA-2026-10-15/addendum.md
---

# Q Remastered on FPGA — Specification

This kernel and its companions are the complete downstream contract. CAP identifiers are stable; the adopted architecture retains AD-1 through AD-12. Historical open labels in UX do not reopen technical decisions already settled by those ADs. Prototype questions below remain unresolved.

## Why

Realize a mouse-driven drawing-and-physics puzzle on Basys3 for first-time players and an EE2026 live assessment. A player should see how an accepted drawing changes the ball's motion, recognize a win, and retry or choose another stage in one integrated bitstream.

## Capabilities

- **CAP-1 — Select and launch a stage**
  - **intent:** The player can choose a puzzle from the startup lobby.
  - **success:** All three stage choices are mouse-clickable on VGA; choosing one loads its ball, obstacles, objective and five-stroke allowance and starts play without another Start action or reprogramming.

- **CAP-2 — Pause and resume**
  - **intent:** The player can freeze and resume the current attempt.
  - **success:** Pause is disabled while the left button is held, with no queued draw-time pause; drawing release never pauses even over the icon. A separate completed pause-icon click freezes after any in-flight admission completes atomically. Resume preserves the attempt; outside-menu clicks leave it paused.

- **CAP-3 — Reset or return to the lobby**
  - **intent:** The player can retry or choose another stage within the running game.
  - **success:** Reset restores the initial stage, clears accepted strokes and restores five allowance. Back to Lobby discards the attempt and returns to selection; lobby remains reachable after victory.

- **CAP-4 — Capture a visible stroke**
  - **intent:** The player can position a visible cursor and draw a proposed stroke.
  - **success:** Cursor and preview match the playfield; continuous simplification retains the start, endpoint and significant bends within eight points. The displayed collision shape is the one submitted on release; fine curves may straighten.

- **CAP-5 — Admit or reject a stroke**
  - **intent:** The player can release a stroke that becomes a movable object when valid.
  - **success:** Validate final geometry against the current ball, accepted strokes and fixed obstacles. Reject penetration without a body, impulse or charge, clear preview and show Stroke overlaps an object; permit tangency. Accepted strokes persist, fall and interact, including rotation; input with fewer than two distinct vertices or final sampled path length below 16 pixels is rejected without charge.

- **CAP-6 — Enforce drawing allowance**
  - **intent:** The player can see and stay within the allowed number of accepted strokes.
  - **success:** Each attempt permits five accepted strokes; debit once per accepted acknowledgement, never on rejection. Additional creation is blocked at zero, OLED shows zero and VGA briefly shows No strokes left.

- **CAP-7 — Advance motion**
  - **intent:** The player can observe gravity-driven translation and stroke rotation.
  - **success:** During active play the ball and accepted strokes move under gravity; strokes with angular motion visibly change orientation. Paused and completed attempts do not advance.

- **CAP-8 — Resolve collisions and contain bodies**
  - **intent:** The world can respond to contacts among its moving objects, obstacles and walls.
  - **success:** Ball/stroke and stroke/stroke contacts alter motion; fixed platforms/ramps and all four walls keep supported bodies contained, with low-bounce response. A prepared off-center impact visibly changes a stroke's angular motion; supported stage interactions do not visibly tunnel through solids.

- **CAP-9 — Detect stage completion**
  - **intent:** The player can complete a stage by guiding the ball to the left edge.
  - **success:** Any ball touch or overlap with the full left boundary wins at any height, including tangency. Other edges and stroke-only contact do not win; correction preserves the winning event and the attempt stops.

- **CAP-10 — Communicate state and victory choices**
  - **intent:** The player can identify active play, pause and completion and choose what follows.
  - **success:** VGA and OLED distinguish those states; the completed scene remains until a choice. Stages 1/2 offer Next Stage and Back to Lobby; stage 3 offers Back to Lobby. Victory never auto-advances.

- **CAP-11 — Render the interaction surface**
  - **intent:** The player can see and operate the game on VGA.
  - **success:** Full-view VGA shows lobby choices or the magenta ball, white user-drawn strokes, fixed obstacles, marked goal edge, cursor and top-left two-bar pause control, with pause/victory menus as overlays. Objects and actions remain distinguishable using readable text and non-colour cues.

- **CAP-12 — Present supporting information**
  - **intent:** The player can read the stage, objective, allowance and state on the OLED.
  - **success:** The 96x64 colour OLED shows the selected stage, Touch the left edge, accepted strokes remaining and current status, with wrapping as required; stage selection stays on VGA.

- **CAP-13 — Indicate state on LEDs**
  - **intent:** The player can observe pause and victory on board LEDs.
  - **success:** LED indications change for pause and victory; displays also explain the state so LEDs are not the only feedback.

## Constraints

- Run on one Basys3 xc7a35tcpg236-1 in Vivado 2025.2; application HDL is Verilog, with supplied/public sources in other HDLs permitted. Preserve provenance and redistribution notices.
- Mouse-only gameplay follows the recorded staff-approved exception to the course's switch requirement. Keep OLED and LED status; switches/buttons are not game controls.
- Reference-based initial geometry: magenta ball diameter 24/radius 12 pixels, white stroke thickness 16/capsule radius 8 pixels; exact Q6 defaults and source proportions are in geometry-profile.md.
- Fixed platform/ramp capsules have minimum thickness 16 pixels (radius 8), also the default; individual obstacles may be thicker.
- Initial physics tuning uses downward gravity 9/64 pixels per 60-Hz outer-update², restitution 1/8 and common contact friction 1/2. q_physics_params.vh publishes these tunable defaults; behavior and arithmetic still require G-3 evidence.
- Use ball mass 1 and stroke mass equal to total admitted sampled-polyline length in pixels divided by 64; geometry-profile.md specifies the relative scale. Internal mass/inertia arithmetic remains a prototype obligation.
- Bound integrated ball-center and stroke-point travel to 4 pixels per physics substep; translation and rotation share the budget defined in geometry-profile.md. Enforcement and collision coverage remain prototype obligations.
- Each stage starts with the ball at rest on a fixed support platform (initial linear velocity zero); gravity remains active and the platform provides physical support. Exact layouts remain open.
- Three built-in stages; one ball, at most five accepted strokes and eight fixed capsule platforms/ramps per attempt. Four walls are separate. Each stroke is one rotating rigid body with at most eight sampled vertices.
- Share the 640×480 upper-left coordinate system and signed 18-bit, six-fraction-bit geometry/linear-state format. Follow the adopted architecture for other scales, physics cadence, ownership, clocks, drivers, reliable events and frame consistency.
- The finalized architecture's AD rules and revision 2 shared Verilog declarations bind all implementations. Use q_contract.vh/q_ports.vh, q_geometry_params.vh and q_physics_params.vh through the module/geometry companions; consuming modules and common physical parameters must still pass G-1 before integrated RTL is accepted.
- Measure achieved responsiveness, aggregate utilization and worst-case timing before making final performance or fit claims. Preserve reliable reset/retry and one-bitstream operation when limiting scope.
- Apply the adopted UX's restrained retro arcade palette, bitmap typography, non-colour cues, mouse gestures and screen roles. Release obligations are in delivery-requirements.md.

## Non-goals

- Unlimited points, strokes or stages; physically exact or general-purpose physics; unrestricted high-speed motion.
- Multiple FPGA boards, network play or a computer-hosted gameplay runtime.
- Additional keyboard, switch, button or touch gameplay controls, or unrelated device/effect additions.
- Features or report claims unsupported by the final integrated bitstream.

## Success signal

- In a typical 2–5 minute board demonstration, a player selects a stage, draws an accepted object, sees gravity/contact and visible off-center stroke rotation, wins by ball contact with the left edge, and uses pause/resume/reset/lobby/victory navigation without a board reset or reprogramming.
- All three stages are selectable and demonstrably solvable; invalid strokes preserve allowance; VGA/OLED/LED feedback agrees; the delivered integrated bitstream fits the board and its recorded behavior supports every report claim.

## Assumptions

- Prototype seeds: two full-resolution one-bit image banks with magenta overlays, a 4096×18 sine table, two internal substeps per 60 Hz outer update, and a tunable one-second visible-feedback duration. These have not been established by synthesis or board measurements.
- Optimize for a first-time short live demo with legible cause/effect and calm, brief success feedback; “Alex” in the UX is illustrative, not a researched persona.

- Revision2 engineering seeds: 32-bit identifiers, fixed enum/record packing, stage keys 0..2, body numbering, zero initial ball spin and normal LED bits 0/1. These declarations are published; their consuming behavior is unvalidated.

## Open Questions

- Do consuming modules implement the published Verilog-2001/revision 2 record, ready/valid, cancellation, identity-retirement and mailbox contracts, with physical parameters shared through G-1/G-3/G-4?
- Which physics parameter/scaling/contact/solver/speed settings meet G-3's bounded workload and supported stage behavior? The adopted starting gravity/contact values in geometry-profile.md still require arithmetic and response validation.
- Which simplifier, stroke thresholds, common hit regions, font/layout and rendering/CDC implementation pass G-4/G-5?
- Which exact Logitech mouse and active VGA-to-HDMI converter are available, and do they work with the supplied/chosen drivers? Which third-party source commits and clock configurations pass G-2?
- Do the adopted off-centre beam-drop target and initial coordinate seed in rotation-fixture.md produce repeatable contact-driven rotation/ball impact? Do the three adopted stage concepts and proposed scenes in stage-layouts.md provide reproducible solutions within five accepted strokes, including leftward transfer from the Stage 3 beam?
- What responsiveness/resource/timing measurements and exact course word/layout/submission requirements will G-7/G-8 record before claims and release?

