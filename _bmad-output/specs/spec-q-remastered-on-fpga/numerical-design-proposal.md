# Shared length and numerical design proposal

Adoption update, 2026-10-17: approved by the user for the initial isolated parallel build, including the corrected 1/8-pixel transform reserve. Earlier proposal/review-pending wording is the design history. Width/range validation, actual kernel cycles, completion review and hardware proof remain implementation obligations.

Prepared 2026-10-17 for Story 3 and readiness item R2. Status: selected design proposal, pending Doyeon's ownership review, Qi-Ze's shared-length agreement and Choon Hsiang's geometry review. No arithmetic RTL, simulation, synthesis or timing validation is supplied by this document.

The binding inputs remain [geometry-profile.md](geometry-profile.md), [module-contracts.md](module-contracts.md) and the current four common headers. This document proposes internal representations and kernels; it does not revise the adopted external 18-bit Q6 geometry, interface revision 2, geometry profile 3 or physics profile 1. New internal constants must be published through coordinated implementation definitions before consumers use them.

## Notation and arithmetic rules

`S(W,F)` is a W-bit two's-complement value scaled by 2^-F; W includes the sign bit. `U(W,F)` is unsigned with the same scale. A product initially retains all operand bits and the sum of their fractional widths. Extend operands before subtraction/addition; do not rely on the unsigned enclosing record bus to preserve signed fields.

Default quantization is round-to-nearest, ties-to-even (RNE), defined symmetrically for negative numbers using magnitude/sign and a widened absolute value. A signed arithmetic shift alone is not this rounding rule. The exceptions below are deliberate: segment length rounds down, conservative extent/norm bounds round up, movement scale factors round down, and theta wraps modulo one turn. No other state arithmetic wraps.

Check range before narrowing. During authoritative updates, arithmetic overflow, invalid divisor, out-of-range transformed geometry or an unrepresentable positive inverse invalidates the staged update: retain the last complete world and set the existing numerical fault. Saturated temporaries may be used for diagnostics, not silently committed as valid physics. A geometrically invalid proposed stroke is rejected without body/impulse/allowance side effects; it must not corrupt existing bodies.

## One shared sampled-length rule

For each consecutive pair of the final sampled vertices, use the signed Q6 stored integers:

```text
dx = sign_extend(x[i+1], 19) - sign_extend(x[i], 19)
dy = sign_extend(y[i+1], 19) - sign_extend(y[i], 19)
n  = unsigned(dx*dx) + unsigned(dy*dy)   // exact widened sum
segment_length_q6 = isqrt_floor(n)
total_length_q6   = sum(segment_length_q6)
```

Keep each signed 19×19 product at 38 bits, extend its nonnegative value into a 39-bit unsigned sum, and pad that radicand to 40 bits for a 20-step digit-by-digit restoring integer square root. The output is `U(20,6)`; accumulate at most seven outputs in `U(24,6)`. A 24-bit accumulator covers even seven maximum 20-bit outputs; reject invalid vertex counts before indexing. A duplicate consecutive point contributes zero; no division is required for that segment.

This is floor of each segment length followed by exact addition, not floor of one Euclidean endpoint distance, and not a fresh length estimate after mass calculation. For at most seven segments, the underestimate relative to the exact sampled path is less than 7/64 pixel. Record that deliberate bias; input and physics must not independently choose different approximations.

Apply the existing minimum against the shared integer result: `total_length_q6 >= 1024`, with at least two distinct vertices and a valid 2..8 count. Equality passes the length criterion. Other geometry/state checks still apply. A path whose exact irrational length lies just above 16 pixels can conservatively fail after this quantization; preview/feedback/admission must agree on the computed path, and the owners must accept that threshold policy before adoption.

Use this same result for mass and body-property weighting. Input uses it after simplification; authoritative admission recomputes it from the exact submitted samples. Both consumers should instantiate the same bounded length kernel source, or use implementations whose equivalence is established before integration. Do not count discarded raw mouse samples.

Design review examples, not executed tests:

| Final Q6 geometry | Expected shared result |
| --- | --- |
| One horizontal 16-pixel segment | 1024; passes length. |
| One horizontal segment of raw Q6 length 1023 | 1023; rejects length. |
| A closed/backtracking path | Sum every retained segment; endpoint coincidence does not imply zero total length. |
| Consecutive repeated vertex | That segment adds zero; two distinct vertices are still required overall. |
| Seven segments with fractional square roots | Apply floor independently seven times, then sum; never round the accumulated result again. |

## Proposed format table

These widths are implementation seeds supported by the bounded inputs; they still need range/error and resource evidence from actual kernels.

