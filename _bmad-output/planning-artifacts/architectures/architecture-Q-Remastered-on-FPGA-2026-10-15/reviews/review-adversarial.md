# Adversarial independent-builder review

Date: 2026-10-16  
Scope: `../ARCHITECTURE-SPINE.md`, reviewed as a build substrate for independently implemented input, controller, physics, presentation, scanout and status modules. Document reasoning only; no code tests or hardware validation.

## Verdict

**Pass, subject to the already recorded pause-gesture clarification and mandatory shared-definition gates.** The state ownership, exact-once admission intent, goal precedence, coherent frame publication and double-bank ownership rules are sound. Many apparent incompatibilities require violating an explicit rule or starting independent RTL before the common contract is published; those are not new architecture defects.

The two semantic concerns raised during this review—association/refresh of world/UI records and feedback-specific presentation confirmation—were addressed in the spine and re-read from the current source. Their original counterexamples and confirmed dispositions are retained below. The already acknowledged pause request during left-button drawing remains a user clarification blocker; this review does not choose its gesture.

The current version includes actually displayed attempt/view identity for input targeting, separate world/UI revisions joined by a required-world barrier, retained-world reuse for UI-only refresh, and presented frame/UI/feedback identities for feedback lifetime. These close the identified presentation counterexamples without changing the view identity on every moving-world snapshot.

## Findings

### F1 — Define the world/UI join and UI-only revision owner

**Classification: genuine semantic concern, now addressed in the reviewed spine.**  
**Relevant rules:** AD-1, AD-4, AD-9; Logical Interface Contract physics/controller → presentation rows; Input and presentation conventions.

**Independent pair:** Physics publishes complete snapshots to presentation with world identity `W`. Controller publishes UI records associated with `W`. Renderer A only starts a draw when it receives a new world snapshot and an exact matching UI record, which preserves coherence. Controller B changes pause-menu state, cursor, feedback or pending preview while the physics world is unchanged, continues associating those UI records with the retained `W`, and expects presentation to redraw it. Each obeys the specified association and immutable-record rules, yet the menu/cursor/feedback update may never be drawn while paused. A renderer that instead requires a new world identity for every UI update can deadlock with a physics module that correctly stops advancing and stops publishing new world records in Paused/Victory.

The table also does not identify how the controller learns the identity of ordinary physics snapshots: physics → controller lists result/goal identities, while all routine world snapshots go directly to presentation. Independent builders could wait on information available only to another module. A create result and a post-admission world snapshot can arrive through different channels; an ID association alone must not allow a body-present image paired with pre-acceptance allowance or the submitted preview painted again.

**Required contract:** Name the presentation assembly owner and how it receives/assigns world association. Distinguish world snapshot identity, presentation revision/frame identity, and displayed view identity. State that a complete retained world snapshot can be reused for UI-only frames while paused or otherwise unchanged, and define what causes those frames to be scheduled. Define the causal join for accepted/rejected admission, allowance, preview clearing and winning scene/menu state. Do not require physics advancement merely to show new cursor/menu/feedback data.

This does not mandate a particular queue depth or wire packing. Those remain AD-12 deliverables; the observable ability to refresh a coherent view while the world is static is the semantic requirement.

**Confirmed resolution:** The current interface includes committed world revision on state-changing completions/goal, controller UI revision and required-world barrier, and renderer ownership of coherent assembly. The conventions separate world/UI counters, require a same-attempt complete world at or beyond the barrier, select/release snapshots atomically, allow retained-world/background reuse in Paused/Victory/Lobby, and prohibit post-admission UI with a pre-admission world. Combined with the existing ban on drawing a superseded preview over an admitted body, this closes the counterexample. Exact fields, counter wrap and queue/backpressure scheduling remain the common-definition gate.

### F2 — Confirm feedback by frame/feedback identity, rather than view identity alone

**Classification: genuine observable feedback concern, now addressed in the reviewed spine.**  
**Relevant rules:** AD-9; renderer → scanout acknowledgement; conventions requiring at least one presented frame carrying feedback and scanout reporting displayed view identity.

**Independent pair:** Scanout A reports the actual attempt and view identity at swaps, as required. Controller B owns message lifetime and receives a report for the current view, so it considers pending feedback displayed and starts its one-second visible timer. The acknowledged frame can have been rendered just before the feedback trigger, because ordinary feedback does not necessarily change mode/layout view identity. Both modules can obey the stated view-ID reporting contract; the feedback-specific visibility guarantee still cannot be established. A controller that instead waits for proof can retain feedback forever because no feedback-specific proof is defined.

