# Product Brief Addendum: Technical Context and Open Questions

## Captured design context

- **Platform and course constraints:** Basys3 and the OLED are compulsory for the I-FDP. The alternative game theme is assessed using functionality, robustness and reliability, user interface, and user experience. The complete project must fit FPGA resources and run in one integrated bitstream.
- **Displays and controls:** VGA is the gameplay canvas. The Pmod OLED shows level selection, objectives, remaining drawing budget, and status. Mouse input handles cursor and strokes; Basys3 buttons and switches handle start, pause, retry, and level selection; LEDs show game status.
- **Proposed module boundaries:** Input controller tracks the cursor and debounced controls. Stroke capture stores sampled points and submits a completed stroke. Game control owns level and play/pause/retry/victory transitions. Level memory contains initial positions, fixed obstacles, and winning conditions. World state owns object geometry, positions, velocities, and fixed/movable status. Proposed interface: physics owns dynamic state and the renderer reads a stable snapshot; confirm the exact contracts during architecture.
- **Physics loop:** Use signed fixed-point positions and velocities. Each update applies gravity, predicts movement, detects collisions, corrects penetration and velocities, then reports whether the goal is met. The game controller owns the victory transition.
- **Bounded first version:** One ball and a few drawn objects; approximate strokes as chains of small circles; start with translation and bouncing; defer rotation. A fixed update rate around 60 Hz using a clock-enable pulse is the current proposal.
- **Initial integration milestone:** Draw one object, release it, let it fall and collide with the ball, then detect whether the ball reaches a target.

## Open design questions for the PRD and architecture

1. What mouse connection and input protocol will the implementation use on the available setup?
2. What coordinate system, fixed-point format, speed limits, stroke-point limit, and total object limit fit the design?
3. What exact overlap rule counts as reaching a target, and what collision cases must the first version support?
4. How should pause, retry, level changes, and drawing-budget reset behave at module boundaries?
5. Reconcile the display wording: the project proposal assigns gameplay to VGA and information screens to the OLED, while an earlier module table says the renderer draws into the OLED image.
6. What renderer and frame-consistency strategy fits the FPGA memory budget? Confirm utilization before choosing a full-resolution buffer strategy.
7. What observable checks will demonstrate reliability and usability during the short course assessment?

These are unresolved implementation choices, not settled requirements.