| Quantity | Proposed representation | Use |
| --- | --- | --- |
| Published geometry/linear values | Existing `S(18,6)` | External record compatibility; range -2048 to 2048-1/64. |
| Internal center/pose translation | `S(48,24)` | Retain subpixel integration precision; check external representability before world publication. |
| Local admitted vertices | `S(32,16)` | Store geometry relative to the computed center of mass; identical local samples feed contact and display transforms. |
| Linear velocity | `S(40,24)` | Pixels per 60 Hz outer update; movement cap is much tighter than storage range. |
| Angular velocity | `S(32,24)` | Radians per outer update; clamp before integration. |
| Orientation | Unsigned 32-bit turn phase | One full turn is 2^32; modulo wrap is intentional here only. |
| Segment/total sampled length | `U(20,6)` / `U(24,6)` | Exact shared rule above. |
| Mass | `U(32,16)` | Ball=1; stroke mass from total length/64. |
| Inertia | `U(64,16)` | Mass×pixel² about the stored center of mass. |
| Inverse mass / inverse inertia | `U(48,32)` | Relative inverse units; static geometry stores zero. |
| Sine/cosine coefficients | `S(18,16)` | Includes exact +1/-1; 4096-entry full-turn sine table plus interpolation. |
| Candidate contact normal components | `S(24,22)` | Proposed Story 4 normalization output; solver acceptance is separate. |
| Candidate linear impulse | `S(64,24)` | Proposed mass×pixels/outer-update; retain full-width products before rescaling. |
| Candidate angular impulse | `S(80,24)` | Proposed mass×pixel²/outer-update; solver must range-check its actual intermediates. |
| Moment/weighted-sum staging | Up to signed 128-bit accumulators with explicit binary point per operation | Widen sums/products; this is not a request to infer an unrestricted 128×128 single-cycle multiplier. |

Use narrow bounded operands, shared/sequential arithmetic and documented rescaling. The normal/impulse choices provide a proposed handoff, not a completed effective-mass/contact solver contract. Story 4 must establish its denominators, normal fallback, seam policy, storage, sweeps, correction and fault ranges before freezing that solver.

## Mass, center of mass and inertia

Proposed floors are mass 1/4 and inertia 1/16 mass×pixel². These are new tuning seeds pending validation, not previously adopted physics constants. Reject below-minimum input rather than using the mass floor to rescue a degenerate stroke. Accepted path length at least 16 pixels naturally supplies mass at least 1/4.

With mass stored at F=16 and length at F=6, admitted stroke mass is exact:

```text
mass_raw_f16 = total_length_q6 << 4
segment_mass_raw_f16[i] = segment_length_q6[i] << 4
ball_mass_raw_f16 = 65536
```

No extra rounded mass estimate is allowed. The segment masses sum to the stored total mass. Zero-length segments have zero weight and are skipped.

Convert original Q6 endpoints exactly to F=16 and compute the weighted center using widened integers:

```text
com_x_raw_f16 = RNE(sum(len_q6[i] * (ax_f16[i] + bx_f16[i]))
                    / (2 * total_length_q6))
com_y_raw_f16 = corresponding y calculation
```

Subtract that stored center to produce each local vertex. Initial orientation is zero. Before accepting insertion, demonstrate that pose plus local vertices reproduces the submitted external samples under the shared transform/rounding rule; do not silently insert different geometry.

For each segment's local endpoints a,b about the stored center, use uniform-wire inertia:

```text
I_segment = mass_segment * (dot(a,a) + dot(a,b) + dot(b,b)) / 3
I_stroke  = max(sum(I_segment), 1/16)
```

Retain exact products/sums before dividing/rescaling; round once when storing the final inertia rather than repeatedly rounding each dot product. At F=16 local coordinates, quadratic terms have F=32; mass-weighted moments have F=48. Accumulate in signed 128 bits, divide by three and rescale to stored F=16 with one combined RNE operation. Check nonnegativity and narrowing explicitly. This preserves the architecture's wire model; capsule thickness is used for collision/extent, not silently added to the wire inertia model.

For the ball, propose solid-disk inertia `mass * radius² / 2`, giving 72 at mass 1 and radius 12. This is a proposed angular-contact model. Compute reciprocal raw values as `RNE(2^48 / mass_raw_f16)` and `RNE(2^48 / inertia_raw_f16)` to obtain F=32 inverses. Apply the positive floors before reciprocation. Reject/fault if a required positive dynamic inverse cannot be represented; static inverse mass/inertia are deliberately zero.

