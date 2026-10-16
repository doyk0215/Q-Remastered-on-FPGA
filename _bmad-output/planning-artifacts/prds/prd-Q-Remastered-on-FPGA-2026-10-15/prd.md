---
title: "PRD: Q Remastered on FPGA"
status: final
created: 2026-10-15
updated: 2026-10-16
---

# PRD: Q Remastered on FPGA

## 0. Document Purpose

This PRD defines the player-visible capabilities and quality requirements for the team's EE2026 Interactive FPGA Design Project. It is the shared product contract for game control, physics/world state, and graphics/display work. It focuses on what a player and assessor must be able to observe; implementation choices are collected in the adjacent `addendum.md` for architecture and integration planning.

## 1. Vision

Q Remastered on FPGA is a compact drawing-and-physics puzzle game for the Basys3. When the board starts, the game opens to a lobby. The player selects a stage with the mouse, draws a limited stroke, and releases it as an object that can redirect a ball under gravity. The player succeeds by guiding any part of the ball into contact with the full left boundary of the display.

The game should make the relationship between a drawn stroke and the ball's motion easy to see. A player should be able to understand the objective, try a solution, recognize success, and retry or choose another stage without reprogramming the board. The complete demonstration runs as one integrated bitstream and respects the board's resource limits.

## 2. Target User

### 2.1 Jobs to Be Done

- As a first-time player, understand the stage objective and remaining drawing allowance before attempting a solution.
- Draw a stroke, see it become part of the puzzle, and understand how it affects the ball.
- Know when the left goal boundary has been reached and quickly retry or choose another stage.
- As an assessor, see the integrated game loop and each claimed capability within a short live demonstration.

### 2.2 Key User Journey

- **UJ-1. Alex guides the ball during a first-time live demonstration.** **[ASSUMPTION: Alex is a representative first-time demo player; no individual persona has been supplied.]** When the board starts, Alex sees a lobby on the VGA display and clicks a stage to launch it. In the stage, the OLED shows the objective and remaining stroke allowance while the VGA playfield shows the ball, obstacles, marked left goal boundary, and cursor. Alex draws and releases a stroke, then watches gravity and collisions change the ball's path. Pause is disabled while the left mouse button is held. After releasing the stroke, Alex makes a separate click on the top-left two-bar pause icon to pause. The pause menu offers Resume, Reset Stage, and Back to Lobby. If the ball misses, Alex resets the stage and tries again. When any part of the ball touches or overlaps the left display boundary, the game signals victory and leaves the completed stage visible. Alex can choose Next Stage when one is available or return to the lobby; the final stage offers Back to Lobby.

## 3. Glossary

- **Ball** — The moving game object that the player guides toward the left goal boundary.
- **Stage** — A puzzle setup containing a starting ball, fixed obstacles, the left display boundary as the goal, and a drawing allowance.
- **Fixed obstacle** — An immovable thick platform or sloped ramp. Each is represented by a static capsule in the MVP architecture. Each stage supports up to eight; the four display boundaries are counted separately, with the left boundary also serving as the goal.
- **Stroke** — A player-drawn path offered for validation on mouse release. An accepted stroke becomes a physics object; an overlapping stroke is rejected without consuming allowance.
- **Physics object** — A ball or released stroke represented in the game world. Both move under gravity and respond to collisions; released strokes can also rotate.
- **Goal boundary** — The full left edge of the display. Any ball contact or overlap, including tangency, completes the stage.
- **Drawing allowance** — The per-stage limit on the number of separate strokes the player can submit, shown as strokes remaining.

## 4. Features

All feature requirements in this section support UJ-1.

### 4.1 Stage Selection and Game Controls

The player enters the lobby on startup and uses the mouse for all game interactions. No Basys3 switches or buttons are used as game controls. Stage changes and retries happen within the running bitstream.

#### FR-1: Select and launch a stage

When the board starts, the game presents a lobby. The player selects an available stage by clicking it with the mouse; the selected stage immediately loads and starts.


