# Project Brief: Q Remastered on FPGA

## Goal

Build a single-bitstream drawing-and-physics puzzle game on the Basys3 FPGA, inspired by Q REMASTERED. The player draws strokes that become physics objects and tries to guide a ball into a level target.

## User experience and hardware

- VGA monitor: main gameplay display, including the ball, drawn objects, obstacles, target, and cursor.
- Pmod OLED: level selection, puzzle objective, remaining drawing budget, and game status.
- Mouse: cursor and stroke input.
- Basys3 buttons and switches: start, pause, retry, and level selection.
- LEDs: game status.

## Initial scope

Keep the first version bounded to one ball, a few drawn objects, a limited number of stroke points, and a small set of levels. Use signed fixed-point state for positions and velocities. The physics update applies gravity, predicts movement, detects and resolves collisions, then checks the goal. Begin with translation and bouncing; defer rotation.

## System ownership

- Game control and drawing input: mouse and button input, debouncing, stroke capture and budget, level/control state, objective transitions, and LEDs.
- Physics and world state: object geometry, fixed-point positions and velocities, gravity, collisions, boundaries, pause/reset, and goal-event reporting.
- Graphics and displays: VGA timing and gameplay rendering, OLED screens, and display clocks.

## Integration constraints

- Keep all functionality in one integrated bitstream and within Basys3 FPGA resource limits.
- Keep responsibilities distinct and define shared coordinate, fixed-point, object-limit, and module-interface contracts before integration.
- The game controller owns level and victory state; physics reports whether the goal condition is met. The renderer reads stable world-state snapshots.
- Keep VGA rendering memory-aware; avoid assuming that full-resolution double frame buffering fits.