For creation endpoints bounded to x=0..639 and y=0..479, each segment is at most approximately 798.6001 pixels. Seven segments total less than 5590.201 pixels, so admitted stroke mass is below 87.347. Wider declared accumulators cover generic signed-Q6 kernel inputs as well; accepting out-of-playfield creation is not implied by their capacity. Publish actual worst-case inertia/reciprocal and moment bounds with implementation evidence.

## Orientation and geometry transforms

Use a full-turn 4096×18-bit sine ROM, indexed by the top 12 phase bits. Linearly interpolate the neighboring entries using the remaining 20 bits, wrapping the last neighbor to entry zero. Cosine uses the same table with a quarter-turn phase offset. Coefficients are RNE at F=16; table generation must pin the script, method/error bound and generated memory-file hash before import/build. It is not generated by this plan. Nominal sine payload is 9 KiB; actual BRAM allocation and read-port replication must be reported with the renderer's budget.

Interpolate before multiplying vertices; retain full-width products and round the resulting rotation into the high-precision pose representation. Rotate a local vertex with `x'=c*x-s*y`, `y'=s*x+c*y`, add the center and RNE to external Q6 only for the complete published geometry. Physics contact and graphics consume that same transformed geometry; neither may independently re-rotate or re-sample it.

For phase integration, use the proposed constant `INV_TWO_PI_Q32 = 683565276`, nearest-even to 2^32/(2*pi). One substep phase delta is `RNE(omega_raw_f24 * INV_TWO_PI_Q32 / 2^25)`: this converts radians per outer update to half-update turns in unsigned 32-bit phase. Multiply with explicit signed extension of the positive constant; orientation addition alone wraps modulo 2^32.

Table coefficient quantization, interpolation, phase conversion, local-coordinate quantization and final Q6 rounding all contribute to error. Derive a conservative bound for admitted stroke collision extent up to 1024 pixels; larger extent must fault/reject until a separately proven guard is available. The actual playfield-bounded initial stroke has a substantially smaller extent. Do not claim the motion guard below is established merely because the table size is selected.

## Cadence, gravity and movement ledger

Use a core-domain accumulator initialized to zero: add 60 each 100 MHz cycle; when the result reaches 100000000, subtract 100000000 and emit one outer-tick enable. A 27-bit accumulator covers the pre-subtraction sum. Intervals are 1666666 or 1666667 cycles, with 60 ticks per 100 million cycles. Keep the cadence running independently of whether physics is paused; enable actual advancement only in active play. Do not replay paused ticks or queue missed work.

On an eligible outer tick, stage a private next world, execute two substeps and commit/publish only after both and their required contact work complete. If the next active tick arrives while work is still busy, retain the previous complete world and set the existing physics-deadline fault; never overlap updates or enlarge the timestep.

Use semi-implicit integration as the proposed seed: apply gravity to velocity, incorporate Story 4's bounded impulses in its reviewed order, enforce the motion ledger and then integrate pose. Story 4 must specify contact evaluation/correction ordering without violating that ledger. Gravity in F=24 is exactly 2359296 per outer update of velocity, so each substep adds exactly 1179648 to vy. Pose increments use half the resulting outer-update velocity, with RNE at internal precision. Zero linear velocity at stage load remains required; supported rest is established by contacts in later stories, not by disabling gravity.

For each substep, propose this conservative budget within the adopted maximum of 4 pixels:

| Component | Proposed allocation |
| --- | ---: |
| Integrated translation plus rotation | At most 27/8 pixels = 3.375 |
| Total contact positional-correction motion | At most 1/2 pixel |
| Transform/quantization guard | 1/8 pixel |

For a stroke, use an upward-rounded norm of v and a conservative extent R bounding every local vertex plus capsule radius. Limit `norm(v) + abs(omega)*R` to 27/4 pixels per outer update before dividing time by two. Scale v and omega together by a downward-rounded factor at F=24 when necessary; re-evaluate the bound after rounding, reducing again or failing safely if it still exceeds the allocation. Never scale translation and rotation against independent full budgets. Include forces/impulses before the check.

The reserve was increased during preparation review: one F=16 table rounding and one F=16 interpolation rounding contribute at most 2^-16 combined coefficient error, in addition to the ideal linear-interpolation bound `(2*pi/4096)^2/8`. At R<=1024, conservatively bound one pose's vector transform error by `2*R*coefficient_error + sqrt(2)/128` for coefficient error plus Q6 output rounding, then add phase/internal rounding. Twice that bound is about 0.086 pixel before small phase/internal terms, exceeding 1/16 but fitting 1/8. Implementations must preserve this envelope or revise the guard; the previous 1/16 allocation is superseded.

For the ball, translation uses the same integration allocation; spin does not change occupied circle geometry. Propose an independent angular cap `radius * abs(omega) <= 8 pixels per outer update` for contact stability, to be validated with friction and off-center impacts.