**Consequences (testable):**
- The lobby and available stages are shown on VGA at startup.
- Clicking a stage loads its ball, obstacles, objective, and drawing allowance, then starts play without a separate Start action or FPGA reprogramming.

#### FR-2: Pause and resume

A two-bar pause icon appears in the top-left corner of the stage. Pause is disabled while the left mouse button is held: requests during drawing are ignored, not queued. Releasing a stroke only requests validation, even if released over the pause icon; it does not pause. After release, a separate pause-icon click freezes the ball and all released strokes, then opens a menu offering Resume, Reset Stage, and Back to Lobby. If stroke validation is already in flight when that separate click occurs, resolve the atomic acceptance/rejection before freezing, with no further physics advancement afterward. Selecting Resume continues the same attempt.


**Consequences (testable):**
- The paused state is visibly indicated.
- Holding the left mouse button disables pause. Releasing a drawing gesture never activates the pause control; a separate click is required.
- While paused, the ball and all released strokes remain frozen in place; resuming continues the same attempt.
- Clicking outside the pause-menu items keeps the game paused and the menu open; it neither resumes play nor draws a stroke. Resume requires selecting Resume.

#### FR-3: Reset a stage and return to the lobby

The player can use the in-stage menu with the mouse to reset the current stage or return to the lobby and select another stage, without reprogramming the FPGA.


**Consequences (testable):**
- Selecting Reset Stage restores the stage to its starting state, clears every player-drawn stroke, and restores the full drawing allowance.
- Selecting Back to Lobby resets the current stage attempt and returns to the stage selector.
- The lobby remains available after victory.

### 4.2 Mouse Drawing and Drawing Allowance

The player uses a mouse to place strokes in the game playfield. The allowance bounds the amount of player-created geometry.

#### FR-4: Capture a stroke

The player can move a visible cursor and draw a stroke with the mouse while a stage is active.


**Consequences (testable):**
- Cursor and stroke positions correspond to the visible game playfield.
- An accepted stroke remains visibly identifiable after the player releases the mouse.

#### FR-5: Submit a stroke as a movable physics object

Releasing the mouse requests validation of the completed stroke against the current ball, existing released strokes, and fixed platforms or ramps. If its collision geometry penetrates any of these objects, reject the whole stroke without creating a body or consuming allowance. Mere tangency is allowed. An accepted stroke becomes a movable physics object, moves under gravity, responds to collisions including collisions with the ball, and can rotate when an impact changes its angular motion.


**Consequences (testable):**
- Only an accepted stroke is inserted into the world, remains for the current attempt, and moves under gravity.
- A rejected stroke leaves existing world state and the remaining allowance unchanged; ordinary simulation continues. Clear its preview and show a brief VGA message: “Stroke overlaps an object.”
- Validation uses the final sampled collision geometry and the world state at acceptance time, so movement during drawing cannot bypass the overlap check.
- Releasing the stroke never automatically pauses. A separate pause click made after release can wait for an already in-flight validation to finish.
- Collisions update the motion of the released stroke and can change the ball's motion.
- The released stroke's orientation can visibly change during play.

#### FR-6: Enforce and show the drawing allowance

Each MVP stage attempt starts with an allowance of five submitted strokes. The game shows the number remaining on the OLED.


**Consequences (testable):**
- The OLED shows the number of strokes remaining and decreases by one only when a released stroke is accepted into the world. Rejected strokes do not change the OLED count.
- The player can submit at most five strokes in one stage attempt; a sixth stroke cannot be submitted.
- When no strokes remain, a brief VGA message says “No strokes left” and the OLED count shows zero.

### 4.3 Ball Motion and Puzzle World

The ball and released strokes move under gravity and interact with one another, fixed obstacles, and the VGA playfield edges, which form a closed container.

#### FR-7: Advance linear and angular motion

During active play, the ball and released strokes update their positions over time. Released strokes also update their orientation as angular motion persists or collision response produces a rotational effect.


