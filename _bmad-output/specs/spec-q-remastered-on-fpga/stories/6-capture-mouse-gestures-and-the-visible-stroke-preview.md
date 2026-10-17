---
title: Capture mouse gestures and the visible stroke preview
type: feature
created: 2026-10-17
status: ready-for-dev
approved: 2026-10-17
approval_authority: user
approval_scope: before-coding checkpoint and isolated implementation; completion evidence pending
baseline_commit: d96adc2aa72763f5fd27b2cb1988e00c16f5dc79
lead: Han Qi-Ze
reviewer: Chua Choon Hsiang
review_loop_iteration: 0
context:
  - '../SPEC.md'
  - '../module-contracts.md'
  - '../geometry-profile.md'
  - '../prototype-gates.md'
---

## Intent and scope

Approval update: the user adopted the planning package on 2026-10-17, satisfied this story's before-coding checkpoint and approved short provisional previews while retaining the 16-pixel final admission minimum. Earlier pending-review descriptions below record draft preparation, not a claimed teammate approval. Implementation/completion and hardware gates remain open.

Implement CAP-4's deterministic gesture capture and preview state under G-4. Consume coherent mouse reports, simplify the provisional sampled path to at most eight vertices and submit the same visible geometry on release. Recognize UI gestures once using the actually presented attempt/view. Qi-Ze owns capture and action state; Choon Hsiang contributes visible preview, fonts and common layout through the graphics implementation.

This story does not insert bodies, decide overlap acceptance, debit allowance, own game mode or implement the full controller/menu lifecycle. Those decisions remain in physics and Stories 7/8. Lead: Han Qi-Ze. Reviewer: Chua Choon Hsiang. Doyeon agrees geometry/length rules. All reviews and implementation are pending.

## Prerequisites and decisions

| Item | Required action before dependent work |
| --- | --- |
| Mouse source | Consume Story 1's 100 MHz coherent mouse_sample ready/valid interface, not the raw PS/2 pins. Qi-Ze contributes adapter initialization/FIFO checks; physical mouse compatibility remains pending. Controlled reports can exercise isolated capture. |
| G-4 capture algorithm | Qi-Ze publishes sampling threshold, endpoint-preserving simplification, deterministic tie-breaking, duplicate handling and bounded processing/backpressure behavior before capture RTL depends on them. |
| Shared length rule | Doyeon publishes deterministic segment-length calculation/accumulation/rounding; Qi-Ze agrees input and authoritative admission use the same rule and 16-pixel/Q6=1024 threshold. |
| Shared UI geometry | Choon Hsiang publishes fonts, layout and hit regions with Qi-Ze. Input and display consume one definition. Dependent hit-testing/UI layers wait for it. |
| Renderer cooperation | Agree the preview/cursor presentation path and pending-submission behavior with Story 2. Isolated input can publish controlled preview records; visible preview acceptance requires the graphics join. |
| Controller cooperation | Coordinate how revision 2 UI state, presented attempt/view and action readiness reach input; do not privately extend the public interface. Game-state validation and allowance remain controller responsibilities. |

Before dependent input RTL, name the exact core-domain route for controller context, actual presented attempt/view, pending-result status and cancellation. The current action/preview macros define outbound input traffic; they do not themselves deliver this reverse context. Use a reviewed controller/input wrapper or a coordinated shared-contract change, with one owner for each state field. Never infer actual presentation from the newest UIState sent toward rendering or treat action-ready as admission completion.

The [core wiring proposal](../core-wiring-proposal.md) supplies a concrete wrapper design: registered read-only controller context, a single outstanding submitted stroke, reliable `draw_retire` notification, private `blocked_draw` feedback intent, and actual-presentation events retained by the renderer source. These are proposed local ports, not newly published header macros. Qi-Ze and Choon Hsiang must review the map before dependent implementations adopt it.

The [numerical design proposal](../numerical-design-proposal.md) specifies the proposed shared length calculation: floor integer square root per Q6 segment, exact accumulation and comparison against 1024. Its underestimation is less than 7/64 pixel for seven segments, so near-threshold paths require explicit Qi-Ze/Doyeon agreement. Use the same source kernel or establish equivalent results; no input-only approximation is accepted by this draft. The 256-cycle path-processing target is unmeasured and excludes downstream result stalls.

The [capture/UI proposal](../input-ui-design-proposal.md) now supplies R3's concrete selections: a 2-pixel anchor-relative threshold, protected start/live endpoint, exact point-to-segment error ranking and earliest-index tie removal from a temporary nine-point list, gesture-state rules, half-open hit rectangles and 5×7 glyphs. Its per-report target is 1024 processing cycles including simplification and length, excluding downstream stalls. Owner review must explicitly resolve its provisional-short-preview wording clarification before adoption; final admission still requires at least 16 pixels. No proposed layout/font macro is yet published in the shared headers.