**Required contract:** Carry a feedback sequence/identity or an unambiguous frame-to-feedback association in the complete frame metadata. Return an actual-presented event that allows the controller to identify that frame/message; a bank metadata receipt or an old-frame release acknowledgement is insufficient. Start the visible-duration policy from that confirmation, subject to reset/stage cancellation. Repeated display of a frame must not retrigger the feedback event or extend its lifetime unintentionally. The current attempt/view report is still useful for input targeting and can share a transport with this event.

This is a semantic path/identity requirement; counter widths, FIFO layout and ready/valid signals belong to AD-12.

**Confirmed resolution:** The current Scanout → controller interface reports presented attempt, view, frame, UI revision and feedback identities, explicitly at actual visible presentation rather than receipt or rendering completion. The convention uses frame/feedback identities to start/clear the matching lifetime even when view identity is unchanged. This closes the counterexample; presentation event delivery/deduplication and finite-ID retirement remain AD-12 details.

### F3 — Specify reset/cancel/event draining as an ordered transaction in the common definition

**Classification: mandatory existing AD-12 gate, not an additional finalization blocker.**  
**Relevant rules:** AD-4/5/6/9/10/12.

**Independent pair:** Physics A retains an old-attempt accepted result or goal until acknowledgement and waits for that event to drain before completing reset. Controller B advances generation, considers the old attempt invalid, sends reset, and waits for reset completion before accepting further old results. Each has a plausible implementation of invalidation plus safe draining, but the dependency cycle can prevent completion unless “drain” explicitly includes consuming/acknowledging stale reliable events during reset. Dropping old semantic effects does not authorize dropping their transport acknowledgements.

The spine already requires a common definition covering reset/cancellation before parallel interface implementation, acknowledgement of reliable events, and no stale ID reuse. The shared definition must settle transaction priority, event acknowledgement while reset is pending, create receipt versus create completion, how reset acknowledgement establishes a new world, and the treatment of a simultaneous reset/load and old goal. Goal explicitly outranks pending pause/uncommitted stroke; its ordering against reset/leave is not selected in the spine and should be selected once in the common cancellation contract.

For finite IDs, specify which channels must be empty and which bank/frame references must retire before reuse. Use an agreed drain order rather than independently resetting local counters or handshake toggles. Preserve AD-10's distinction between logical stage reset and physical peripheral/startup reset. These items are within the existing gate; a designer who independently chooses them before the shared result is published does not satisfy that gate.

### F4 — Define handshake receipt, replay policy and same-boundary command arbitration once

**Classification: mandatory existing AD-12 gate; the invariant is already stated.**  
**Relevant rules:** AD-4/5/6/8/12; create `pause_after`; separate late pause convention.

**Independent pair:** Controller A holds `valid` until `ready` and then expects one durable matching result. Physics B regards repeated asserted `valid` as repeated receipt unless its common handshake has defined the acceptance edge/cycle. Or a controller introduces timeout retransmission while physics provides no duplicate replay. The resulting duplicate admission violates AD-4's exact-once rule; it is not a compliant alternate interpretation once the common ready/valid contract exists. The shared contract must define a receipt event, one outstanding request across receipt-to-result completion, stable payload lifetime, ID lifetime and whether retransmission is unsupported or idempotent.

At an admission boundary, a controller may issue a late pause separately rather than mutating an in-flight create. The shared command protocol needs a definite acceptance/arbitration point so physics can apply a pending pause before its next advancement. This includes commands arriving in the same core cycle as create completion, outer-update enable or a goal. A goal that has latched must win; acknowledging goal must not resume the stopped world. The pending pause gesture itself remains the known user clarification and must not be invented here.

No new timeout/retry feature is implied by this finding. A held-data request/acknowledgement protocol without timeout retransmission can satisfy the spine.

## Decision-by-decision attack matrix

The pairs below were tested against the written rules conceptually. “Ruled out” means the proposed incompatibility would violate a current invariant. “Gate” means the spine already forbids independent choices until a shared contract is published.

