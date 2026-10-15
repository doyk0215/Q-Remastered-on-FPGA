# Project Brief Reconciliation

## Source intent and ownership

The original team brief describes a Basys3 drawing-and-physics puzzle inspired by Q REMASTERED. The player uses a mouse to draw lines or shapes that interact with a ball and fixed obstacles; gravity and collisions should move the objects so the ball can overlap a target. The physics model and object/point counts are deliberately bounded. The intended delivery is a single bitstream supporting retries and level changes.

The original display plan assigns gameplay to VGA and level selection, objectives, and drawing budget to the Pmod OLED. Basys3 buttons and switches were initially listed for start, pause, retry, and level selection, with LEDs showing status. Ownership is divided into (1) game/input control, including cursor/clicks, stroke capture, budget, level data, state machine, objective checks, and LEDs; (2) physics/world state, including geometry, fixed/movable objects, gravity, collision response, boundaries, and pause/reset behavior; and (3) graphics/displays, including VGA timing/rendering, OLED information screens, and display clocks.

## Reconciliation with current PRD

The PRD retains the puzzle loop, bounded object scope, Basys3, VGA gameplay, Pmod OLED, LEDs, and one-bitstream delivery. It incorporates later user clarifications: mouse-only interaction is staff-approved; the VGA lobby launches a stage immediately; pause opens a mouse-operated menu; leaving for the lobby resets the attempt; the drawing budget counts separate strokes; target contact means any ball-target overlap; and released strokes translate and rotate under gravity and collision response. These later decisions supersede the initial switches/buttons and OLED level-selection interaction proposal. The responsibility split remains compatible, with mouse UI and its coordinates needing integration agreement.

## Gaps to carry into planning

- The original “lines and shapes” language does not settle which stroke geometries are supported or how they become bounded rotating bodies; representation, center of mass, and angular-response model remain architecture decisions.
- Maximum levels, strokes per level, sampled points/geometry per stroke, and simultaneous physics objects are not yet quantified.
- VGA output/interface availability and mouse protocol/coordinate mapping still need confirmation for implementation.
- The original brief assigns OLED menus and level selection to graphics; the clarified PRD places the clickable lobby and pause menu on VGA, reserving OLED for stage/objective/budget/status information. This is a deliberate interaction/display allocation change.
