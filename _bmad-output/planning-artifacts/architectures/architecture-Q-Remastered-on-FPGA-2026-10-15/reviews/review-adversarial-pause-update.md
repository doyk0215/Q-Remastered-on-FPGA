# Adversarial pause-update review

Date: 2026-10-16  
Scope: Current architecture AD-5, logical interface table and input/presentation conventions, with DESIGN pause availability and supporting current PRD/EXPERIENCE wording. Source review only; no code tests, rendering, synthesis or hardware validation. No architecture, PRD or UX source edits.

## Verdict

**Pass.** The user-selected behavior is now explicit and consistent across the targeted sources. Pause is unavailable while the left button is held; requests from a drawing gesture are ignored and never queued. A draw release submits admission only, including when its endpoint is over the pause icon. A separate UI click begins over the pause control and activates on release. The create interface no longer contains `pause_after`; physics receives pause as a separate valid UI command. No alternative button shortcut is assigned.

No pair of modules can obey all these current semantic rules while interpreting a draw release as a pause request or treating one UI click as both drawing and UI activation. Such behavior would violate AD-5 and the gesture-consumption convention directly. The existing common interface/layout gate still needs concrete event encoding, acceptance timing and hit geometry before independent RTL. Those implementation choices do not reopen the selected behavior.

This review supersedes the pending pause-gesture blocker recorded in `review-adversarial.md`: that user decision is resolved in the current source.

## Findings

### 1. Pause-on-release and queued-drag pause are explicitly excluded

**Status: resolved; no remaining semantic blocker.**

Architecture AD-5 states all of the following together: no pause while held, ignore rather than queue requests during drawing, release only submits the stroke even over the icon, require a fresh pause-icon click after release, and prohibit a draw gesture becoming a pause click. The input convention also excludes an alternate-button shortcut and queued drag pause. PRD FR-2/FR-5 and EXPERIENCE component/state/pattern descriptions agree.

**Attempted incompatible pair:** Input sees the release endpoint over the pause hit region and emits a pause click; controller accepts it and freezes after admission. This is not a compliant alternate implementation: it violates the explicit gesture-origin and draw-release rules. Likewise, physics cannot autonomously freeze at every create result, because the create record contains no pause flag and admission completion alone is not a pause command.

### 2. Press-time gesture ownership prevents UI/draw double action

**Status: explicit invariant; preserve in the existing shared-definition gate.**

The first press selects UI or draw using controller mode and the shared hit regions. The whole UI gesture is consumed. A fresh pause press may arm a UI gesture while held, but activation waits until release; the phrase “disabled while held” cannot be implemented as discarding the arm and reclassifying that same gesture as a draw. AD-5 explicitly defines the fresh UI click's press/release lifecycle.

**Attempted incompatible pair:** Input starts a preview on every left press while controller separately recognizes the same press as pause/menu UI. Emitting a create at that release would violate the first-press classification and UI-consumption invariant. Similarly, an old-view UI action rejected by the controller must remain a consumed UI gesture rather than falling through into drawing.

The common definition should encode or otherwise unambiguously retain gesture ownership through release, including simultaneous release/click event delivery, stale-view rejection, zero allowance and an outstanding admission. Exact hit boxes and any release-outside-control cancellation policy belong to the shared UI definition. None of those choices permits a draw-origin gesture to activate pause or a UI-origin gesture to create a stroke.

### 3. A valid separate click during admission has one atomic outcome

**Status: aligned; existing handshake/arbitration gate remains.**

The “no second stroke while creation is pending” convention limits drawing; it does not prohibit a fresh pause UI click. The input/controller path can therefore accept that separate click while the immutable create is already in flight. AD-5 requires finishing its atomic acceptance/rejection, then freezing before another world advancement. The interface table says pause is separate from create, and the pending-pause convention requires physics to check it before subsequent advancement. Admission still produces exactly one reliable result and allowance changes only upon acceptance.

**Attempted incompatible pair:** Controller changes the submitted create payload to include pause, or physics treats receipt of pause as permission to abandon partially completed admission. Both violate the immutable-request/atomic-result rules. Physics continuing with another update after recognizing a valid pending pause also violates the explicit boundary rule. A latched goal still wins over valid pending pause and uncommitted stroke, so pause cannot reopen or advance the winning world.