**Consequences (testable):**
- With no collision, the ball and a released stroke visibly move under gravity.
- A released stroke with angular motion visibly changes orientation while the stage is active.

#### FR-8: Resolve collisions

The game detects and responds to collisions among the ball, movable released strokes, fixed obstacles, and all four VGA playfield edges, which act as solid container walls. Collision response updates linear motion and, for released strokes, angular motion including rotation caused by an off-center impact.


**Consequences (testable):**
- Collision response prevents the ball and released strokes from visibly passing through supported solid objects or the display-edge walls.
- Contact with a display edge keeps the physics objects inside the playfield and changes their motion as a bounce.
- A collision produces a visible change in the motion or position of the affected physics objects.
- In a prepared stage or physics test setup, an off-center collision changes a released stroke's angular motion and visibly changes its orientation.

### 4.4 Goal and Feedback

#### FR-9: Detect stage completion

A stage is complete as soon as any part of the ball touches or overlaps the full left display boundary, at any height.


**Consequences (testable):**
- Tangency counts as completion; the ball's center does not need to reach or pass the left edge.
- Contact with the top, right, or bottom edge alone does not complete the stage.
- A drawn stroke touching the left boundary does not complete the stage.
- Boundary position correction must not discard a detected winning ball contact.
- The game stops treating the current attempt as active after completion.

#### FR-10: Communicate game status

The VGA and OLED visibly identify active play, pause, and victory. The LEDs indicate pause and victory.


**Consequences (testable):**
- A player can distinguish a running stage, a paused stage, and a completed stage from the display status during the demonstration.
- The completed state remains visible until the player selects Next Stage or Back to Lobby; the final stage offers Back to Lobby. Victory does not automatically advance.

### 4.5 Displays

#### FR-11: Render the lobby, playfield, and in-stage menu

The VGA display shows the stage-selection lobby and, during play, the ball, player-created strokes, fixed obstacles, marked left goal boundary, cursor, and top-left two-bar pause icon. It uses the full view for the playfield and displays pause and victory menus as overlays. The pause menu offers Resume, Reset Stage, and Back to Lobby. The victory overlay offers Next Stage when another stage exists and Back to Lobby; the final stage offers Back to Lobby.

**Consequences (testable):** The player can see and click the stage choices in the lobby, pause using the top-left icon, and use the menu shown after pausing.


#### FR-12: Present supporting stage information

The Pmod OLED presents the current stage, objective, remaining stroke allowance, and game status. Stage selection is performed in the VGA lobby with the mouse.

**Consequences (testable):** After stage selection, the OLED shows that stage's objective, number of strokes remaining, and current game state.


#### FR-13: Show status on board LEDs

Basys3 LEDs indicate game status, including pause and victory.

**Consequences (testable):** LED status changes when the game enters pause or victory.


## 5. Cross-Cutting Quality and Hardware Constraints

- **Single-bitstream operation:** All claimed capabilities are integrated and usable from one bitstream; selecting, retrying, or pausing a stage does not require reprogramming.
- **Reliability:** The complete demonstration sequence through lobby selection, mouse drawing, pause/resume, stage reset, return to lobby, and victory must run without a board reset or bitstream reprogramming.
- **Responsiveness:** The integrated demonstration must show cursor movement, drawing feedback, and continuous visible physics updates. The team will measure and record the achieved response and update rates before claiming them in the final report.
- **Resource use:** The implementation must fit the Basys3 FPGA. The team will review post-implementation utilization and keep only capabilities that work in the integrated bitstream.
- **Assessment/demo fit:** The core game loop should be straightforward to show in the typical 2–5 minute team demonstration described in the course manual.
- **Required/optional devices:** The course manual identifies Basys3 switches, LEDs, and the Pmod OLED as required. This design uses no Basys3 switches or buttons for game interaction; all game input is through a mouse. Course staff confirmed that mouse-only input is acceptable for this project despite the manual's stated switch requirement. The manual allows a mouse as an optional device; sole reliance on it is the staff-approved exception. VGA is proposed for the lobby and gameplay; confirm its interface before implementation.

