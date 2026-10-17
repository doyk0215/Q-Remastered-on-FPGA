---
title: Implement bounded rigid-body arithmetic and motion
type: feature
created: 2026-10-17
status: draft
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

Provide CAP-7's bounded numerical foundation under G-3: geometry kernels, body-property arithmetic, gravity, translation, rotation and complete transformed geometry. Stories 4/5 reuse this foundation for contact response and admission. This story does not claim a completed collision solver, supported stage starts, atomic admission, gameplay controller or solvable stages.

Lead: Kim Doyeon. Reviewer: Chua Choon Hsiang. Han Qi-Ze contributes sampled-length agreement and control/result boundaries. Status is draft: numerical choices and before-coding review remain pending.

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

The [numerical design proposal](../numerical-design-proposal.md) now supplies concrete selections for shared floor-square-root length, internal formats, mass/inertia floors and formulas, reciprocal scales, interpolated turn-phase lookup, rational tick enable, movement/correction allocations and processing-cycle targets. These are review proposals, not adopted parameter-header changes or validated measurements. Doyeon must check bounds/feasibility, Qi-Ze must agree the deliberate near-threshold floor-length policy, and Choon Hsiang must review external geometry/resources before implementation freeze.

## Code and interface boundaries

- Own proposed `rtl/physics/` and numerical kernels; choose final filenames/module boundaries during the reviewed implementation design.
- Keep shared length computation accessible to input/admission through an agreed common implementation or precisely identical rule. Coordinate shared-file edits with Qi-Ze; do not create private competing thresholds.
- Preserve revision 2 physics boundary records and independent diagnostic flags. Early arithmetic work can use controlled body inputs; it must not expose a substitute public world/control protocol for other developers to depend on.
- Choon Hsiang consumes only complete transformed Q6 snapshots. Qi-Ze owns mode/allowance and later controller scheduling; authoritative pause/reset is a coordinated physics transaction when integrated.

## Tasks

- [ ] Publish the numerical decision table, range/error analysis and initial cycle/resource budget; obtain before-coding review and Qi-Ze's length-rule agreement.
- [ ] Implement bounded shared geometry/length kernels, signed conversions, widened arithmetic and explicit rounding/saturation guards.
- [ ] Implement reusable mass/center-of-mass/inertia/inverse-property calculations for accepted sampled polylines; return deterministic fault/rejection information for later admission logic.
- [ ] Implement local-to-world transforms and bounded rotational arithmetic, preserving the same local samples for later display and collision.
- [ ] Implement gravity and translation/rotation integration under the two-substep cadence with fractional precision retained and a combined movement budget.
- [ ] Stage updates so only complete state/geometry can be published. On numerical/workload failure, retain the prior complete world and expose the specified fault rather than wrapping or publishing partial state.
- [ ] Record kernel evidence and actual cycle/resource results; document unresolved contact/admission costs before Stories 4/5 consume the foundation.
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

Before-coding review: pending Chua Choon Hsiang; shared length agreement: pending Han Qi-Ze. Completion review: pending. No numerical choices, RTL, simulation tests or board evidence are approved by this draft. G-3 remains open. Exact deadline is unconfirmed; use M0–M2 in the [parallel development plan](../../../../docs/parallel-development-plan.md).
