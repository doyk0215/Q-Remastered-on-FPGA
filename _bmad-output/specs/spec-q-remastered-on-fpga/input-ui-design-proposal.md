# Stroke capture and shared UI design proposal

Prepared 2026-10-17 for G-4 and readiness item R3. Status: concrete proposal for Qi-Ze's capture ownership review, Choon Hsiang's visual review and Doyeon's geometry/length agreement. It does not implement RTL, generate font assets, approve a story or establish board usability.

This elaborates the existing [module contracts](module-contracts.md), [geometry profile](geometry-profile.md), [core wiring proposal](core-wiring-proposal.md) and [numerical proposal](numerical-design-proposal.md). External records remain revision 2. All coordinates below are proposed common definitions; they must become one coordinated layout source before dependent input/rendering code uses them.

## Coordinates and gesture states

VGA pixels and mouse positions use the same upper-left origin, x=0..639 and y=0..479. Rectangles use half-open bounds: `[x0,x1) × [y0,y1)`. A coordinate exactly at x1/y1 is outside; clipping drawing at the screen edge does not change a hit region. Geometry vertices convert integer pixels to signed Q6 by extending before shifting six bits.

Use these logical input states: IDLE, UI_HELD, DRAW_HELD, BLOCKED_HELD, WAIT_RELEASE and SUBMITTED. They are proposed private FSM states, not new public enums. A submitted stroke slot can coexist with a later UI_HELD gesture; distinguish the outstanding draw lifecycle from the currently held-button gesture rather than forcing one FSM to block all UI.

- IDLE begins a gesture only on an accepted left rising edge and eligible presented context. If the first report after startup/context activation already has left held, enter WAIT_RELEASE; do not synthesize a press.
- Resolve the gesture at press: current enabled control first, then drawable active playfield. A control press is consumed as UI even if its action is disabled; it cannot fall through into drawing.
- UI_HELD remembers the pressed focus and presented attempt/view. Release activates once only if it is in the same enabled control and that identity is still current. Moving through another control does not transfer ownership of the click.
- DRAW_HELD never retests controls to choose a release action. Release finalizes the stroke even over the pause icon. Pause requests during drawing are ignored, not queued.
- BLOCKED_HELD consumes a zero-allowance draw attempt and generates the private feedback intent once, using the core wiring proposal. It neither captures a body nor turns its release into pause.
- Outside-menu presses in PAUSED/VICTORY, ineligible presented context, and context changes during a held gesture consume the remainder of the hold until release. No drawing through a modal or newly appearing screen.
- A pending creation blocks a second draw but permits a fresh eligible UI click, including pause. Right/middle buttons have no gameplay action or pause shortcut.

Controller mode, allowance and actual presented identity remain read-only context to input. Apply controller transition arbitration again when receiving an action; an input gesture decision is not permission to mutate world/game state.

## Deterministic online simplifier

Select a 2-pixel sampling threshold, evaluated as squared integer displacement >=4. Treat the last vertex as a live endpoint and the preceding vertex as the last retained anchor. First vertex is permanently protected; the current endpoint is always protected. Keep coordinates as integer mouse pixels while simplifying, then convert the retained list exactly to Q6.

For every accepted report while DRAW_HELD, including the final release report:

1. Update the cursor from the coherent report. Begin the stroke with the press position as the sole protected start vertex.
2. If the new position equals the live endpoint, leave the path unchanged. With only the start present, create the second live endpoint on the first distinct position, even below the sampling threshold.
3. With at least two vertices, compare the new position to the last retained anchor (the penultimate vertex). If squared distance is below 4, replace only the live endpoint. Otherwise append the new position, promoting the previous live endpoint into the retained set. Comparing to the anchor rather than only the previous report prevents repeated one-pixel motion from suppressing all intermediate sampling.
4. Remove consecutive duplicate vertices, preserving the protected start and current endpoint coordinates. A nonconsecutive return to the start is retained as a closed path; it is not collapsed merely because endpoints coincide.
5. If the temporary list has nine vertices, remove exactly one interior vertex with the least point-to-neighbor-segment error described below. Do not remove the first or last vertex. The list returns to at most eight vertices before publication/submission.
6. Recompute the shared sampled length after the retained list changes. Publish a completed coherent cursor/path record; never overwrite a stalled exposed preview record. New coalescible visual state belongs in a separate pending slot.

For candidate interior vertex B with neighbors A,C, let `u=B-A`, `v=C-A`, `d=dot(v,v)`, `t=dot(u,v)` using exact widened integer arithmetic. Rank squared distance by a rational numerator/denominator:

| Condition | Error numerator / denominator |
| --- | --- |
| d=0 or t<=0 | dot(B-A,B-A) / 1 |
| t>=d | dot(B-C,B-C) / 1 |
| Otherwise | cross(u,v)^2 / d |

