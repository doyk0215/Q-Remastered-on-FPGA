# Parallel development plan — group S2_19

Prepared 2026-10-17. This is the coordination plan for the ownership split in [story-ownership.md](story-ownership.md). It defines work order and handoffs; named reviewer approval and story acceptance are still pending. It does not mark any story or prototype gate complete.

## Starting point and deadlines

Use commit `d96adc2` or a descendant containing its Vivado fixes as the common starting point. Vivado 2025.2 project creation, synthesis and routing passed for xc7a35tcpg236-1 with JB selected for the planned OLED connection. Timing passes and DRC has zero violations. Story 1 remains in progress: four CDC findings, reset/input behavior, physical wiring and peripheral operation still require evidence. Source byte hashes also need a checkout line-ending policy; see [hardware-bringup.md](hardware-bringup.md).

The recorded course context says the demonstration is in **Week 13**, with a typical **2–5 minute** demonstration. Exact calendar dates and submission cutoffs are unconfirmed. The sequence below is a proposed internal schedule, not a claim about course deadlines.

| Date to confirm | Responsible person | Required action |
| --- | --- | --- |
| Week 13 demonstration date and slot | Han Qi-Ze | Confirm from the course portal/instructions and record the source. |
| Source/bitstream/report submission cutoff and timezone | Han Qi-Ze | Confirm the actual deadline, naming and upload requirements. |
| Peer-feedback deadline | Han Qi-Ze | Confirm separately; do not assume it matches submission. |
| Internal milestones M0–M5 below | Qi-Ze with all three developers | Set calendar targets by working backward from the confirmed course dates, reserving board debugging and packaging time. |

Do not derive a calendar date from “Week 13” alone. Until the dates are confirmed, work against the ordered exit criteria below. Release requirements remain in [delivery-requirements.md](../_bmad-output/specs/spec-q-remastered-on-fpga/delivery-requirements.md).

## Roles and first assignments

| Developer | First assignment | Reviewer | Follow-on work |
| --- | --- | --- | --- |
| Han Qi-Ze | Story 6: gestures, capture, simplification and preview state | Chua Choon Hsiang | Lead Stories 7, 8, 10 and 12; own controller, stages and LEDs. |
| Kim Doyeon | Story 3: arithmetic, mass/inertia, transforms and bounded motion | Chua Choon Hsiang | Lead Stories 4 and 5; own physics, accepted world state and goal events. |
| Chua Choon Hsiang | Finish relevant Story 1 platform checks and develop Story 2: buffered rendering/frame transfer | Kim Doyeon for Story 2; Han Qi-Ze for Story 1 | Lead Stories 9 and 11; own display implementation and Vivado build coordination. |

Story 1 closure and Story 2 compete for Choon Hsiang's time; they are one developer's scheduled work, not two assumed parallel resources. Qi-Ze contributes mouse-adapter checks; Doyeon reviews shared numerical/interface assumptions. Reviewers retain their own development responsibilities.

## Milestones and dependency order

| Milestone | Work and accountable lead | Exit criteria |
| --- | --- | --- |
| M0 — Ready to split | Qi-Ze coordinates; all three review their boundaries | All developers have the common source baseline. Detailed Story 2, 3 and 6 plans name files, inputs, outputs and acceptance evidence, and receive their assigned before-coding review. Shared decisions below have owners and delivery points. |
| M1 — Independent foundations | Qi-Ze: 6; Doyeon: 3; Choon Hsiang: 1/2 | Capture and display agree on preview/UI geometry; physics publishes numerical choices; renderer publishes bank/schedule/resource choices. Each track demonstrates its relevant contract behavior with controlled inputs. Platform work records CDC dispositions and outstanding hardware evidence. |
| M2 — First playable slice | Qi-Ze leads Story 7; Doyeon completes required 4/5 work; Choon Hsiang connects presentation | Required portions of Stories 1–6 are reviewed and available. One build loads the development fixture, captures/adopts a stroke, debits once, shows gravity/contact/rotation and detects the left-edge goal with coherent UI/world presentation. Board evidence is required before calling the slice board-playable. |
| M3 — Complete gameplay | Qi-Ze: 8/10; Choon Hsiang: 9; Doyeon: physics/control support | Lobby, pause/resume/reset/return, allowance/rejection feedback, OLED/LED state and all three stages work together. Stage solutions and supported starts are demonstrated; Stage 3 includes contact-driven rotation. |
| M4 — Board acceptance | Choon Hsiang leads Story 11; each developer validates their subsystem | Close G-1 through G-7 with actual peripheral compatibility, reset/stale-event behavior, worst-case physics/admission/frame workload, aggregate utilization and timing evidence. Unresolved faults block acceptance. |
| M5 — Assessed release | Qi-Ze leads Story 12; Choon Hsiang reviews | Package the board-tested bitstream and reproducible sources, meet archive/report/disclosure requirements, verify download/unzip, complete peer feedback and rehearse the short demo. |

