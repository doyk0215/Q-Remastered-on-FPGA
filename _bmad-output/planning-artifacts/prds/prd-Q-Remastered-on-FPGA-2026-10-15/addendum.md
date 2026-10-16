---
title: "PRD Addendum: Q Remastered on FPGA"
status: draft
created: 2026-10-15
updated: 2026-10-16
---

# PRD Addendum: Q Remastered on FPGA

This addendum preserves implementation context and choices for later architecture work. The PRD defines player-visible capabilities; this file records how the team currently expects to realize them and which technical details remain open.

## Source base

- The current project brief and the EE2026 Project Manual, pages 10–15, are the inputs for this PRD. The manual is treated as a course constraint source, not as instructions to change the game theme.

## Confirmed project and course context

- Target platform is the Basys3 FPGA, with the complete Interactive FPGA Design Project running in one bitstream.
- The Pmod OLED and Basys3 are compulsory. Course evaluation considers functionality, robustness and reliability, user interface, and user experience.
- The course manual says optional devices are not required for an excellent project and do not earn marks by themselves. A mouse is allowed. The project proposes VGA for the gameplay view; confirm the permitted/available lab VGA connection path.
- The live team demonstration is typically 2–5 minutes. Claims in the final report must match capabilities that work in the integrated bitstream.
- Carry the manual's delivery requirements into a separate project checklist: include one board-tested bitstream in the final archive, keep the archive at or below 500 MB unless prior approval is granted, verify the downloaded archive, and follow the final report's four-page format, word limits, references, AI-use disclosure, and peer-feedback requirements. These are course-delivery obligations rather than gameplay requirements.
- The current ownership split is: game/input control; physics and world state; graphics and displays. The game interaction path is mouse-only: the lobby, stage choices, drawing, and in-stage menu are controlled with the mouse; Basys3 switches and buttons are not game inputs. Shared coordinate, clickable UI, and object contracts should be agreed before integration.

## Current technical direction (proposals, not final architecture)

- Use signed fixed-point positions and velocities for the ball and released strokes, plus bounded orientation and angular-velocity state for released strokes.
- Apply gravity, predict motion, and detect collisions. Latch ball contact with the full left display boundary before left-wall position correction; report victory from that event. Correct positions and velocities as required for containment.
- Start with one ball and a few player-drawn objects. A released stroke is a bounded sampled polyline treated as one movable rigid body affected by gravity, collisions, and angular motion. Store its sampled geometry in body-local coordinates. Model each adjacent point pair as a capsule with the visual stroke's collision radius. Use eight sample points (seven capsules) as the provisional cap and validate it through synthesis and timing analysis.
- Rotation and angular collision response are included in the MVP for released strokes. An off-center collision should be able to change a stroke's angular velocity; the renderer should show its changed orientation. The ball's required visible motion is translational.
- A physics clock-enable near 60 updates per second is a candidate, subject to timing and resource validation.
- Keep dynamic world state with the physics/world-state component; let input/game control submit commands and let rendering consume a stable snapshot. Confirm exact module interfaces during architecture.
- Avoid assuming that a full-resolution double framebuffer fits. Select the VGA rendering and frame-consistency strategy after checking Basys3 memory and utilization.

## Technical questions for architecture and integration

- **Lab input note:** A wired Logitech mouse will be used; its exact model will be shared later. Confirm its connector/protocol, any required interface hardware, cursor range, and mapping between mouse coordinates and VGA/world coordinates before selecting the input implementation.
- **Lab display note:** The available VGA monitor connection or adapter is not yet known. Confirm it before choosing board connections and VGA timing.
- After the interface is identified, set cursor range and coordinate mapping for the playfield, lobby stage choices, and top-left pause control.
- Set fixed-point format, coordinate range, velocity limits, gravity scale, update timing, and overflow behavior.
- Include three built-in selectable MVP stages. Each stage attempt allows five submitted strokes, giving at most six moving bodies including the ball, and supports up to eight fixed obstacles. Validate the integrated workload with the provisional eight-point stroke cap. Stage 3 is the final stage.
- Fixed obstacles are limited to thick platforms and sloped ramps. Represent each as one static capsule with world-space endpoints and radius; their transforms stay fixed during play. The four display boundaries are separate from the eight-obstacle cap; the full left boundary is also the goal. Choose the level-data encoding during architecture.
- Validate released strokes against the current ball, existing strokes, and fixed obstacles before world insertion. Reject penetration without creating a body or consuming allowance; allow tangency. Disable pause while the left mouse button is held and do not queue requests from drawing. A drawing release never pauses, including over the pause icon. A separate pause-icon click after release can wait for an already in-flight admission to finish atomically. Include admission cost in the workload budget.
- Validate the provisional eight-sample cap, and set collision radius and fixed-point narrow-phase/contact-response implementation for capsule segments. Set center of mass, inertia approximation, angular impulse/torque response, broad-phase strategy, collision iteration limit, and penetration correction rule.
- Define level-data encoding and the command/snapshot interface among game control, physics, and renderer.
- Confirm VGA timing/output interface and available converter/monitor; confirm OLED screen layout and update ownership.
- Back to Lobby resets the current stage attempt before returning to the stage selector. The pause icon immediately pauses and reveals Resume, Reset Stage, and Back to Lobby options; course staff approved mouse-only game input.
- Validate the core integration milestone early: submit one drawn object, let it fall/collide with the ball, and detect ball contact with the left display boundary in the same bitstream.
