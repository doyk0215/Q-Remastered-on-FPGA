---
name: Q Remastered on FPGA
status: draft
sources:
  - {planning_artifacts}/prds/prd-Q-Remastered-on-FPGA-2026-10-15/prd.md
  - {planning_artifacts}/prds/prd-Q-Remastered-on-FPGA-2026-10-15/addendum.md
  - {planning_artifacts}/briefs/brief-Q-Remastered-on-FPGA-2026-10-14/brief.md
  - {planning_artifacts}/briefs/brief-Q-Remastered-on-FPGA-2026-10-14/addendum.md
  - {planning_artifacts}/prds/prd-Q-Remastered-on-FPGA-2026-10-15/reconcile-ee2026-manual.md
updated: 2026-10-16
---

# Q Remastered on FPGA — Experience Spine

## Foundation

A mouse-driven, single-player puzzle game running as one integrated Basys3 bitstream. VGA is the primary game and interaction surface. The Pmod OLED supplements it with the current stage, objective, strokes remaining, and game status; LEDs provide status signals. The mouse is the only game input. Basys3 buttons and switches are not used for gameplay.

The player selects a stage from the lobby by clicking it; selection starts the stage immediately. In a stage, the player draws a limited number of strokes. Releasing a stroke validates its geometry: an accepted stroke becomes a movable physical object affected by gravity, collisions, and rotation; a stroke penetrating an existing object is rejected without consuming allowance. The ball and drawn objects remain inside the display playfield's container boundaries. Any ball contact or overlap with the full left display boundary wins the stage; tangency counts. The chosen visual direction is restrained retro arcade. `DESIGN.md` owns visual styling and component appearance; this spine owns navigation, behavior, states, and feedback.

[ASSUMPTION] The game is optimized for a short live course demo: the stage objective, remaining stroke count, and cause-and-effect physics should be legible without a spoken explanation.

## Information Architecture

| Surface | Reached from | Purpose |
|---|---|---|
| Lobby | Board startup; Back to Lobby | Show available stages and let the player choose one. |
| Gameplay | Click a stage in Lobby; Resume | Play the selected physics puzzle and draw strokes. |
| Pause menu | Click the pause control in Gameplay | Resume, reset the stage, or return to the lobby. |
| Victory | Ball touches or overlaps the left display boundary | Hold the completed stage until the player chooses Next Stage or Back to Lobby. On the final stage, offer Back to Lobby. |

Stage selection starts play immediately. Returning to the lobby resets the current attempt. Victory does not advance automatically. Offer Next Stage when another stage exists and Back to Lobby; after the final stage, offer Back to Lobby.

## Voice and Tone

Use short, direct labels. State names should tell the player what happened and what action is available. Avoid instructions that require reading a paragraph before play.

| Use | Avoid |
|---|---|
| “Resume” | “Continue your exciting adventure!” |
| “Reset Stage” | Ambiguous icon-only reset actions |
| “Back to Lobby” | “Exit” when the destination is the stage selector |
| Stage objective and strokes remaining | Physics jargon in player-facing instructions |
| A clear stage-complete state with an explicit Next Stage or Back to Lobby choice | Auto-advance or unexplained screen changes |

[ASSUMPTION] Keep success feedback calm and brief so the physics outcome remains the focus.

## Component Patterns

Behavioral rules live here; visual treatment and token references live in `DESIGN.md`.

| Component | Use | Behavioral rules |
|---|---|---|
| Stage card | Lobby | Present three selectable MVP stages. Clicking a stage selects it and starts it immediately. Show the stage identity and enough preview/objective context to distinguish choices. |
| Gameplay playfield | Gameplay | Shows the ball, drawn strokes, fixed obstacles, marked left goal boundary, other container boundaries, cursor, and pause control. Objects update while the stage is active. |
| Mouse cursor | Lobby and Gameplay | Remains visible over the VGA interaction surface. During drawing, tracks the pointer; click-and-drag captures a stroke and release requests validation. |
| Pause control | Gameplay, upper-left | Two-bar pause icon. Disabled while the left button is held. Ignore pause requests during drawing; a drawing release over the icon does not activate it. A separate click after release freezes the world at the next safe atomic boundary and opens the pause menu. |
| Pause menu | Paused Gameplay | Offers Resume, Reset Stage, and Back to Lobby. Resume restores the same attempt; reset restores the stage start and full stroke allowance; Back to Lobby also resets the attempt. Clicking outside the menu items keeps the menu open and the game paused, without drawing a stroke. |
| Drawn stroke | Gameplay | Preview follows the mouse while held. On release, validate against the ball, existing strokes, and fixed obstacles. If accepted, it becomes a persistent movable object and consumes one stroke. If it penetrates an existing object, reject it, clear the preview, and preserve allowance; mere tangency is allowed. It responds to gravity, collisions, and rotation. |
| Ball | Gameplay | Responds to gravity and collisions; remains within the playfield container. Any contact or overlap with the full left display boundary completes the stage. |
| Fixed obstacle | Gameplay | Remains at its level-defined position and geometry; participates in collision response. |
| Goal boundary | Gameplay | Marks the full left display edge as the goal. Any ball contact or overlap, including tangency, triggers victory at any height. Stroke contact alone does not win. |
| OLED status | All applicable stages | Shows stage, objective, remaining strokes, and current status. Do not make it the only place a required gameplay action is communicated. |
| Status LEDs | Global | Signal game status as defined by the hardware implementation; never act as the only explanation of a state. |
| Victory state | After goal overlap | Stops active gameplay and offers Next Stage after Stages 1 and 2, plus Back to Lobby. After Stage 3, offer Back to Lobby. No automatic stage advance. |

## State Patterns

