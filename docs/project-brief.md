# Project Brief: Q Remastered on FPGA

This file summarizes the current product contract. The finalized PRD and [architecture spine](../_bmad-output/planning-artifacts/architectures/architecture-Q-Remastered-on-FPGA-2026-10-15/ARCHITECTURE-SPINE.md) contain the detailed requirements and remaining implementation gates.

## Goal

Build a single-bitstream drawing-and-physics puzzle game on the Basys3 FPGA, inspired by Q REMASTERED. The player selects a stage, draws strokes that become rotating physics objects, and guides a ball to the full left boundary of the display.

## User experience and hardware

- VGA: full-view stage lobby and gameplay playfield, with pause and victory menus as overlays.
- Pmod OLED: current stage, objective, remaining stroke allowance, and game status.
- Wired Logitech mouse: all game input, including stage selection, drawing, pause, and menu actions; exact model and interface remain pending.
- Basys3 buttons and switches: not used for game interaction; course staff approved mouse-only input.
- LEDs: game status, including pause and victory.

## Initial scope

Include three selectable MVP stages, each with one ball, a five-stroke allowance per attempt, at most eight sample points per stroke as a provisional profile, and fixed obstacles. There are at most six moving bodies: one ball and five strokes. Released strokes are sampled polylines treated as rigid bodies; the current architecture recommendation models each adjacent point pair as a capsule, subject to resource validation. Use fixed-point state for physics. The ball and strokes respond to gravity and collisions; strokes rotate after angular impacts. A stage is won as soon as any part of the ball touches or overlaps the full left display boundary.

Each stage supports up to eight fixed thick platforms or sloped ramps, each represented by a static capsule. The four display boundaries are counted separately; the left boundary is also the goal.

On release, reject a stroke whose collision geometry penetrates the ball, an existing stroke, or a fixed obstacle. Rejection creates no body and consumes no allowance; tangency is allowed. Pause is disabled while the left mouse button is held, and requests during drawing are ignored. Drawing release never pauses, even over the pause icon; pausing requires a separate click afterward. If that click occurs during admission, finish its atomic result before freezing.

## System ownership

- Mouse input and game control: cursor/click/drag capture, stroke sampling and allowance, stage state, pause/reset/next-stage transitions, objectives, and LEDs.
- Physics and world state: mutable ball and stroke state, fixed-point motion, gravity, translation and rotation, collisions, boundaries, pause/reset, and goal-event reporting.
- Graphics and displays: VGA timing/rendering, lobby and menu overlays, OLED status, and display clocks.

## Integration constraints

- Keep all demonstrated functionality in one integrated bitstream and within Basys3 FPGA resource limits.
- Keep responsibilities distinct and define shared coordinates, fixed-point formats, stroke/object caps, and module interfaces before integration.
- The game controller owns stage and victory state; physics owns mutable world state and reports ball contact with the left goal boundary; renderers consume stable snapshots.
- Keep VGA rendering memory-aware; compare procedural and compact-buffer approaches before allocating a full-resolution frame buffer.
- The exact Logitech model/interface and the lab VGA monitor path remain open architecture inputs.
