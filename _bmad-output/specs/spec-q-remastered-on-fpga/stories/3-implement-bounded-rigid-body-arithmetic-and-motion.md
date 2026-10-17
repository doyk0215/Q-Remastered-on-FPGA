---
title: Implement bounded rigid-body arithmetic and motion
type: feature
created: 2026-10-17
status: in-review
approved: 2026-10-17
approval_authority: user
approval_scope: before-coding checkpoint and isolated implementation; completion evidence pending
baseline_commit: d96adc2aa72763f5fd27b2cb1988e00c16f5dc79
lead: Kim Doyeon
reviewer: Chua Choon Hsiang
review_loop_iteration: 0
context:
  - '../SPEC.md'
  - '../module-contracts.md'
  - '../geometry-profile.md'
  - '../prototype-gates.md'
---

## Intent and scope

Approval update: the user adopted the planning package on 2026-10-17 and explicitly satisfied this story's before-coding checkpoint. Earlier pending-review descriptions below record draft preparation, not a claimed teammate approval. The approved design package is linked from the parallel start checklist. Implementation/completion and hardware gates remain open.

Provide CAP-7's bounded numerical foundation under G-3: geometry kernels, body-property arithmetic, gravity, translation, rotation and complete transformed geometry. Stories 4/5 reuse this foundation for contact response and admission. This story does not claim a completed collision solver, supported stage starts, atomic admission, gameplay controller or solvable stages.

Lead: Kim Doyeon. Reviewer: Chua Choon Hsiang. Han Qi-Ze contributes sampled-length agreement and control/result boundaries. The isolated implementation is in review under the recorded user approval; named completion review remains pending.

## Binding inputs

- Application HDL is Verilog-2001 in the 100 MHz core domain. Use the four common headers; external geometry/linear state is signed 18-bit Q6. Enclosing record buses are unsigned, so extract signed values explicitly and widen intermediates before arithmetic.
- Keep ball radius 12 pixels, stroke radius 8, fixed-capsule minimum/default radius 8, at most eight stroke vertices and five admitted strokes. Never substitute endpoint distance for sampled-polyline length.
- Use adopted gravity 9/64 pixels per 60 Hz outer-update squared, restitution 1/8, friction 1/2, ball mass 1 and stroke mass equal to sampled-polyline length/64.
- Use two substeps per outer update. Bound combined translation/rotation travel to 4 pixels per substep for the ball center and every occupied stroke point. The bound `norm(v) + abs(omega)*R <= 8 pixels per outer update` is shared, not a separate full allowance for each component.
- Schedule outer updates with a core-domain rational clock enable: 100 MHz divided by 60 is not an integer. Publish the enable implementation and bounded integer tick intervals; do not silently use a rounded divider, add a physics clock domain or queue overlapping updates. A tick while busy must follow the declared workload-fault policy.
- Physics owns authoritative bodies, pose and world revisions. Display receives complete transformed geometry, never a partially updated body table.

## Numerical decisions before dependent implementation

| Decision | Owner output and review |
| --- | --- |
| Formats and rounding | Doyeon publishes widths/scales for mass, inertia, inverses, phase, trigonometric coefficients, accumulators and products; define rounding/rescaling, saturation and fault behavior. Choon Hsiang reviews external geometry consistency. |
| Shared length arithmetic | Specify a deterministic segment-length approximation/calculation, accumulation width and threshold rounding. Qi-Ze agrees the same rule for capture and Story 5 admission, including exact 16-pixel equality and near-threshold cases. |
| Body properties | Define length-weighted center of mass, local vertices, shape-derived wire inertia and positive floors. Prove intermediate ranges for the bounded geometry, including long/backtracking paths. Static inverse properties are zero. |
| Rotation kernel | Select phase/trig representation, source provenance if reused, approximation error and bounded transform schedule. Publish transformed-geometry error/guard assumptions. |
| Integration and limits | Define substep gravity precision, update order, shared translation/rotation clamp, conservative extent R, numerical guard margins, ball angular limit and correction-motion accounting contract for Story 4. |
| Bounded schedule | Publish kernel latencies, shared arithmetic arbitration and memory/table resources. Reserve the future contact/admission workload; isolated arithmetic throughput is not a completed 60 Hz solver proof. |