## Code and interface boundaries

- Own proposed `rtl/input/`; final module names and any required controller-side context wiring belong in the reviewed plan.
- Consume mouse samples and publish INPUT_ACTION/PREVIEW using the existing role macros in the core clock domain. Hold an exposed valid/data beat stable under backpressure.
- Source cursor coordinates are bounded integers; extend to signed 18 bits before converting to Q6. Use shared stroke radius and minimum length macros.
- Choon Hsiang owns renderer/layout assets. Doyeon owns numerical meaning and authoritative admission. Coordinate shared header edits and route top wiring through the designated maintainer.

## Tasks

- [ ] Publish the G-4 decisions and module/interface map; obtain Choon Hsiang's before-coding review and Doyeon's shared-length agreement.
- [ ] Implement mouse report consumption with coherent buttons/coordinates, bounded capture work and preservation of press/release events. Respect ready/valid backpressure and propagate adapter overflow diagnostics through the agreed fault path.
- [ ] Implement cursor and provisional sampled-path state, endpoint-preserving simplification to eight vertices and deterministic duplicate/tie handling. Keep the visual proposal identical to the submitted polyline/radius.
- [ ] Implement shared length/degeneracy evaluation without authoritative body insertion or allowance changes. Align below/equal/above-threshold behavior with physics.
- [ ] Implement the existing UI gesture rule: a fresh press and release inside the same current control activates once on release. Consume the gesture so it cannot also create a stroke; presses/releases across different controls do not activate either control. Tag actions with the actually presented attempt/view for controller stale-action validation.
- [ ] Disable pause for the whole held-left draw, ignore draw-time pause intent without queuing it and ensure drawing release over the pause icon only ends drawing. A separate completed UI click after release is required for pause.
- [ ] On stroke submission, preserve the pending proposal as required by the common input/controller contract and block a second draw; keep ordinary cursor updates available. Coordinate clearing on terminal result/cancellation rather than treating request receipt as completion.
- [ ] Join with Story 2 to demonstrate the visible cursor/preview and agreed hit regions. Record isolated versus integrated evidence separately.
- [ ] Obtain completion review and provide capture/action handoff to Story 7; leave complete navigation and allowance behavior to Stories 7/8.

## Acceptance matrix

| Gesture/condition | Required evidence |
| --- | --- |
| Straight, bent or over-eight-point movement | At most eight retained vertices; start and current endpoint preserved by the published algorithm. Simplification is deterministic and visible while drawing. |
| Duplicate reports or stationary click | No invalid arithmetic or fabricated path length; fewer than two distinct points remains degenerate. |
| Final sampled length below/equal/above 16 pixels | Input agrees with the shared rounding/threshold rule; equality passes only the length criterion. Physics still owns final admission/state checks. |
| Release after simplification | Submitted samples and radius match the visible proposal; no different high-resolution hidden path is submitted. |
| Drawing release over pause control | Submit/end the drawing gesture; never pause from that release or replay a stored pause request. |
| Fresh UI click after drawing | Produce exactly one UI action when valid in the presented view; prevent that gesture from becoming a new stroke. |
| Press/release crosses controls or outside-menu areas | Apply the agreed press/release rule once; do not invent navigation or allow outside-menu clicks to draw through a paused menu. |
| Pending result or blocked consumer | No second submission, dropped reliable action or overwrite of stalled payload. Cursor/visual coalescing cannot discard reliable release/result handling. |
| Attempt/view changes during gesture or pending submission | Controller can reject stale action identities; clear/cancel provisional state through the shared lifecycle without sending an old draw into a new attempt. |
| Invalid/overlapping release | No local body insertion or allowance debit. Terminal rejection clears the proposal through controller/result coordination and produces the agreed feedback path. |

## Handoff and review

Provide the simplifier/sampling/gesture specification, shared layout and numerical definitions used, module/port map, maximum processing/storage bounds, actual capture/backpressure evidence, visible-preview evidence where available, known limitations and reviewer outcome. Story 7 receives reliable actions and matching proposed geometry; Story 8 supplies full state/navigation policy.

Technical draft review on 2026-10-17 restored the already-adopted same-control press/release rule and made reverse controller/presentation context an explicit interface prerequisite. See the [readiness review](../../../../docs/reviews/parallel-readiness-review.md). This is a Codex document review; Chua Choon Hsiang's named review remains pending.

Before-coding review: pending Chua Choon Hsiang; length/geometry agreement: pending Kim Doyeon. Completion review: pending. No algorithm or UI-layout choice, RTL, simulation tests or board behavior is accepted by this draft. G-4 remains open. Exact deadline is unconfirmed; use M0–M2 in the [parallel development plan](../../../../docs/parallel-development-plan.md).
