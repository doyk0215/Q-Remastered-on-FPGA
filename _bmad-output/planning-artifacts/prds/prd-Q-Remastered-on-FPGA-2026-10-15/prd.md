---
title: "PRD: Q Remastered on FPGA"
status: final
created: 2026-10-15
updated: 2026-10-15
---

# PRD: Q Remastered on FPGA

## 0. Document Purpose

This PRD defines the player-visible capabilities and quality requirements for the team's EE2026 Interactive FPGA Design Project. It is the shared product contract for game control, physics/world state, and graphics/display work. It focuses on what a player and assessor must be able to observe; implementation choices are collected in the adjacent `addendum.md` for architecture and integration planning.

## 1. Vision

Q Remastered on FPGA is a compact drawing-and-physics puzzle game for the Basys3. When the board starts, the game opens to a lobby. The player selects a stage with the mouse, draws a limited stroke, and releases it as an object that can redirect a ball under gravity. The player succeeds by guiding any part of the ball into the target area.

The game should make the relationship between a drawn stroke and the ball's motion easy to see. A player should be able to understand the objective, try a solution, recognize success, and retry or choose another stage without reprogramming the board. The complete demonstration runs as one integrated bitstream and respects the board's resource limits.

## 2. Target User

### 2.1 Jobs to Be Done

- As a first-time player, understand the stage objective and remaining drawing allowance before attempting a solution.
- Draw a stroke, see it become part of the puzzle, and understand how it affects the ball.
- Know when the target has been reached and quickly retry or choose another stage.
- As an assessor, see the integrated game loop and each claimed capability within a short live demonstration.

### 2.2 Key User Journey

- **UJ-1. Alex guides the ball during a first-time live demonstration.** **[ASSUMPTION: Alex is a representative first-time demo player; no individual persona has been supplied.]** When the board starts, Alex sees a lobby on the VGA display and clicks a stage to launch it. In the stage, the OLED shows the objective and remaining stroke allowance while the VGA playfield shows the ball, obstacles, target, and cursor. Alex draws and releases a stroke, then watches gravity and collisions change the ball's path. Alex clicks the two-bar pause icon in the top-left corner; the stage pauses immediately and a menu appears with Resume, Reset Stage, and Back to Lobby options, selected with the mouse. If the ball misses, Alex resets the stage and tries again. When any part of the ball overlaps the target, the game signals victory and leaves the completed stage visible. Alex can retry or return to the lobby and choose another stage without reprogramming the FPGA.

## 3. Glossary

- **Ball** — The moving game object that the player guides toward the target.
- **Stage** — A puzzle setup containing a starting ball, fixed obstacles, a target, and a drawing allowance.
- **Stroke** — A player-drawn path that is submitted as a physics object when drawing is released.
- **Physics object** — A ball or released stroke represented in the game world. Both move under gravity and respond to collisions; released strokes can also rotate.
- **Target area** — The marked region that the ball must reach to complete a stage.
- **Drawing allowance** — The per-stage limit on the number of separate strokes the player can submit, shown as strokes remaining.

## 4. Features

All feature requirements in this section support UJ-1.

### 4.1 Stage Selection and Game Controls

The player enters the lobby on startup and uses the mouse for all game interactions. No Basys3 switches or buttons are used as game controls. Stage changes and retries happen within the running bitstream.

#### FR-1: Select and launch a stage

When the board starts, the game presents a lobby. The player selects an available stage by clicking it with the mouse; the selected stage immediately loads and starts.


**Consequences (testable):**
- The lobby and available stages are shown on VGA at startup.
- Clicking a stage loads its ball, obstacles, target, objective, and drawing allowance, then starts play without a separate Start action or FPGA reprogramming.

#### FR-2: Pause and resume

A two-bar pause icon appears in the top-left corner of the stage. Clicking it immediately freezes the ball and all released strokes, then opens a menu offering Resume, Reset Stage, and Back to Lobby. Selecting Resume continues the same attempt.


**Consequences (testable):**
- The paused state is visibly indicated.
- While paused, the ball and all released strokes remain frozen in place; resuming continues the same attempt.

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
- A stroke remains visibly identifiable after the player releases the mouse.

#### FR-5: Submit a stroke as a movable physics object

Releasing the mouse submits the completed stroke as a movable physics object. It moves under gravity, responds to collisions including collisions with the ball, and can rotate when an impact changes its angular motion.


