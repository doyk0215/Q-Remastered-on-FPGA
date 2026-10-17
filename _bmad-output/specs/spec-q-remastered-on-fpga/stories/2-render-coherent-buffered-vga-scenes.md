---
title: Render coherent buffered VGA scenes
type: feature
created: 2026-10-17
status: ready-for-dev
approved: 2026-10-17
approval_authority: user
approval_scope: before-coding checkpoint and isolated implementation; completion evidence pending
baseline_commit: d96adc2aa72763f5fd27b2cb1988e00c16f5dc79
lead: Chua Choon Hsiang
reviewer: Kim Doyeon
review_loop_iteration: 0
context:
  - '../SPEC.md'
  - '../module-contracts.md'
  - '../geometry-profile.md'
  - '../prototype-gates.md'
---

## Intent and scope

Approval update: the user adopted the planning package on 2026-10-17 and explicitly satisfied this story's before-coding checkpoint. Earlier pending-review descriptions below record draft preparation, not a claimed teammate approval. The approved design package is linked from the parallel start checklist. Implementation/completion and hardware gates remain open.

Implement CAP-11's bounded world rendering and coherent frame presentation under G-5. Consume complete transformed geometry and matching UI state; publish only completed frames through the revision 2 frame/epoch protocol. This story owns rendering, scanout, frame transfer and frame-local ball composition. It does not own physics, game state, stroke admission, OLED status or final stage solutions.

Lead: Chua Choon Hsiang. Reviewer: Kim Doyeon. Han Qi-Ze contributes UI/world barrier and presented-view requirements. Status is draft: no before-coding review or implementation acceptance is claimed.

## Prerequisites and decisions

| Item | Required action before dependent work |
| --- | --- |
| Common declarations | Use `q_contract.vh`/`q_ports.vh` revision 2 and the current geometry/physics headers. Preserve signed Q6 extraction and exact mailbox roles. |
| Story 1/G-2 | Build from the verified foundation; coordinate outstanding reset/CDC findings before actual peripheral/scanout integration. Isolated renderer work can use controlled clocks and records. |
| G-5 memory/schedule | Choon Hsiang publishes bank packing/ports, BRAM allocation, clearing/rasterization bounds, circle arithmetic, read latency and safe-release timing before finalizing dependent RTL tasks. Two one-bit banks remain the adopted seed; measure allocation overhead and budget other subsystem storage. |
| G-4 visual definitions | Choon Hsiang and Qi-Ze agree shared font/hit-region/layout definitions, layer order and cursor/preview distinction. World rasterization may proceed independently; dependent UI layers wait for the common definitions. |
| World records | Doyeon reviews complete-world packing and transformed geometry. The renderer must not require access to private physics state or internal numerical formats. |

Planning choices still to record: exact module decomposition, memory primitive/configuration, subpixel coverage and rounding, latency through RGB/sync/enable, mailbox capture timing/synchronizer stages, and worst-case frame workload. These are owner deliverables, not values selected by this draft.

The [core wiring proposal](../core-wiring-proposal.md) now specifies the frame acknowledgement relay, capacity reservation, controller/input context and epoch ownership for owner review. Adopt/reconcile that proposal before separately implementing the shared boundary; its named approvals and RTL are still pending.

The [capture/UI proposal](../input-ui-design-proposal.md) supplies common half-open control rectangles, font-cell/scaling choices, cursor/stippled-preview primitives and proposed OLED layout for owner review. Adopt one shared definition with Qi-Ze before dependent rendering/hit-testing code; verify its short-provisional-preview clarification against the common contract. These selections do not establish G-5's bank packing, raster cycle or CDC evidence.

The [renderer proposal](../renderer-design-proposal.md) now specifies 32-useful-bit/36-bit-word banks, ten RAMB36-equivalent blocks per bank, exact scanline disk/strip intervals with incremental signed edge division, a three-cycle token pipeline and concrete mailbox capture/release timing. Its radius-eight worst-case arithmetic target is 1632480 core cycles, not a measured frame rate. Thicker obstacles, actual operator latency and aggregate resources must be evaluated before throughput claims. Owner review/adoption is pending.

## Code and interface boundaries

