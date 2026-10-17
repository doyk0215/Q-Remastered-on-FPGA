# Parallel implementation start checklist

First time joining the project? Start with the [teammate guide](TEAMMATE-GUIDE.md) for local BMAD setup, your branch and the starter prompt. Coding agents must read [AGENTS.md](../AGENTS.md).

Prepared 2026-10-17. This is the entry point for the group S2_19 planning handoff. The bundle is prepared for approval, not a declaration that the human before-coding checkpoints have passed. No implementation threads or developer branches are launched by this document.

**Approval update, 2026-10-17:** the user answered “Yes” to adopting the package and treating their approval as the before-coding checkpoint for Stories 2, 3 and 6, including short provisional previews. That explicit user authorization satisfies the start checkpoint in place of the pending named-review outcomes; it is not attributed to any teammate. Approved isolated parallel implementation may begin. Earlier pending-approval descriptions below are the preparation record, superseded by this update. Runtime evidence, completion reviews, CDC/board gates and exact course dates remain outstanding.

## Approval package

| Artifact | Purpose |
| --- | --- |
| [Parallel development plan](parallel-development-plan.md) | Ownership, branches, dependencies, shared files, integration and M0–M5 exit criteria. |
| [Story ownership](story-ownership.md) | Existing named leads and reviewers; state ownership remains binding. |
| [Story 2](../_bmad-output/specs/spec-q-remastered-on-fpga/stories/2-render-coherent-buffered-vga-scenes.md) | Choon Hsiang's graphics assignment; reviewer Doyeon. |
| [Story 3](../_bmad-output/specs/spec-q-remastered-on-fpga/stories/3-implement-bounded-rigid-body-arithmetic-and-motion.md) | Doyeon's numerical assignment; reviewer Choon Hsiang. |
| [Story 6](../_bmad-output/specs/spec-q-remastered-on-fpga/stories/6-capture-mouse-gestures-and-the-visible-stroke-preview.md) | Qi-Ze's input assignment; reviewer Choon Hsiang. |
| [Core wiring proposal](../_bmad-output/specs/spec-q-remastered-on-fpga/core-wiring-proposal.md) | Single acknowledgement receiver/relay, controller context, pending/retirement/cancellation and epoch paths. |
| [Numerical proposal](../_bmad-output/specs/spec-q-remastered-on-fpga/numerical-design-proposal.md) | Shared length and fixed-point choices, motion guard, cadence and kernel targets. |
| [Input/UI proposal](../_bmad-output/specs/spec-q-remastered-on-fpga/input-ui-design-proposal.md) | Simplifier, exact hit geometry, gestures, fonts and short-preview clarification. |
| [Renderer proposal](../_bmad-output/specs/spec-q-remastered-on-fpga/renderer-design-proposal.md) | Memory allocation, exact scanline span engine, cycle/resource targets, pixel and mailbox timing. |
| [Readiness review](reviews/parallel-readiness-review.md) | Technical findings, evidence limits and remaining review/adoption gates. |
| [Validation record](reviews/planning-validation-results.md) | Reference-check scope/results and Vivado declaration parsing, with explicit hardware-proof limitations. |

## Start decision

| Check | Current disposition |
| --- | --- |
| Common platform baseline | Published `d96adc2`; Vivado 2025.2 setup/synthesis/route/timing pass, zero DRC violations. |
| Three detailed assignments and R1–R4 choices | Written and cross-linked; owner adoption/human review still pending. |
| Source-byte reproducibility | `.gitattributes` pins LF for source/RTL and CRLF for the supplied master XDC. Restore only newline conversions proven by the manifest hashes. Direct hash verification is part of the reference checker. |
| Reference/design consistency | Run `node scripts/planning/validate_parallel_plan.mjs`; results go to ignored `build/planning-validation.json`. Re-run after changes. This is not HDL simulation or a throughput/CDC proof. |
| Concrete shared declarations | Inactive `q_parallel_ports_draft.vh`, `q_numeric_params_draft.vh` and `q_ui_layout_draft.vh` supply the proposed ports/constants. Accepted record headers remain unchanged. Adopt these together at the approval checkpoint before dependent implementations consume them. |
| Fresh source checkout | A fresh staged-tree checkout passed reference checks with all fifteen baseline source hashes exact and zero newline repairs. Baseline HDL/imported-source contents are unchanged by the final planning patch. |
| Course dates | Exact demonstration, submission and peer-feedback dates remain unconfirmed; Qi-Ze records them before dated milestone commitments. They need not block approved isolated subsystem implementation. |
| Human before-coding review | Pending Doyeon for Story 2, Choon Hsiang for Stories 3/6 and cross-owner agreements, or an explicit user-authorized alternative recorded without impersonating those reviewers. |
| Short-preview semantics | Approval needed: provisional held paths with two distinct vertices may be displayed below 16 pixels; released/admitted strokes still require the shared computed length >=16 pixels. Reconcile the common contract wording when adopted. |
| Physical/CDC acceptance | Remains open under Story 1/G-2. Blocks actual peripheral/scanout acceptance and board claims, not all isolated design/RTL work. |