Publish decisions in the canonical numerical/geometry companions and coordinated shared parameters where consumed. Internal format choices must not silently change packed interfaces. Contact seams, storage/overflow, solver/correction sweeps and warm-start decisions remain Story 4/G-3 follow-up; identify their required inputs here.

The [numerical design proposal](../numerical-design-proposal.md) now supplies concrete selections for shared floor-square-root length, internal formats, mass/inertia floors and formulas, reciprocal scales, interpolated turn-phase lookup, rational tick enable, movement/correction allocations and processing-cycle targets. The initial isolated implementation was subsequently adopted by the user as recorded above. The [implemented numerical foundation](../numerical-foundation.md) records checked bounds, unchanged shared parameters and actual verification. Named teammate length-rule/external-geometry review remains part of completion and integration; it is not impersonated by the implementation evidence.

## Code and interface boundaries

- Own proposed `rtl/physics/` and numerical kernels; choose final filenames/module boundaries during the reviewed implementation design.
- Keep shared length computation accessible to input/admission through an agreed common implementation or precisely identical rule. Coordinate shared-file edits with Qi-Ze; do not create private competing thresholds.
- Preserve revision 2 physics boundary records and independent diagnostic flags. Early arithmetic work can use controlled body inputs; it must not expose a substitute public world/control protocol for other developers to depend on.
- Choon Hsiang consumes only complete transformed Q6 snapshots. Qi-Ze owns mode/allowance and later controller scheduling; authoritative pause/reset is a coordinated physics transaction when integrated.

## Tasks

- [x] Publish the numerical decision table, range/error analysis and initial cycle/resource budget; before-coding checkpoint satisfied by the recorded user approval. Named Qi-Ze length-rule agreement remains explicitly pending at completion review.
- [x] Implement bounded shared geometry/length kernels, signed conversions, widened arithmetic and explicit rounding/saturation guards.
- [x] Implement reusable mass/center-of-mass/inertia/inverse-property calculations for accepted sampled polylines; return deterministic fault/rejection information for later admission logic.
- [x] Implement local-to-world transforms and bounded rotational arithmetic, preserving the same local samples for later display and collision.
- [x] Implement gravity and translation/rotation integration under the two-substep cadence with fractional precision retained and a combined movement budget.
- [x] Stage updates so only complete state/geometry can be published. On numerical/workload failure, retain the prior complete world and expose the specified fault rather than wrapping or publishing partial state.
- [x] Record kernel evidence and actual cycle/resource results; document unresolved contact/admission costs before Stories 4/5 consume the foundation.
- [ ] Obtain completion review and hand off numerical contracts and modules to Stories 4/5 and the Story 7 integration lead.

## Acceptance matrix

| Condition | Required evidence |
| --- | --- |
| Negative coordinates and product extremes | Signed behavior is correct; widened products/accumulators do not wrap silently. Rounding and saturation match the published rules. |
| Duplicate/zero-length segments and short paths | Defined kernel outputs avoid division by zero. Later admission can reject fewer than two distinct points or total length below 16 pixels without side effects. |
| Minimum 16-pixel accepted path | Length equality is preserved and the adopted mass is 0.25 before internal representation; floors and inverses remain positive/bounded. |
| Translation and rotation | Geometry matches the same local sample set at the new pose within documented error, without an independently changed display approximation. |
| Gravity split across substeps | Fractional increments are retained; integer truncation cannot silently remove gravity. Reference expectations use the declared integration order. |
| Combined motion demand exceeds budget | Conservatively bound translation plus rotational point travel after force/impulse changes; publish margins and the Story 4 correction contract. |
| Paused/unchanged controlled state | No unintended integration; complete state can be reused without fabricating a new physics advance. Full pause protocol is accepted during later integration. |
| Busy tick or numerical fault | No overlapping update, enlarged timestep or partial world publication; preserve the last complete state and report the condition. |
| Long-run outer-update cadence | The enable schedule represents 60 updates per 100 million core cycles when work meets its budget; measure the permitted interval variation separately from kernel/solver latency. |
| Maximum supported body/vertex counts | Kernel schedule and storage remain bounded. Report actual measurements and outstanding solver/admission reservations separately. |

## Handoff and review

Provide the numerical format/range table, shared length rule, kernel ports/latencies, rounding and error bounds, mass/inertia floors, transform and speed-limit rules, resource/cycle evidence and limitations. Story 4 receives contact-ready geometry/arithmetic; Story 5 receives shared length and body-property calculations. Renderer sees unchanged external Q6 records.