- Own new graphics implementation under proposed `rtl/graphics/`; final filenames belong in the reviewed implementation plan.
- Reuse `rtl/platform/q_vga_timing.v` and pinned Project F timing. Coordinate any adapter/clock/XDC changes through the platform owner.
- Consume WORLD/UI records at 100 MHz. Frame and epoch mailboxes cross to 25.2 MHz scanout; do not substitute same-clock ready/valid or bitwise payload synchronization.
- Qi-Ze's controller/integration logic owns the desired attempt/epoch and the source-side pending epoch policy. Choon Hsiang implements the display-side transport/commit and coordinates its source wrapper with Qi-Ze; graphics does not independently allocate attempts.
- Before coding the integration boundary, publish the core-domain route for actual-presentation acknowledgements to controller/input. FrameAck already contains the required identities, but its mailbox return must be captured once and retained/distributed without two consumers independently retiring the same transaction. The route must carry dropped dispositions too, while only PRESENTED updates the presented identity or starts feedback lifetime.
- Keep top-level wiring changes coordinated with Qi-Ze's Story 7 join. Shared header/layout changes require affected owners' review.

## Tasks

- [ ] Publish the G-5 implementation choices and resource/cycle budget; obtain Doyeon's before-coding review and Qi-Ze's UI-join agreement.
- [ ] Implement two one-bit banks with explicit writer/front-bank ownership, bounded clear and capsule rasterization, clipping and count limits. Exclude the moving ball from the white image mask.
- [ ] Capture one complete world and a compatible UI state for each frame: same attempt and world revision at least the UI's required revision. Preserve a retained complete world for paused/lobby/UI-only refreshes.
- [ ] Assemble FramePacket with the exact bank's ball geometry, visibility, world identity and UI metadata. Hold exposed/stalled records stable; do not overwrite a live mailbox.
- [ ] Implement the four-phase held-data frame and epoch transfers with reviewed CDC/reset constraints. Give epoch application priority at a safe frame boundary and drain stale submissions with the defined dispositions.
- [ ] After the desired epoch has been acknowledged and its handshake is fully idle, permit the new attempt's completed frame to be published. Coalesce desired epochs only in the controller/integration source's pending slot, never by overwriting the live mailbox.
- [ ] Implement scanout read/pixel/sync alignment, frame-local magenta circle and agreed overlays. Remain black until the first valid frame of the current attempt.
- [ ] Acknowledge actual presentation identities and release the old front bank only after read-pipeline retirement. Reclaim a dropped submission only once its entire handshake is idle.
- [ ] Collect relevant behavioral, synthesis/resource and timing evidence; obtain completion review and hand off to Story 7.

## Acceptance matrix

| Condition | Required evidence |
| --- | --- |
| Startup; no complete frame | Front bank 0 starts invalid, renderer owns bank 1, req/ack start idle and output stays black. |
| Rendering takes longer than a scanout frame | Repeat the prior complete image; no partially drawn frame or front-bank write is visible. |
| Physics updates while a frame is retained | Bank geometry and magenta ball remain from the same snapshot; no white ball halo or live-coordinate overlay. |
| Independent UI/world revisions | Join same-attempt records using the required-world barrier, not equality between unrelated counters. |
| Admission result, pause or goal changes UI | No new allowance/cleared preview on a pre-admission world. Frozen-world UI refresh does not require advancing physics. |
| Epoch change during a pending frame | Apply epoch safely, blank old-attempt content, acknowledge stale frames without releasing the displayed front bank incorrectly. |
| New-attempt frame races epoch acknowledgement | Hold the new attempt's publication until its desired epoch handshake is acknowledged and idle. |
| Presented/dropped acknowledgement reaches the core | Retire the mailbox once; controller/input receive retained identity/disposition without losing renderer bank-release accounting. Only PRESENTED starts feedback lifetime or advances presented view. |
| Backpressure and delayed acknowledgements | Frame payload/ack metadata stay stable through the full four-phase handshake; no early memory reuse or lost identity. |
| Maximum supported geometry | Bounded rendering/clearing completes within the documented schedule; actual BRAM utilization includes packing and allocation overhead. |
| Pixel pipeline | 640×480 active pixels, 800×525 timing, negative 96-pixel/2-line sync and RGB alignment agree with the timing contract. |

## Handoff and review

Provide module/port map, shared-definition revisions, memory initialization/configuration inputs, measured frame cycle bounds, resource/timing reports, actual CDC disposition, behavioral evidence, known limitations and a reproducible build command. Story 7 receives completed-frame presentation and safe ownership transfer, not private renderer state.

Technical draft review on 2026-10-17 clarified epoch-source ownership, the new-frame/epoch-idle barrier and the core presentation-acknowledgement handoff. See the [readiness review](../../../../docs/reviews/parallel-readiness-review.md). This is a Codex document review; Kim Doyeon's named review remains pending.

Before-coding review: pending Kim Doyeon; UI/epoch coordination: pending Han Qi-Ze. Completion review: pending. No RTL, simulation tests or board checks were performed by creating this draft. G-5 and Story 1's pending gates remain open. Exact deadline is unconfirmed; use M0–M2 in the [parallel development plan](../../../../docs/parallel-development-plan.md).