Do not label the team implementation-ready until the applicable before-coding reviews/approval are recorded. The reference checks can establish consistency of this proposed design but cannot sign for a human developer or prove the eventual RTL.

## First build tasks after approval

Each developer pulls the published planning commit and works in their own checkout/branch. Do not run three sequential BMAD auto-dispatchers in one checkout. Suggested branches below are not created yet. Do not change the canonical story queue/checkpoint flags just to force parallel selection.

| Developer/branch | First bounded deliverable | Dependency boundary |
| --- | --- | --- |
| Qi-Ze — `codex/story-6-input` | Implement controlled-report capture/simplifier, action/preview holding and private controller-context wrapper against the approved core/UI proposal. Proposed files: `rtl/input/q_stroke_capture.v`, `rtl/input/q_input_wrapper.v`. | Coordinate the common layout source with Choon Hsiang and shared length kernel with Doyeon. Use controlled context until the real Story 7 controller is connected; do not claim board/input acceptance. |
| Doyeon — `codex/story-3-physics` | First publish the reusable length/rounding kernel and its module ports, then body properties, transforms and bounded motion. Proposed common file: `rtl/common/q_path_length.v`; numerical modules under `rtl/physics/`. | Qi-Ze consumes the same shared kernel source. Keep adopted external records unchanged; coordinate any new shared definitions before consumers diverge. Solver/admission are Stories 4/5. |
| Choon Hsiang — `codex/story-2-rendering` | First implement bank packing and exact span engine with controlled snapshots, then frame transfer/scanout/compositor. Proposed files: `rtl/graphics/q_framebuffer_bank.v`, `q_capsule_span.v`, `q_frame_source.v`, `q_scanout.v`, `q_ui_compositor.v`. | Own the single shared layout/font asset publication and aggregate memory budget. Real scanout/peripheral integration waits for the relevant G-2 reset/CDC readiness; isolated blocks can use controlled clocks/records. |

Final file decomposition can change in the assigned review if owners update the map together. Choon Hsiang remains the sole coordinated editor for top/build changes; Qi-Ze coordinates integration and merge order. First merge the approved shared length/layout interfaces, then their consumers. Each owner supplies before/after review and actual verification evidence; a design reference model is not the finished hardware kernel.

## Platform follow-up tickets

| Ticket | Owner | Required evidence before closing |
| --- | --- | --- |
| Two PS/2 CDC-1 endpoints in supplied deglitch logic | Choon Hsiang coordinates; Qi-Ze supplies mouse checks | Review raw sampling/frontend behavior and scoped timing exceptions; demonstrate actual compatible mouse initialization/report transitions and overflow/backpressure behavior. Preserve supplied-source provenance. No waiver is implied. |
| Two generated-domain reset CDC-10 endpoints | Choon Hsiang | Review combinational async assertion and synchronous release topology; establish lock-loss/startup recovery and actual constraints/placement. The current custom synchronizers are not automatically certified by their stage count. |
| JB wiring and converter/OLED/mouse models | Choon Hsiang with all owners | Confirm physical connection/orientation and peripheral models, then collect actual display/input evidence. Planned JB is not a connected-board observation. |
| Complete integrated 60 Hz/resource claims | Doyeon and Choon Hsiang, coordinated by Qi-Ze | Measure solver/admission/frame worst cases, memory primitive allocation, core/pixel timing and responsiveness. Proposed cycle budgets, including the radius-eight raster case, remain targets. |

These tickets are assigned work with acceptance criteria, not missing planning documents or reasons to delay every isolated block. They must remain visible through Story 7/11.

## Human approval record

- Planning bundle adoption: approved by the user on 2026-10-17.
- Story 2 before-coding checkpoint: satisfied by explicit user authorization; no Doyeon sign-off is claimed.
- Story 3 before-coding checkpoint: satisfied by explicit user authorization; no Choon Hsiang sign-off is claimed.
- Story 6 before-coding checkpoint: satisfied by explicit user authorization; no Choon Hsiang sign-off is claimed.
- Provisional-short-preview clarification: approved. A held path may be visible below 16 pixels; final admission still enforces >=16 pixels.
- Exact course deadlines/source: pending.

Record only actual approvals and supplied dates. An explicit user override of review arrangements must be written as that user's authorization; it must not be attributed to a named teammate.