Compare two candidates by exact cross multiplication, without approximate division. Choose the lowest error; ties remove the lowest interior index (closest to the start in the current list). Use explicitly widened signed products and unsigned nonnegative error comparisons; a 128-bit comparison staging value is a conservative design choice, not an unrestricted single-cycle multiplier requirement. The candidate set has at most seven interior vertices, so ranking is bounded.

Recompute scores from the current nine-point list, not stale scores from earlier removals. Do not run a second hidden simplifier at release. The algorithm favors significant bends but cannot promise exact curves or a universal error bound with only eight points. Lost detail must be visible as the evolving simplified preview. This is a deterministic proposed tradeoff, not validated gameplay quality.

## Length, short strokes and pending preview

Use the numerical proposal's per-segment Q6 floor square root and exact accumulated length. Minimum released/admitted length is 1024 Q6 units (16 pixels), with at least two distinct vertices. Equality passes only the length condition. The input and admission implementations must use identical arithmetic; do not substitute mouse travel or endpoint separation.

During a held draw, propose showing the current path once two distinct vertices exist, even while it is below the release threshold; with only one distinct point show the cursor alone. This requires an explicit wording clarification before adoption: the common contract's shorthand that a “preview/create” has minimum valid length must distinguish a provisional visual preview from a valid final create. The admitted/create minimum is unchanged. Do not silently modify public packing or suppress the adopted rejection rule to make a short preview valid.

Release first incorporates its final position, completes simplification and length calculation, then publishes the immutable action. Short/degenerate release reaches controller rejection/feedback handling without body insertion or charge; the exact pre-dispatch versus authoritative rejection path must match the reviewed wrapper. The invalid-stroke feedback enum already exists. There is no overlapping-body check inside input.

Input retains the submitted geometry through its terminal lifecycle. Controller retains the matching pending proposal for coherent UI composition, and cursor updates cannot replace it. The pending preview clears/replaces only through terminal result/cancellation and the required-world barrier. A release cannot be sent before its final path is the same completed proposal used by presentation; processing/visual latency must be recorded separately from geometry identity.

## Shared font and visual primitives

Propose a project-authored 5×7 monochrome bitmap glyph set in a 6×8 cell. VGA body labels use integer scale 2 (12-pixel advance, 16-pixel line pitch); headings use scale 3 (18-pixel advance, 24-pixel pitch). OLED uses scale 1. Do not interpolate or antialias. The proposed 96-glyph ASCII table from 32 through 127 contains 3360 bitmap bits before allocation overhead; the final glyph contents, generation source and memory initialization/hash still need publication and readability review.

Use black background, white text/strokes and magenta accent as adopted. Accepted strokes are solid white. Proposed live/pending stroke preview uses the same capsule radius and retained polyline coverage with a distinguishable white diagonal stipple, e.g. `((x+y) & 3) < 2`, leaving non-preview pixels unchanged. No change to submitted collision geometry follows from the stipple pattern.

Cursor hotspot is the exact integer mouse position. Propose an 11×11 cross with a black outline/underlay and white/magenta foreground, clipped at screen edges; its center is not offset for hit testing. The goal edge uses a magenta/white pattern at x=0..3 for visibility, but the physical goal stays at x=0. The moving ball remains the snapshot-matched magenta circle of radius 12; preview/accepted stroke radius stays 8.

Render in the adopted priority: world and snapshot-matched ball, goal/control accents, modal black backdrop/menu, transient feedback, cursor. No alpha blending or permanent VGA status strip. Overlay rectangles can obscure geometry without changing collision or admission boundaries.

## Proposed VGA layout and hit regions

The same half-open rectangle defines the visible control footprint and its clickable region; text is inset within it. Publish the following values once in a proposed shared `q_ui_layout.vh` or an equivalent generated common source after review. Do not duplicate constants in input and graphics.

The selected constants are now provided for review in [q_ui_layout_draft.vh](../../../rtl/include/q_ui_layout_draft.vh). This inactive header is the proposed single source once adopted; the reference checker compares its control bounds and sampling threshold with the proposed layout. Font bitmap contents remain an implementation asset to author and verify within the approved story.

| View/control | Rectangle `(x0,y0,x1,y1)` | Existing focus/action |
| --- | --- | --- |
| Lobby Stage 1 card | (48,160,208,352) | STAGE_0 / SELECT_STAGE with stage 0 |
| Lobby Stage 2 card | (240,160,400,352) | STAGE_1 / SELECT_STAGE with stage 1 |
| Lobby Stage 3 card | (432,160,592,352) | STAGE_2 / SELECT_STAGE with stage 2 |
| Active-play pause control | (12,12,44,44) | PAUSE / PAUSE; non-stage action uses stage NONE |
| Pause Resume | (192,168,448,216) | RESUME / RESUME |
| Pause Reset Stage | (192,232,448,280) | RESET_STAGE / RESET_STAGE |
| Pause Back to Lobby | (192,296,448,344) | BACK_TO_LOBBY / BACK_TO_LOBBY |
| Victory Next Stage, Stages 1/2 only | (192,208,448,256) | NEXT_STAGE / NEXT_STAGE |
| Victory Back to Lobby, Stages 1/2 | (192,280,448,328) | BACK_TO_LOBBY / BACK_TO_LOBBY |
| Victory Back to Lobby, final Stage 3 | (192,240,448,288) | BACK_TO_LOBBY / BACK_TO_LOBBY |

