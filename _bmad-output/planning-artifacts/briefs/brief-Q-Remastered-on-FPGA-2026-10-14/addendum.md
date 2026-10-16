# Product Brief Addendum: Technical Context and Open Questions

## Captured design context

- **Platform and course constraints:** Basys3 and the OLED are compulsory for the I-FDP. The alternative game theme is assessed using functionality, robustness and reliability, user interface, and user experience. The complete project must fit FPGA resources and run in one integrated bitstream.
- **Displays and controls:** VGA is the full-view lobby and gameplay canvas, with pause and victory overlays. The Pmod OLED shows the current stage, objective, remaining drawing budget, and status. Mouse input handles all game interaction; buttons and switches are not game inputs under the staff-approved mouse-only exception; LEDs show game status.
- **Proposed module boundaries:** Mouse input and stroke capture track cursor/click/drag input and sample bounded polylines. Game control owns stage and play/pause/reset/victory transitions. Level memory contains initial positions, fixed obstacles, and winning conditions. World state owns dynamic geometry and linear/angular state. Physics owns mutable world state; renderers read a stable snapshot. Confirm the exact contracts during architecture.
- **Physics loop:** Use fixed-point state for positions, velocities, and released-stroke rotation. Each update applies gravity, predicts movement, detects collisions, detects and latches ball contact with the left display boundary before wall position correction, corrects penetration and velocities, then reports the latched goal event. The game controller owns the victory transition.
- **Bounded first version:** One ball and at most five drawn strokes per stage attempt. Each released stroke is a bounded sampled polyline treated as a rigid body; the architecture recommendation uses a capsule for each adjacent sample pair, with eight sample points as a provisional cap subject to synthesis and timing analysis. Include translation and rotation. A fixed update rate around 60 Hz using a clock-enable pulse remains a proposal.
- **Fixed obstacles:** Use up to eight thick platforms or sloped ramps per stage, each represented by one static capsule. The four display boundaries are separate from the obstacle cap; the full left boundary is the goal. Level-data encoding remains open.
- **Stroke validation:** Reject a released stroke that penetrates the ball, an existing stroke, or a fixed obstacle without consuming allowance. Tangency is allowed. Pause is disabled while the left mouse button is held; ignore requests during drawing and never pause automatically on drawing release. Pausing requires a separate pause-icon click after release. If that click occurs during admission, finish its atomic result before freezing.
- **Stage count:** Include three built-in selectable MVP stages. Stage 3 is the final stage; its victory screen offers Back to Lobby.
- **Initial integration milestone:** Draw one object, release it, let it fall and collide with the ball, then detect whether any part of the ball touches the left display boundary.

## Open design questions for the PRD and architecture

1. What mouse connection and input protocol will the implementation use on the available setup?
2. What coordinate system, fixed-point format, speed limits, stroke-point limit, and total object limit fit the design?
3. What point and object limits, fixed-point widths, and capsule contact-response costs fit the Basys3 resource budget?
4. Which mouse interface hardware and VGA display path are available in the lab?
5. Reconcile the display wording: the project proposal assigns gameplay to VGA and information screens to the OLED, while an earlier module table says the renderer draws into the OLED image.
6. What renderer and frame-consistency strategy fits the FPGA memory budget? Confirm utilization before choosing a full-resolution buffer strategy.
7. What observable checks will demonstrate reliability and usability during the short course assessment?

These are unresolved implementation choices, not settled requirements. The PRD and UX artifacts record the settled player-facing behavior.