Stories 2, 3 and 6 may progress independently after M0 using the published interfaces and controlled inputs. Story 4 depends on Story 3's numerical foundation; Story 5 depends on the shared geometry/contact kernels and capture-length agreement. They stay under Doyeon's ownership. Input/display-dependent portions wait for G-4 decisions, and final graphics tasks wait for G-5 choices. Internal physics choices must be published before dependent integration under G-3.

Board access does not block isolated arithmetic, gesture or rasterizer development. However, actual peripheral/scanout integration must satisfy the relevant G-2 prerequisites. Any temporary behavior or synthetic source must be identified as development-only and cannot establish hardware acceptance. Use [prototype-gates.md](../_bmad-output/specs/spec-q-remastered-on-fpga/prototype-gates.md) for the full evidence requirements.

## Shared decisions to publish

| Decision/output | Owner and collaborators | Needed by |
| --- | --- | --- |
| Interface revision 2, packed fields, units, IDs, ready/valid and cancellation rules | Existing common contract; Qi-Ze coordinates changes with Doyeon and Choon Hsiang | All three detailed story plans; consumers use the existing headers immediately. |
| Deterministic simplification, sampling threshold, endpoint retention and duplicate handling | Qi-Ze; Choon Hsiang reviews visible behavior and Doyeon reviews admitted geometry | Story 6 capture implementation and matching preview. |
| Sampled-polyline length kernel/rounding and threshold comparison | Doyeon owns numerical definition; Qi-Ze implements/consumes the identical rule | Input/admission agreement before Stories 5/6 integration. Keep the adopted 16-pixel minimum. |
| Fonts, common hit regions and layout definitions | Choon Hsiang owns the shared visual definition; Qi-Ze agrees clickable regions | UI-dependent input and rendering implementation. Store one common definition, not separate coordinate copies. |
| Internal fixed-point formats, mass/inertia floors, inverse scales, rounding/saturation, geometry kernels and solver bounds | Doyeon; Choon Hsiang reviews output geometry and Qi-Ze reviews result/control behavior | Story 3 numerical contract, then Stories 4/5 and dependent integration. External geometry remains signed 18-bit Q6. |
| Framebank packing/ports, clear/raster schedule, BRAM budget, frame-local overlays and safe transfer/release protocol | Choon Hsiang; Doyeon reviews world geometry, Qi-Ze reviews UI/world joins | Story 2 implementation plan and presentation integration. |
| CDC/reset disposition, PS/2 checks, reproducible source bytes and physical peripheral details | Choon Hsiang leads; Qi-Ze owns mouse behavior checks; Doyeon reviews contract effects | Relevant Story 1/G-2 acceptance and board integration. |

Publish each decision in its canonical spec companion/header and link it from the affected story plan. Keep architecture AD-1 through AD-12 and existing geometry/physics parameter revisions binding. A proposed change to a shared field, unit, reset rule or parameter must identify affected consumers, obtain their owners' review and update them together before integration. Do not privately invent replacement defaults.

## File ownership and integration

These are write-coordination assignments; they do not transfer authoritative state between subsystems. Proposed new directories below are conventions for future work, not modules already implemented.