| State | Surface | Treatment |
|---|---|---|
| Cold start | Lobby | Enter the stage lobby from board startup; no hardware-button start step. |
| Stage selection | Lobby | Available stages are mouse-clickable. Selecting one immediately initializes and starts that stage. |
| Active attempt | Gameplay | Ball and released strokes simulate; the player may draw while stroke budget remains. |
| Drawing in progress | Gameplay | Cursor movement previews the continuously simplified stroke, preserving its start/end and significant bends within eight points. Pause is disabled while the left button is held and requests are not queued. Release requests validation only; consume one stroke only if accepted. |
| Stroke rejected | Gameplay | Clear the invalid preview and briefly show “Stroke overlaps an object” on VGA. Preserve the OLED count and continue the attempt. A separate pause click made after release can wait for validation to complete. |
| Stroke allowance exhausted | Gameplay | Prevent additional strokes and keep the current attempt playable. Show a brief VGA “No strokes left” message and show zero on the OLED count. |
| Paused | Gameplay + pause menu | Freeze the ball and released strokes; show Resume, Reset Stage, Back to Lobby. Resume preserves the attempt. Clicks outside menu items have no effect. |
| Reset | Gameplay | Restore the initial ball and stage objects, clear player strokes, and restore the full stroke allowance. |
| Returned to lobby | Lobby | Discard the current attempt and show stage selection. |
| Victory | Gameplay | Trigger on any ball contact or overlap with the left display boundary; stop the attempt and wait for player choice. |
| Invalid/unavailable input | Any surface | No game input is assigned to Basys3 switches or buttons. Mouse hit regions and feedback for unsupported actions remain to be specified. |

## Interaction Primitives

- **Mouse click:** activate a stage or visible menu action. Stage selection begins play immediately.
- **Mouse draw:** press and hold to capture pointer movement as a preview stroke; release requests validation. Only an accepted stroke becomes a physics object and decrements the count. A stroke penetrating an existing object is rejected without consuming allowance.
- **Pause:** disabled while the left mouse button is held. Ignore requests during drawing and do not queue them. Drawing release, including over the pause icon, requests validation only. To pause, make a separate click on the upper-left two-bar control after release; if validation is still in flight, finish its atomic result then freeze before further simulation.
- **Resume:** return to the same gameplay attempt and continue simulation.
- **Reset Stage:** discard the attempt and restore its initial state and full drawing allowance.
- **Back to Lobby:** discard the attempt and return to stage selection.
- **Win check:** any ball contact or overlap with the left display boundary completes the stage; wait for player choice.

Mouse protocol, coordinate mapping, and hit regions remain open implementation details. Do not add switch, button, keyboard, or touch controls without a product decision.

## Accessibility Floor

- Use readable text and distinguishable shapes on the VGA display and OLED. Do not rely on color alone to communicate the left goal boundary, active mode, pause, or victory.
- Keep the mouse cursor and current drawing preview visually distinguishable from the ball, strokes, obstacles, and left goal boundary.
- Make lobby and pause-menu actions large and clearly separated enough for reliable mouse selection at the actual display resolution. Exact dimensions await the display and mouse-coordinate decisions.
- Repeat critical stage and status information across the VGA/OLED/LED roles where practical; a status LED alone cannot explain an action or outcome.
- The project is mouse-only by course-staff confirmation. The UX does not promise keyboard, switch, button, touch, or screen-reader interaction.

## Key Flows

### Flow 1 — Solve a stage during the course demo (Alex, first-time player)

1. Alex turns on the Basys3 game and arrives at the lobby.
2. The VGA screen shows stage choices; the OLED presents relevant stage/objective information as designed.
3. Alex clicks a stage. The click initializes and starts it immediately.
4. The gameplay surface shows the ball, marked left goal boundary, obstacles, cursor, and upper-left pause control. The OLED shows the objective and strokes remaining.
5. Alex presses and drags the mouse to draw a stroke, then releases. If accepted, the stroke becomes a movable object and consumes one stroke from the allowance. If it penetrates the ball, another stroke, or a fixed obstacle, reject it with brief feedback and keep the allowance unchanged.
6. Gravity and collisions move the ball and stroke; the physical result is visible on the playfield.
7. If Alex misses, the ball and objects remain contained and the attempt continues while strokes remain. Alex can draw again or pause and reset.
8. **Climax:** the ball touches or overlaps the left display boundary; the stage enters a visible victory state and stops simulation.
9. The victory state offers Next Stage when another stage exists and Back to Lobby. After the final stage, it offers Back to Lobby. It does not advance automatically.

Failure path: if the stroke does not guide the ball to the left display boundary, keep the attempt understandable and recoverable through another allowed stroke, Reset Stage, or Back to Lobby. When no strokes remain, show a brief VGA message and keep the OLED count at zero. After victory, offer Next Stage when available or Back to Lobby; the final stage offers Back to Lobby.

### Flow 2 — Pause and choose how to recover (Alex, during an active attempt)

1. Alex finishes and releases any drawing gesture, then makes a separate click on the two-bar pause control at the upper-left. Pause requests while the left button is held are ignored.
2. The ball and released strokes freeze immediately; the pause menu appears.
3. Alex chooses one action with the mouse:
   - **Resume:** close the menu and continue the same attempt from the frozen state.
   - **Reset Stage:** restore starting positions, remove all drawn strokes, and refill the stroke allowance.
   - **Back to Lobby:** reset the current attempt and return to stage selection.
4. **Climax:** the selected action is reflected clearly in the next visible state: resumed play, a fresh stage, or the lobby.

Failure path: clicking outside the menu items keeps the menu open and the game paused. No stroke is drawn. A menu item must be selected to resume, reset, or leave the stage.