| Decision | Independent-builder attack | Assessment |
| --- | --- | --- |
| AD-1: ownership | Graphics updates a stroke pose to smooth it while physics retains the authoritative pose. | Ruled out: graphics must consume immutable presentation data and cannot mutate gameplay. The separate join responsibility raised in F1 is now explicitly resolved. |
| AD-2: limits | Levels counts the four walls among eight obstacles while physics reserves eight obstacles plus walls; renderer assumes a target body. | Ruled out: walls are separate and the full left boundary is the goal; no target body exists. Packing/count widths remain shared-definition details. |
| AD-3: coordinates | Input sends integer mouse positions as raw Q6 words; physics interprets them as pixels/64, or velocity uses pixels per substep. | Ruled out: shared storage/units are explicit. Port packing, exact coefficient formats and numerical parameters remain named gates. |
| AD-4: admission | Input starts another stroke after request receipt while controller still awaits the result; preview clears at receipt and renderer draws it again over the accepted body. | Ruled out by the pending-preview convention and one-creation-pending rule. Transaction receipt/result handshake and causal frame association require F1/F4. |
| AD-5: modes/reset | Controller rejects effects of old-generation events; physics waits for acknowledgement before releasing them, while reset waits for both. | F3: common cancellation/drain ordering is mandatory. Stale events may be semantically ignored but still acknowledged. Pause-during-drag remains a known unresolved gesture. |
| AD-6: goal | Physics clears a goal because visual snapshots were superseded; renderer synthesizes Victory from a decorative goal strip. | Ruled out: goal is latched reliable state separate from visual snapshots, uses the physical boundary, and retains winning snapshot. Simultaneous goal versus reset policy belongs in F3. |
| AD-7: transforms | Renderer independently rounds/rotates local points while collisions use physics-transformed points. | Ruled out: renderer and collision detection consume the same transformed points. Different internal contact math remains a physics-owned prototype gate, not a second transform authority. |
| AD-8: scheduling | Controller queues update ticks while physics is busy, then physics increases timestep or overlaps updates to catch up. | Ruled out. The exact bounded schedule, deadline policy details and kernel costs require the published integration/physics result; no fit is claimed. |
| AD-9: frames | Scanout acknowledges metadata receipt and rasterizer immediately overwrites the old front bank; cursor overlays use a newer live position than the bank's frame. | Ruled out: safe bank release and frame-local aligned overlays are explicit. F1/F2's separate refresh/association and feedback-evidence counterexamples are now addressed. |
| AD-10: CDC/reset | Stage reset resets only the source handshake toggle while pixel scanout continues using the old bank. | Ruled out: logical stage reset is distinct and handshakes/bank ownership initialize coherently. Actual cancellation/reset state machine and read-pipeline drain latency are gates. |
| AD-11: drivers | OLED producer uses a convenient posedge interface; adapter assumes the source's negedge update/sample contract, or cursor bounds remain driver defaults. | Ruled out: preserve actual setup/sample contract and explicitly initialize 639/479 bounds. Exact adapter phase/latency is a required peripheral integration deliverable. |
| AD-12: common contract | Each developer picks enum encodings, ID widths, retry rules or bank acknowledgement meanings independently. | Ruled out as a development process: publish and consume one shared definition before independent interface implementation. This gate must include the operational semantics described by F3/F4, not only constants. |

## Frame and overlay ownership stress cases

- **Completed bank becomes stale before swap:** invalidate its generation, drain the held-data handshake and return bank ownership through the agreed release protocol. Do not clear a source toggle or reclaim a bank solely because the controller changed attempt. Already governed by AD-5/9/10/12; exact control sequence is gated.
- **Goal while rasterizer is busy:** retain winning world independently of droppable ordinary snapshots, cancel/supersede obsolete presentation work safely, and eventually assemble the matching Victory frame. AD-6/9 supplies the invariant; F1's resolved revision barrier supplies the causal join.
- **Paused world plus cursor/menu/feedback changes:** coherent UI revisions are explicitly renderable from retained geometry without a physics tick. F1 addressed.
- **Old frame has same view ID as new feedback:** actual presented frame/UI/feedback identities supply message visibility independently of the view identity. F2 addressed.
- **Read pipeline crosses swap:** acknowledgement cannot authorize overwriting a bank until every read referencing it has retired. AD-9 explicitly requires this. Address/RGB/sync/mask pipeline delays must be published together; a live overlay with unrelated timing is not a compliant implementation.
- **OLED updates before VGA:** permitted at different instants if each latches its own coherent record. Do not mistake the lack of simultaneous peripheral frame boundaries for field tearing within a record.
- **First image after startup:** scanout remains black until a valid completed image. Initial bank ownership and clock-valid synchronized reset release are explicit; black screen need not imply the world has begun advancing.

## Required disposition

F1 and F2 are addressed in the current source. Before independent RTL, complete the existing common-definition gate with F3/F4's transaction state and arbitration details, including cancellation, stale-event draining, finite-ID retirement, command acceptance and bank release. Retain the current hardware/profiling gates and avoid treating them as missing measured proof in this document review.

Architecture finalization still requires the separately pending user answer about requesting pause during left-button drawing. No mouse mapping is selected by this review. No edits to the spine or UX were made.