| Files/area | Primary owner | Coordination rule |
| --- | --- | --- |
| Future `rtl/input/`, `rtl/control/`, `rtl/levels/`; `rtl/platform/q_mouse_adapter.v`; LED behavior | Qi-Ze | Coordinate geometry/length changes with Doyeon and visible layout with Choon Hsiang. Controller alone owns mode and allowance. |
| Future `rtl/physics/` and numerical kernels | Doyeon | Physics alone owns accepted bodies, world revisions, admission and winning-contact events. |
| Future `rtl/graphics/`, `rtl/status/`; existing VGA/OLED adapters and `q_clock_reset.v` | Choon Hsiang | Graphics consumes complete snapshots; status consumes controller records. Preserve domain/reset and framebank ownership rules. |
| Existing four `rtl/include/` headers and new shared definitions | Qi-Ze coordinates edits; Doyeon owns numerical meaning; Choon Hsiang owns visual layout meaning | One coordinated change at a time. Both affected producer and consumer owners review interface changes. |
| `rtl/q_top.v` | Choon Hsiang maintains physical top; Qi-Ze coordinates Story 7 integration | Subsystem developers provide port/wiring changes to the top maintainer. Agree one editor for each integration change. |
| `scripts/vivado/`, `hardware/`, `.gitignore` | Choon Hsiang | Record build, pin and clock changes; rerun appropriate reports. JB is selected but wiring still needs confirmation. |
| `third_party/` | Choon Hsiang coordinates provenance | Preserve imported sources/notices; resolve the line-ending/hash policy explicitly. |
| Each detailed story document | Its named story lead | Record prerequisites, review findings, actual evidence and remaining limitations. |
| Shared planning records and milestone progress | Qi-Ze coordinates; relevant owner supplies evidence | Distinguish authored, reviewed, synthesized, integrated and board-validated states. |

Qi-Ze is the merge/integration coordinator. Choon Hsiang is the Vivado build coordinator. Doyeon owns physics readiness and numerical acceptance. No developer should overwrite another developer's unmerged work or amend the shared contract without coordination.

## Branches, reviews and handoffs

1. Each developer pulls the common baseline and uses a separate branch/checkout. Suggested first branches are `codex/story-6-input`, `codex/story-3-physics` and `codex/story-2-rendering`; platform follow-up uses a separate small change. These branches are not created by this document.
2. Select the assigned story explicitly. The canonical [stories.yaml](../_bmad-output/specs/spec-q-remastered-on-fpga/stories.yaml) retains its sequential order and checkpoints; do not run three automatic “next story” dispatchers against the same checkout. This plan permits coordinated story selection without rewriting dispatcher semantics.
3. Before coding, the lead writes the detailed plan and obtains the named review. Resolve prerequisites or identify the isolated portion that can proceed. Preserve each story's spec and done checkpoints.
4. Keep changes scoped to the owned subsystem. Shared definitions and top-level wiring are coordinated changes with their maintainers. Merge approved shared prerequisites before dependent consumers.
5. Each handoff provides a commit/branch, changed modules, interface revision, configuration/memory inputs, actual verification results, resource/timing results where applicable, known limitations and the reviewer outcome. Controlled-input evidence must not be represented as integrated board evidence.
6. After completion review, Qi-Ze coordinates merging and Choon Hsiang runs the appropriate integrated build checks. Contributors pull the merged baseline before the next integration change. Fix build/interface regressions before layering more integration onto them.

Review substantive updates at each handoff or dependency change. Record the current milestone, each developer's next deliverable, blockers and required cross-owner decisions; calendar meeting frequency can be agreed once the course dates and team availability are known.

## Integration acceptance checks

Before accepting the Story 7 join, check these cross-subsystem behaviors against [module-contracts.md](../_bmad-output/specs/spec-q-remastered-on-fpga/module-contracts.md):