Story 4 must charge the sum of all correction translations and rotational extent motion against the half-pixel correction allowance, not just compare initial/final positions after cancelling corrections. If required resolution exceeds the allowance or the transform error exceeds the guard, reject the staged step and report the fault. The tighter integration limit and half-pixel correction allocation are tunable proposals; stage/contact evidence must show they permit stable support and visible rotation. They are not claims that the chosen solver can resolve every overlap.

## Kernel handoff and cycle targets

Concrete draft declarations are supplied in [q_parallel_ports_draft.vh](../../../rtl/include/q_parallel_ports_draft.vh); selected format/guard constants are in [q_numeric_params_draft.vh](../../../rtl/include/q_numeric_params_draft.vh). They are additive, inactive draft headers pending adoption, not changes to the four accepted headers.

The shared path-length kernel accepts `length_req_valid/ready` plus immutable `length_req_stroke[Q_STROKE_W-1:0]`. It returns `length_rsp_valid/ready`, `length_rsp_total_q6[23:0]`, `length_rsp_two_distinct` and `length_rsp_bad_payload`. Counts 0/1 yield zero length and no two-distinct flag; count >8 is a bad payload and must not index memory. Radius is not part of length calculation. Consecutive zero segments are valid arithmetic inputs. Bad payload returns zero/false properties with the bad flag; caller performs admission/feedback classification, not this kernel.

There is one outstanding request/result per instance; request-ready remains low until the prior response retires. The caller retains its own attempt/path identity while waiting. Exposed result fields remain stable under stalls. This kernel cannot silently switch operands as input's live endpoint changes. No request IDs or body-insertion effects are invented for the arithmetic helper.

All kernels are core-domain, single-outstanding request/result blocks with valid independent of ready, held operands/results while stalled, and explicit completion/fault. Acceptance is not completion. Input and physics can use separate instances of the same length-kernel source so an admission does not monopolize input processing. A final stroke action cannot overtake its own completed length evaluation, and button transitions still require reliable buffering.

Proposed design targets, not measured latencies:

| Kernel/work | Initial bound to implement and measure |
| --- | --- |
| 39-bit segment square root | 20 fixed iterations after operand setup; specify setup/output handshakes separately. |
| Up-to-seven-segment path length | At most 256 processing cycles after request receipt, excluding external result stall. |
| Full admitted body properties | At most 4096 processing cycles including length, moments, reciprocal calculation and setup; excluding external result stall. |
| Transform up to five eight-vertex strokes | At most 2048 processing cycles per full pose-transform pass; report ROM port replication and arbitration. |
| Outer update | Minimum tick budget is 1666666 cycles. Two substeps, up to 1626 contact candidates plus walls, solver sweeps, transforms, publication and up to 259 admission candidates must be budgeted together. No complete solver timing bound is established here. |

Use bounded restoring division/square-root FSMs or another explicitly bounded equivalent; no data-dependent unbounded iterations. Record memory access, arbitration and external response stalls separately from arithmetic processing. A proposed target is not evidence that the implementation meets it. If targets fail, revise the implementation plan before dependent integration rather than hiding latency in a timestep change.

## Owner review and remaining evidence

This proposal supplies a concrete shared length rule, formats, floors, body-property formulas, transform representation, cadence and motion-budget policy for review. It does not close G-3 or R2 acceptance.

Required evidence before numerical freeze/merge:

- Doyeon checks exact range bounds and operator widths, especially full products, weighted moments, inverses and scale-factor edge cases.
- Qi-Ze accepts the shared floor-length threshold policy and capture/backpressure timing; input and admission must agree at below/equal/above-threshold values.
- Choon Hsiang checks external geometry, transform guard, memory payload versus actual BRAM allocation and resource sharing with rendering.
- Establish transform reconstruction/error and combined movement/correction bounds; demonstrate duplicate, near-degenerate, long/backtracking and extreme signed cases when behavioral verification is authorized.
- Measure actual kernel cycles/resources and integrate the remaining Story 4 solver schedule before any 60 Hz worst-case claim.
- Pin/generated-table provenance and memory initialization, then obtain actual synthesis/timing evidence. The four existing Story 1 CDC findings remain separate outstanding work.

Reference/design checks now exercise selected arithmetic/invariants through `scripts/planning/validate_parallel_plan.mjs`; see the [validation record](../../../docs/reviews/planning-validation-results.md). They are not HDL acceptance results. No behavioral HDL simulation or board tests were run. Proposed constants are supplied only in the inactive draft header, not the accepted parameter headers, pending coordinated adoption.