## 6. Non-Goals

- Unlimited strokes, points, stages, or physics objects.
- A physically exact simulation or a general-purpose physics engine.
- Multiple Basys3 boards, network play, or a separate computer-based game.
- Capabilities that cannot be integrated, demonstrated, and supported within the FPGA resource limits.

## 7. MVP Scope

### 7.1 In Scope

- Three selectable stages, each with one ball, up to eight fixed platforms or ramps, the left display boundary as the goal, and a five-stroke allowance per attempt.
- Mouse-only game interaction through a lobby, clickable stage selection, stroke drawing, and an in-stage menu; released strokes become movable physics objects affected by gravity and collisions.
- Gravity, translation, and collision response for the ball and released strokes; released strokes visibly rotate through angular collision response.
- Startup lobby, mouse-based stage selection and launch, mouse-accessible pause/resume/reset/return-to-lobby controls, and visible victory feedback.
- VGA gameplay, OLED stage/objective/budget/status information, and LED status.
- One integrated bitstream with all demonstrated capabilities.

### 7.2 Out of Scope for MVP

- Large or unbounded geometry and object counts.
- Extra devices or features without a clear role in the puzzle experience.
- Any enhancement not tested in the integrated bitstream before being claimed in the report.

## 8. Success Metrics

- **SM-1 — Playable core loop:** In a live demonstration, a player can click a stage in the lobby, draw and release a stroke, observe the ball respond to gravity and collisions, demonstrate visible stroke rotation in a prepared stage or physics test setup after an off-center collision, and complete a stage by touching the left display boundary with any part of the ball. Validates FR-1, FR-4, FR-5, FR-7, FR-8, and FR-9.
- **SM-2 — Recoverable play:** Mouse-based pause/resume, stage reset, and return to the lobby work during the demonstration without reprogramming or losing control of the game. Validates FR-2 and FR-3.
- **SM-3 — Clear feedback:** The player can identify the objective, drawing allowance, and active/paused/victory state from the displays and LEDs. Validates FR-6, FR-10, FR-11, FR-12, and FR-13.
- **SM-4 — Integrated delivery:** The complete demonstrated feature set runs in one bitstream and remains within the Basys3 resource limits. Validates the single-bitstream and resource requirements.
- **SM-C1 — Scope guard:** Do not add stages, strokes, or display effects if doing so threatens reliable retry or a working one-bitstream build. Counterbalances SM-1.

## 9. Open Questions

| Question | Owner | Revisit when |
| --- | --- | --- |
| Which mouse protocol and coordinate mapping are available? | Input-control owner | Before implementing stroke capture. |
| What minimum cursor/drawing accuracy and visible physics-update responsiveness can be measured on the Basys3? | Input-control, physics, and display owners | After the first integrated prototype and before story planning. |
| Which VGA monitor/interface path is available? | Display owner | Before choosing board connections and VGA timing. |
| Does the provisional eight-point sample cap, collision radius, and fixed-point capsule contact method fit the resource budget for each drawn polyline rigid body? | Physics owner | During architecture, after synthesis and timing analysis. |
| Which collision geometry, inertia approximation, angular-response model, and update-rate target fit the resource budget? | Physics owner with display/integration owners | During architecture, then validate on board before the demo. |
| Which prepared stage or physics test setup will demonstrate repeatable off-center collision and visible stroke rotation? | Physics and game-control owners | Before story planning and the live demonstration. |

## 10. Assumptions Index

- §2.2: Alex is a representative first-time live-demo player; no individual persona has been supplied. EE2026 assessors are a secondary audience.
- §5: VGA will be available for the lobby and gameplay; confirm the interface. The mouse is an optional device under the manual; course staff approved using it as the sole game input despite the manual's switch requirement.