The shared command protocol must retain its existing acceptance/ready-valid and same-boundary arbitration definition. A valid pause may wait for an already started atomic operation; it must not be confused with prohibited queuing of an attempted pause during drawing. The distinction is the originating fresh UI gesture after drawing release.

### 4. Disabled pause styling fits one-bit banks plus magenta overlays

**Status: compatible; exact appearance remains the shared graphics/layout gate.**

DESIGN's Layout & Spacing now requires the two-bar control's unavailable/pressed state to be clear while held and explicitly excludes drawing-release activation. Its palette remains black, white and magenta, and its accessibility rules require cues beyond color. A changed black/white outline, pattern, icon marking or similarly bounded shape treatment can express that state while magenta remains an accent. These are feasibility examples, not newly selected styling.

The requirement needs no grayscale, transparency, full-color framebuffer or second arbitrary-color mask. The architecture's one-bit black/white image banks, bounded procedural magenta accents, composition priority and shared hit/layout definition remain suitable. A visual state change must use coherent UI revisions and frame-local overlay metadata; a control changing appearance does not change the gesture already captured on press. DISPLAY latency therefore cannot reinterpret a draw release as a fresh click.

## Independent-builder scenario matrix

| Scenario | Required common outcome | Why contrary behavior is excluded |
| --- | --- | --- |
| Draw begins in playfield, crosses pause, remains held | Continue the same draw; no pause event or queued intent | Pause disabled while held and gesture origin retained. |
| Draw releases over pause | One stroke admission request; no pause | AD-5 explicitly excludes release-over-icon pause. |
| Drag-time pause attempt followed by release elsewhere | Admission only; no delayed pause | Requests during drawing are ignored, never queued. |
| Separate press over pause after the drawing release, then release | UI activation requests pause; no new stroke | Fresh UI click arms on press, activates on release and consumes its gesture. |
| Separate pause click while prior admission is still pending | Resolve that create atomically, then freeze before further world advancement | AD-5 plus separate immutable command contract; no second stroke starts. |
| Prior admission rejects and a separate valid pause is pending | Preserve allowance, clear preview, deliver rejection, then pause | Admission outcome does not cancel the valid separate pause. |
| Prior admission accepts and a separate valid pause is pending | Insert/charge exactly once, clear pending preview, then pause | Atomic result and matching committed-world/UI association remain binding. |
| No separate click follows a draw release | Continue active simulation after admission | Admission contains no pause request and does not imply one. |
| Right/other button during draw | No assigned pause shortcut | Input conventions explicitly exclude an alternative button mapping. |
| UI press begins over pause, pointer subsequently leaves it | Gesture remains UI-owned; release activation/cancellation uses the one shared UI policy | It cannot become a stroke regardless of the eventual cancellation choice. |
| Pause/menu UI action carries stale displayed view identity | Reject action; do not draw instead | Displayed-view rejection plus consumed UI gesture. |
| Goal latches while a valid separate pause is pending | Retain winning world and enter Victory | Goal takes precedence over valid pause and uncommitted stroke. |
| Button remains held during a mode/attempt transition | Do not synthesize a fresh press or reuse the release as a new UI click | Fresh-click/gesture-origin and old-view/attempt guards apply; concrete cancellation encoding is shared. |

## Sources checked

- `../ARCHITECTURE-SPINE.md`: AD-4/5/6, logical interface records, Input and presentation conventions, shared-definition and graphics gates.
- `../../../ux-designs/ux-q-remastered-on-fpga-2026-10-15/DESIGN.md`: Colors, Layout & Spacing pause availability, Shapes and Do's and Don'ts.
- `../../../ux-designs/ux-q-remastered-on-fpga-2026-10-15/EXPERIENCE.md`: Pause control, Drawing in progress, Pause interaction pattern and pause recovery flow.
- `../../../prds/prd-Q-Remastered-on-FPGA-2026-10-15/prd.md`: FR-2 and FR-5.
- `../../../prds/prd-Q-Remastered-on-FPGA-2026-10-15/addendum.md`: updated pause/admission direction. Its general “immediately pauses” shorthand is bounded by the explicit current safe-atomic-boundary rules; it does not authorize press-time or drawing-release activation.

## Disposition

The targeted finalization blocker is closed. Carry gesture ownership, release activation, stale-view consumption, immutable separate pause commands and admission-boundary arbitration into the existing shared interface/UI definition. Keep disabled-state visuals within the agreed palette and non-color cue requirement. No additional user decision is required by this review.