Technical draft review on 2026-10-17 added the noninteger 100 MHz/60 cadence requirement and its acceptance case. See the [readiness review](../../../../docs/reviews/parallel-readiness-review.md). This is a Codex document review; Chua Choon Hsiang's named review remains pending.

Before-coding checkpoint: satisfied by the user on 2026-10-17 for isolated implementation. Named shared-length agreement: pending Han Qi-Ze. Named completion review: pending Chua Choon Hsiang. The implementation and measured isolated evidence below are available for that review; no board evidence is claimed. G-3 remains open. Exact deadline is unconfirmed; use M0–M2 in the [parallel development plan](../../../../docs/parallel-development-plan.md).


## Review Triage Log

The three context-free Build review layers ran after the isolated RTL and timing checks. Each finding is recorded before grouping. The baseline also includes previously published planning/onboarding changes; their existing defects are deferred rather than silently added to this physics change.

| ID | Layer / finding | Verdict and verified evidence | Route |
| --- | --- | --- | --- |
| BH-1 | Blind: limiter bound checks trust the returned bound | Medium: the clamp tests compare `bound` to the limit without independently deriving point travel from returned v/omega. An underestimated reported bound would escape these assertions. | Patch; group with VG-2 independent limiter oracle. |
| BH-2 | Blind: production-width divider cases absent | Low: exhaustive division covers W=8, while caller vectors exercise only selected W=64/96 inputs. Directed large-denominator/remainder/tie cases are absent for the reusable production-width helpers. | Patch directed arithmetic cases. |
| BH-3 | Blind: reset cancellation/recovery untested | Medium: bank deadline rollback resets helpers, but no directed test interrupts each arithmetic helper or resets a held response and then proves fresh-request recovery. | Patch reset/recovery cases. |
| BH-4 | Blind: immutable request tests incomplete | Medium: request registers exist, but only length changes its live payload in current tests; properties, transforms and integration lack this explicit regression. | Patch mutate-after-acceptance cases. |
| BH-5 | Blind: trig wrap/quadrant boundary cases absent | Medium: zero/quarter/random transform vectors do not explicitly cover adjacent boundary phases and final-entry interpolation wrap. | Patch directed trig boundary cases. |
| BH-6 | Blind: signed COM ties absent | Medium: the negative horizontal fixture has an exactly representable midpoint. Three-point paths with segment lengths 1+1023 or 3+1021 and final y=+/-1 Q6 raw exercise odd/even positive/negative half ties. | Patch property oracle fixtures. |
| BH-7 | Blind: maximum extent/output boundary transforms absent | Medium: current transform fixtures fit ordinary playfield extents, leaving the adopted 1024-pixel envelope and exact signed-Q6 representability edges unexercised. | Patch transform boundary fixtures. |
| BH-8 | Blind: late integration overflow rollback absent | Medium: zero extent faults before integration; a near-maximum 48-bit position with valid velocity/extent reaches the late arithmetic-overflow branch without an existing assertion. | Patch late overflow/retained-state test. |
| BH-9 | Blind: BMAD setup check is incomplete | Medium: the existing `setup_bmad.mjs --check` probes uv and SKILL.md presence but prints Python as a description, without running the renderer or checking its support files. This predates Story 3 in published commit 7cd0c63. | Defer onboarding maintenance. |
| BH-10 | Blind: AGENTS says no draft-header consumers exist | Low: new Story 3 modules now consume those definitions, so that sentence is stale. The workflow routes agent-context edits to separate context maintenance. | Defer agent-context update. |
| EH-1 | Edge: interpolation rounds delta before adding base | Medium: at phase 0x00280000 the table neighbors are 201 and 302. The current expression returns 201+RNE(50.5)=251, while RNE(251.5)=252. The Python oracle repeats the same mistake. The approved whole-coefficient RNE rule is unambiguous; correcting the two expressions is a mechanical patch with no new public surface or design choice. | Patch RTL/oracle and exact tie regression. |
| VG-1 | Verification: extent validator never sees local y | Medium, pre-verified: existing bank fixtures have zero local y; omitting y-squared would evade them and admit an understated rotation extent. | Patch valid/rejected vertical/diagonal load cases. |
| VG-2 | Verification: a zero scale would pass clamp assertions | Medium, pre-verified: changed-components and upper-bound checks permit excessive damping to zero; no exact expected clamped v/omega/pose oracle exists. | Patch; group with BH-1 independent limiter oracle. |

