# Story ownership for group S2_19

The twelve implementation stories use the three responsibilities in the team's I-FDP proposal. Each story has one lead developer and one reviewer. Shared stories identify each member's contribution so coordination does not transfer ownership of another subsystem.

## Developer responsibilities

| Developer | Area | Responsibilities |
| --- | --- | --- |
| Han Qi-Ze | Game control and drawing input | Mouse events, provisional stroke capture/simplification, UI actions, stage definitions, allowance, game-state/progression FSM and LED behavior. |
| Kim Doyeon | Physics engine and world state | Authoritative body state, fixed-point arithmetic, gravity, transforms, stroke admission, collision/rotation, wall containment, goal events and atomic world pause/reset. |
| Chua Choon Hsiang | Graphics and display system | VGA timing/pixels, buffered rendering, visual cursor/preview/menus, OLED rendering, display clocks and display-side frame/status transfers. |

Qi-Ze supplies UI state and commands; Doyeon owns accepted world geometry and motion; Choon Hsiang renders coherent presentation data. The controller alone changes game mode and remaining allowance. Physics reports the winning contact; the controller enters Victory and chooses the next screen.

## Story assignments

The role areas come from the supplied proposal. Lead and reviewer choices for integration and release are coordination assignments in this mapping.

| Story | Scope | Lead developer | Reviewer | Contributions across roles |
| --- | --- | --- | --- | --- |
| 1 | Reproducible Basys3 project | Chua Choon Hsiang | Han Qi-Ze | Choon Hsiang: build, display clocks/resets, pins and VGA/OLED adapters. Qi-Ze: mouse adapter, initialization and report buffering. Doyeon: shared numerical/interface contract review. |
| 2 | Coherent buffered VGA scenes | Chua Choon Hsiang | Kim Doyeon | Choon Hsiang: rasterization, banks, scanout, magenta overlay and frame/epoch transfer. Doyeon: world snapshot/geometry contract. Qi-Ze: UI revision and view coordination. |
| 3 | Rigid-body arithmetic and motion | Kim Doyeon | Chua Choon Hsiang | Doyeon: formats, mass/inertia, gravity, transforms and combined motion limits. Choon Hsiang: transformed-geometry and display-coordinate review. |
| 4 | Contacts, rotation and left-wall goal | Kim Doyeon | Han Qi-Ze | Doyeon: solver, containment, contact-driven rotation and reliable goal latch. Qi-Ze: consumption of goal/frozen-world events by the controller. |
| 5 | Atomic stroke admission | Kim Doyeon | Han Qi-Ze | Doyeon: geometric validation, body creation, cancellation and reliable results. Qi-Ze: request identity, pending submission and exactly-once allowance accounting. |
| 6 | Mouse gestures and stroke preview | Han Qi-Ze | Chua Choon Hsiang | Qi-Ze: mouse/UI gestures, simplification, final samples and preview state. Choon Hsiang: visible preview, fonts and shared hit-region layout. Doyeon: agreement on sampled path/radius/length rules. |
| 7 | First playable integrated slice | Han Qi-Ze | Kim Doyeon | Qi-Ze: integration lead, minimal controller and admission accounting. Doyeon: connected world/admission/goal behavior. Choon Hsiang: matched world/UI presentation in the same build. |
| 8 | Navigation and attempt lifecycle | Han Qi-Ze | Chua Choon Hsiang | Qi-Ze: lobby, pause/resume/reset, exhaustion, feedback and victory transitions. Doyeon: atomic control responses and frozen/reset worlds. Choon Hsiang: menus and actual-presentation acknowledgements. |
| 9 | OLED and LED status | Chua Choon Hsiang | Han Qi-Ze | Choon Hsiang: OLED layout, text, mailbox and driver timing. Qi-Ze: authoritative mode/allowance/status records and pause/victory LED logic. |
| 10 | Three playable stage layouts | Han Qi-Ze | Kim Doyeon | Qi-Ze: immutable stage data, selection and progression. Doyeon: supported starts, contact/rotation tuning and solutions within five accepted strokes. Choon Hsiang: readable, matching scene presentation. |
| 11 | Integrated board and timing evidence | Chua Choon Hsiang | Kim Doyeon | Choon Hsiang: Vivado build coordination, clocks, display/CDC checks and aggregate reports. Doyeon: worst-case physics/admission workload and numerical behavior. Qi-Ze: mouse/control flows, allowance, reset and stale-event behavior. All three perform their subsystem's board checks. |
| 12 | Assessed release | Han Qi-Ze | Chua Choon Hsiang | Qi-Ze: release checklist, assembly and demo coordination. Choon Hsiang: reproducible project/bitstream and display evidence. Doyeon: physics evidence and resource/timing claims. All three contribute report sections, references/disclosures and peer feedback. |

## Work that can proceed in parallel

Once the relevant Story 1 setup and shared contracts are agreed, the first development tracks are:

| Developer | First independent work | Dependency to coordinate |
| --- | --- | --- |
| Han Qi-Ze | Story 6 capture and gesture logic | Publish sample/preview behavior and agree UI hit regions with Choon Hsiang and geometry thresholds with Doyeon. |
| Kim Doyeon | Story 3, then Stories 4 and 5 | Publish numerical choices before dependent admission and geometry integration. |
| Chua Choon Hsiang | Story 2 world rendering and safe frame transfer | Use the common snapshot/epoch contract; coordinate UI-dependent layers with Qi-Ze. |

Story 7 joins the tracks after its required portions of Stories 1–6 are ready. Stories 8–10 complete the game, displays and stage solutions. Story 11 establishes integrated board evidence; Story 12 packages the accepted result. Story 1 has passed Vivado project creation, synthesis and routed timing; CDC review and behavioral/board acceptance remain pending.

Review-before-coding and review-after-completion remain enabled for every story. This ownership map supports coordinated parallel work; the existing `stories.yaml` dispatcher still lists a sequential execution order. Use the [parallel development plan](parallel-development-plan.md) for shared-file coordination, prerequisite outputs, explicit story selection and milestone exit criteria. It does not remove story review checkpoints or establish hardware acceptance.

## Apply the current game decisions

The named roles remain those in the proposal; later product and architecture decisions govern their implementation:

- Stage selection and clickable menus appear on VGA. OLED shows stage, objective, remaining allowance and status.
- Graphics uses the selected two one-bit black/white banks with a frame-matched magenta ball overlay.
- Gameplay is mouse-only. Qi-Ze handles mouse gesture/button transitions; no physical board-button debouncing or settings feature is added by the proposal wording.
- Qi-Ze owns pause/victory LED behavior. Choon Hsiang owns OLED presentation within the same status story.

## Shared handoff

Use the canonical [story queue](../_bmad-output/specs/spec-q-remastered-on-fpga/stories.yaml), [specification](../_bmad-output/specs/spec-q-remastered-on-fpga/SPEC.md) and [module contracts](../_bmad-output/specs/spec-q-remastered-on-fpga/module-contracts.md). Each lead prepares the detailed story plan, coordinates the named contributors and collects acceptance evidence; the reviewer checks subsystem boundaries and the completed change. Ownership changes do not authorize edits to another subsystem's mutable state.