Focus/action names refer to the existing `Q_FOCUS_*` and `Q_ACTION_*` enums; no new encodings are introduced. Only SELECT_STAGE carries its chosen stage key. Other input actions use Q_STAGE_NONE and non-create actions zero their stroke payload as specified by the module contract. The controller, not the button, chooses progression and reset target data.

Lobby heading “Q REMASTERED” begins at (212,64), scale 3. Center “Stage 1/2/3” within each card at y=208 using scale 2, and short descriptive labels “Ramp”, “Bridge”, “Beam” at y=264. These labels describe the adopted draft concepts, not validated solutions. Additional card decoration is noninteractive and must not imply proven stage thumbnails.

Pause/victory modal panel is (144,104,496,392). Center its scale-3 heading at y=120 and scale-2 labels within the button rectangles. The entire outside-panel and inter-button backdrop consumes clicks without actions. The final-stage view omits Next Stage; it does not merely draw the button disabled over an active hit region.

Pause icon's visible two bars fit within its 32×32 footprint: x=21..25 and 30..34, y=20..35 (inclusive decorative pixel extents). A fresh pause press is classified using pre-gesture eligibility; it is not disallowed merely because that accepted sample has left=1. Show pressed/unavailable appearance while held, and activate only on eligible release. Drawing-held pause remains unavailable and never captures that draw release.

Transient feedback panel is (48,424,592,464), body scale 2 and text baseline/top chosen within the panel at y=436. Proposed labels are “Stroke overlaps an object”, “No strokes left”, “Stroke too short” and existing fault labels chosen from the feedback enum. The panel exists only for a feedback event. Controller starts its visible lifetime from matching actual presentation, not publication; the existing one-second duration remains a tunable seed.

All full labels fit the proposed rectangles at these glyph advances; actual glyph readability and cursor/geometry overlap still need display review. Stage/view/mode chooses the active hit table; invisible controls are never interactive. A new view remains ineligible until its matching presentation event reaches the controller/input context path.

## Proposed OLED layout for Story 9

This is a shared visual handoff to Choon Hsiang, not additional Story 6 implementation scope. With 6-pixel cells at scale 1, a 96-pixel row holds 16 cells. Use top-left positions:

| Position | Content |
| --- | --- |
| (0,0) | Stage label, or “Lobby” when no stage is selected |
| (0,16) | “Touch the left” |
| (0,24) | “edge” |
| (0,40) | “Strokes left: 5”, substituting the current allowance |
| (0,56) | “Playing”, “Paused”, “Victory” or “Lobby” |

Unused rows/pixels remain black. Mode/stage selects strings from enums; no string pointers cross the mailbox. The objective wraps deliberately; do not attempt to fit the full phrase on one line. Latch one coherent status record at the safe OLED frame boundary and preserve the supplied driver's falling-edge capture timing. Final empty-lobby allowance wording may use a placeholder rather than pretending a stage is active.

## Processing bounds and acceptance cases

Propose at most 1024 processing cycles per accepted mouse report for capture, one nine-to-eight reduction and shared length calculation, excluding downstream stalls. This is an unmeasured design target. Mouse-button transitions remain reliable under backpressure; no report is consumed into insufficient storage merely to meet that target. Keep exposed action/preview beats stable, store coalescible cursor/preview updates separately and use the existing sticky overflow path if bounded reliable-event storage is exhausted.

Before adoption/acceptance, establish:

- Monotone one-pixel motion still samples along the path; duplicate reports do not grow it; sharp turns and closed/backtracking paths follow the exact tie rule.
- Every publication has at most eight vertices, protected start/current endpoint and the same geometry later submitted. Temporary nine-point storage is never exposed.
- Below/equal/above-threshold behavior matches the shared length kernel and the explicit provisional-short-preview clarification.
- Exact rectangle borders, click-across-controls, outside-modal clicks, context changes during holds and startup-held input produce the specified consumed/cancelled behavior.
- Drawing release over pause never pauses; a fresh pause click can complete while admission is pending; a zero-allowance attempt generates one feedback event without a create.
- Active/final-stage hit tables, visual control footprints and labels agree; font cells fit VGA/OLED rectangles and remain readable over actual gameplay.
- Processing/storage bounds, preview latency and actual display/controller handoffs are measured separately from the visual/numerical design proposal.

Reference checks now cover simplifier invariants, exact hit borders, same-view rectangle separation, label-cell widths and draft-header constants; see the [validation record](../../../docs/reviews/planning-validation-results.md). No behavioral RTL implementation, HDL simulation or board checks were performed. R3 remains specified for human review, not accepted. The additive draft header does not modify the accepted interface/parameter headers.