All 11 current-story findings were patched and verified by the post-review main/arithmetic regression. The two maintenance findings are recorded in [deferred work](../../../implementation-artifacts/deferred-work.md). Interpolation now rounds the complete coefficient once: phase 0x00280000 returns 252, with signed tie and quadrant/wrap regressions. No approved numerical policy or public record changed. Named completion review remains pending.

## Implementation evidence for completion review

The [numerical foundation](../numerical-foundation.md) is the module-port, fixed-point, range/error, latency/resource and integration handoff. Implementation resides in `rtl/common/` and `rtl/physics/`; independent golden generation, bounded RTL tests and reproducible OOC scripts reside in `scripts/physics/` and `sim/physics/`.

| Acceptance condition | Actual evidence |
| --- | --- |
| Signed extremes/rounding | 129 length vectors, 44 property vectors, 135 transforms, 16 directed trig phases and eight exact limiter vectors; 65536 eight-bit unsigned division pairs in both floor/RNE modes; 32768 signed RNE cases; directed 64/96-bit division, signed COM ties, maximum extent/Q6 boundaries and late overflow rejection. |
| Duplicate/short/minimum path | Zero/duplicate/count rejection cases; exact floor-per-segment length equality at 16 pixels, mass 0.25 and positive inertia/inverses. |
| Translation/rotation | Transform vectors checked against exact table interpolation and real-angle error envelope; integration checks independently verify positive/negative phase deltas and wrap; full bank geometry checked against independently generated pose/phase results. |
| Fractional gravity | Twenty successive half-updates match exact retained Q24 gravity and declared velocity-first integration. |
| Combined motion | Independent integer oracle checks exact clamped velocities, spin, pose, phase and bounds, including angular RNE stasis and ball spin cap. Private load checks vertical/diagonal extents and rejects under-declared bounds. |
| Pause/failure/publication | Held responses, reset/recovery, immutable accepted payloads, complete-bank publication, inactive tick, busy-tick abort, late position-overflow rollback and forced counter exhaustion all asserted in xsim. |
| Rational cadence | Full 100000000-cycle xsim measured 60 ticks: 20 intervals of 1666666 and 40 of 1666667 cycles. |
| Maximum schedule | All six bodies, with eight retained points in each of the five strokes simultaneously and opposite nonzero spins: 1301-cycle outer update; property max1331, transform max59, half-update max174. Contact/admission workload excluded. |

Reproduction: `scripts/physics/verify_story3.ps1`; optional `-SkipCadence` explicitly skips the long cadence case. Simulation logs and generated vector assets remain under ignored `build/story3/`. Named human completion review and aggregate integration/contact/admission/board gates remain open. The implementation is recorded on the local feature branch; no push or board programming was performed.

Routed isolated evidence (Vivado 2025.2, xc7a35tcpg236-1, 10 ns core): property serial2 uses 3980 LUT / 4264 registers / 16 DSP / 0 BRAM, internal setup +0.421 ns / hold +0.098 ns; post-review motion reviewfix uses 9312 LUT / 16975 registers / 44 DSP / 2 BRAM, all-path and internal setup +0.085 ns / hold +0.096 ns. Both pass complete timing coverage under the explicitly assumed synchronous input arrival 1.5..2.5 ns / output delay 0.5..2.5 ns boundary. Actual same-core integration must replace that isolated boundary model. Exact reports are `build/story3/synth_q_body_properties_serial2/timing_boundary.rpt` and `build/story3/synth_q_motion_bank_reviewfix/timing_routed.rpt`; internal setup/hold reports and resource/DRC/checkpoints are alongside them. Earlier failed timing/resource/boundary development reports remain preserved.

Handoff checks: `check_workflow.mjs --story 3` PASS; planning reference validator PASS 12444 checks with all 15 baseline hashes preserved; `git diff --check` clean. `setup_bmad.mjs --check` finds BMAD 6.12.2 / 29 skills but reports uv absent from the implementation shell PATH; the coordinator separately executed the rendered workflow with a temporary runtime PATH. Named completion review is still pending; status remains in-review until that checkpoint accepts the evidence.
