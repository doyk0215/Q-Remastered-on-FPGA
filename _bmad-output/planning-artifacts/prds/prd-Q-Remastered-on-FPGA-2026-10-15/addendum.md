---
title: "PRD Addendum: Q Remastered on FPGA"
status: draft
created: 2026-10-15
updated: 2026-10-15
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
- Apply gravity, predict motion, detect collisions, correct positions/velocities, and then evaluate the goal.
- Start with one ball and a few player-drawn objects. A released stroke is a movable physics object affected by gravity and collisions. Approximate its bounded geometry as a chain of small circles if resource measurements support it.
- Rotation and angular collision response are included in the MVP for released strokes. An off-center collision should be able to change a stroke's angular velocity; the renderer should show its changed orientation. The ball's required visible motion is translational.
- A physics clock-enable near 60 updates per second is a candidate, subject to timing and resource validation.
- Keep dynamic world state with the physics/world-state component; let input/game control submit commands and let rendering consume a stable snapshot. Confirm exact module interfaces during architecture.
- Avoid assuming that a full-resolution double framebuffer fits. Select the VGA rendering and frame-consistency strategy after checking Basys3 memory and utilization.

## Technical questions for architecture and integration

- Confirm mouse protocol, connector, cursor range, and mapping between mouse coordinates and VGA/world coordinates, including lobby stage choices and the top-left in-stage menu.
- Set fixed-point format, coordinate range, velocity limits, gravity scale, update timing, and overflow behavior.
- Set maximum levels, strokes, sampled points per stroke, circles per stroke, and simultaneous physics objects; derive these from utilization and collision cost.
- Choose how to represent and transform bounded released-stroke geometry as a rotating movable physics object. Choose center of mass, supported collision shapes, inertia approximation, angular impulse/torque response, broad-phase strategy, collision iteration limit, and penetration correction rule.
- Define level-data encoding and the command/snapshot interface among game control, physics, and renderer.
- Confirm VGA timing/output interface and available converter/monitor; confirm OLED screen layout and update ownership.
- Back to Lobby resets the current stage attempt before returning to the stage selector. The pause icon immediately pauses and reveals Resume, Reset Stage, and Back to Lobby options; course staff approved mouse-only game input.
- Validate the core integration milestone early: submit one drawn object, let it fall/collide with the ball, and detect target overlap in the same bitstream.