**Consequences (testable):**
- The submitted stroke remains in the world for the current attempt and moves under gravity.
- Collisions update the motion of the released stroke and can change the ball's motion.
- The released stroke's orientation can visibly change during play.

#### FR-6: Enforce and show the drawing allowance

The game limits the number of separate strokes that can be submitted in each stage and shows the number of strokes remaining on the OLED.


**Consequences (testable):**
- The OLED shows the number of strokes remaining and decreases by one when a completed stroke is submitted on mouse release.
- The player cannot submit more strokes than the configured limit for that stage.

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

A stage is complete as soon as any part of the ball overlaps the target area.


**Consequences (testable):**
- Boundary contact that creates overlap counts as completion; the ball's center does not need to enter the target.
- The game stops treating the current attempt as active after completion.

#### FR-10: Communicate game status

The VGA and OLED visibly identify active play, pause, and victory. The LEDs indicate pause and victory.


**Consequences (testable):**
- A player can distinguish a running stage, a paused stage, and a completed stage from the display status during the demonstration.
- The completed state remains visible until the player retries or selects another stage; victory does not automatically advance.

### 4.5 Displays

#### FR-11: Render the lobby, playfield, and in-stage menu

The VGA display shows the stage-selection lobby and, during play, the ball, player-created strokes, fixed obstacles, target, cursor, and top-left two-bar pause icon. After the icon is clicked, it shows the paused stage and a menu with Resume, Reset Stage, and Back to Lobby options.

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

- One ball, a small set of stages, fixed obstacles, a target, and a limited drawing allowance.
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

- **SM-1 — Playable core loop:** In a live demonstration, a player can click a stage in the lobby, draw and release a stroke, observe the ball respond to gravity and collisions, demonstrate visible stroke rotation in a prepared stage or physics test setup after an off-center collision, and complete a stage by overlapping the target. Validates FR-1, FR-4, FR-5, FR-7, FR-8, and FR-9.
- **SM-2 — Recoverable play:** Mouse-based pause/resume, stage reset, and return to the lobby work during the demonstration without reprogramming or losing control of the game. Validates FR-2 and FR-3.
- **SM-3 — Clear feedback:** The player can identify the objective, drawing allowance, and active/paused/victory state from the displays and LEDs. Validates FR-6, FR-10, FR-11, FR-12, and FR-13.
- **SM-4 — Integrated delivery:** The complete demonstrated feature set runs in one bitstream and remains within the Basys3 resource limits. Validates the single-bitstream and resource requirements.
- **SM-C1 — Scope guard:** Do not add stages, strokes, or display effects if doing so threatens reliable retry or a working one-bitstream build. Counterbalances SM-1.

## 9. Open Questions

| Question | Owner | Revisit when |
| --- | --- | --- |
| What minimum number of stages, strokes per stage, sampled points per stroke, and physics objects can the integrated demo support? | Input-control and physics owners | After an initial resource estimate and before story planning. |
| Which mouse protocol and coordinate mapping are available? | Input-control owner | Before implementing stroke capture. |
| What minimum cursor/drawing accuracy and visible physics-update responsiveness can be measured on the Basys3? | Input-control, physics, and display owners | After the first integrated prototype and before story planning. |
| Which VGA monitor/interface path is available? | Display owner | Before choosing board connections and VGA timing. |
| How will bounded stroke geometry be represented and translated as a movable physics object? | Physics owner | During architecture, before implementing stroke collision response. |
| Which collision geometry, inertia approximation, angular-response model, and update-rate target fit the resource budget? | Physics owner with display/integration owners | During architecture, then validate on board before the demo. |
| Which prepared stage or physics test setup will demonstrate repeatable off-center collision and visible stroke rotation? | Physics and game-control owners | Before story planning and the live demonstration. |
| What happens to an in-progress stroke when the player pauses, and which mouse actions remain active in the pause menu? | Input-control and UX owners | During UX planning, before implementing pause behavior. |

## 10. Assumptions Index

- §2.2: Alex is a representative first-time live-demo player; no individual persona has been supplied. EE2026 assessors are a secondary audience.
- §5: VGA will be available for the lobby and gameplay; confirm the interface. The mouse is an optional device under the manual; course staff approved using it as the sole game input despite the manual's switch requirement.