- Producer payloads remain stable while valid is stalled; receipt and terminal completion remain distinct. No duplicate admission result causes a second body or allowance debit.
- The displayed stroke preview and submitted sampled geometry agree; rejection creates no body, impulse or charge. Draw release never activates pause, and held-left pause requests are not queued.
- Pause/control traffic is not blocked by admission arithmetic. Reset/new attempts drain or reject stale commands, responses and frames without charging the new attempt.
- Physics publishes complete world snapshots. Renderer joins the matching world/UI revisions, writes only a free back bank and waits for safe release; the magenta ball uses frame-local metadata.
- Left-boundary contact survives correction and produces a reliable goal event. Controller chooses Victory; graphics and status display coherent records.
- Domain startup and recovery are reviewed, timing/DRC evidence is current, and remaining CDC findings are resolved or explicitly justified with supporting evidence before the relevant acceptance gate closes.

These are planned acceptance obligations, not checks performed by writing this plan. This document does not add or run simulation tests or dispatch implementation work.

## Immediate actions

Detailed first-track drafts are prepared on 2026-10-17. Their existence does not complete M0: owner decisions and the named before-coding reviews remain pending.

A [technical readiness review](reviews/parallel-readiness-review.md) corrected three draft gaps and records the remaining implementation prerequisites. The [core wiring proposal](../_bmad-output/specs/spec-q-remastered-on-fpga/core-wiring-proposal.md) now specifies the controller/input/presentation map, retained acknowledgement relay and cancellation/retirement paths for review. It does not substitute for the named developers' sign-offs.

The [numerical design proposal](../_bmad-output/specs/spec-q-remastered-on-fpga/numerical-design-proposal.md) now specifies the shared length rule and internal numerical choices for owner review. Its new tuning constants and cycle targets remain proposals; the published headers and accepted external geometry are unchanged.

The [capture/UI design proposal](../_bmad-output/specs/spec-q-remastered-on-fpga/input-ui-design-proposal.md) now specifies the simplifier, gesture policy and shared visual geometry for owner review. Its provisional-short-preview clarification needs explicit reconciliation with the common contract; final admission still enforces the adopted 16-pixel minimum.

The [renderer design proposal](../_bmad-output/specs/spec-q-remastered-on-fpga/renderer-design-proposal.md) completes R4's concrete memory, scanline, pipeline and mailbox choices. Use the [parallel start checklist](parallel-start-checklist.md) for the approval package, reference-check command, first build scopes and remaining hardware tickets. Proposed budgets remain unmeasured; human before-coding approval is still pending.

| Draft | Lead | Before-coding reviewer | Outstanding cross-owner agreement |
| --- | --- | --- | --- |
| [Story 2 — buffered VGA scenes](../_bmad-output/specs/spec-q-remastered-on-fpga/stories/2-render-coherent-buffered-vga-scenes.md) | Chua Choon Hsiang | Kim Doyeon | G-5 memory/schedule/CDC choices; Qi-Ze's UI/world join and common layout. |
| [Story 3 — arithmetic and motion](../_bmad-output/specs/spec-q-remastered-on-fpga/stories/3-implement-bounded-rigid-body-arithmetic-and-motion.md) | Kim Doyeon | Chua Choon Hsiang | G-3 numerical choices; Qi-Ze's agreement on shared length rounding. |
| [Story 6 — gestures and preview](../_bmad-output/specs/spec-q-remastered-on-fpga/stories/6-capture-mouse-gestures-and-the-visible-stroke-preview.md) | Han Qi-Ze | Chua Choon Hsiang | G-4 sampling/simplification and common UI layout; Doyeon's shared length rule. |

- Qi-Ze confirms course dates, coordinates M0 and completes Story 6's owner decisions.
- Doyeon completes Story 3's numerical design and publishes the numerical/length decisions needed by the other tracks.
- Choon Hsiang completes Story 2's G-5 design, owns the remaining Story 1 CDC/board checklist and agrees shared UI geometry with Qi-Ze.
- The assigned reviewers review those three drafts as the owner decisions are filled in. Once the relevant prerequisites and reviews pass, begin the independent portions and join them at M2 under Story 7.
