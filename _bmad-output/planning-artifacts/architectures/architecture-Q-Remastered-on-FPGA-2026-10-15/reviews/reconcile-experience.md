# Experience reconciliation

**Verdict: Conditional pass.** The architecture preserves the principal navigation, physics interaction, stroke allowance, containment, victory, and display-role requirements. Three interaction/presentation contracts need clarification before dependent input/controller/graphics stories are finalized. No fundamental UX contradiction was found.

Reviewed the current `ARCHITECTURE-SPINE.md` against `EXPERIENCE.md` on 2026-10-15. This review changes neither source and performs no implementation or code tests.

## Findings

### 1. P2 — Complete the mouse gesture ownership and pause-request contract

- **Evidence:** EXPERIENCE lines 54–59, 74, 85–93 require stage/menu clicks, drawing, an upper-left pause control, and pause requests during a held stroke. Architecture AD-5 and logical interface lines 120–121 carry UI actions and `pause_after`, but do not define which mouse gesture can request pause while the drawing button is already held. The source UX leaves this gesture implicit too; this is an inherited ambiguity rather than a new contradiction.
- **Gap:** The shared hit-region layout does not itself specify UI priority over drawing or whether an action is selected on press or release. A stage/Resume click can enter Active while still held, and a drag can cross a pause region or continue into Victory. Independent implementations could interpret the same physical gesture as both navigation and stroke capture, or make the promised in-stroke pause unreachable.
- **Required clarification:** Publish one input routing rule: which mouse button/gesture requests pause during drawing, when UI actions activate, how an entire consumed gesture is prevented from also creating a stroke, and how mode changes cancel or drain a held gesture. Require a fresh eligible press before drawing or activating a newly displayed menu after a transition. This can accompany the existing shared layout/input schema gate; it does not require adding non-mouse controls.

### 2. P2 — Define the visible/input state while stroke admission is outstanding

- **Evidence:** EXPERIENCE lines 59, 73–76 and 86 describe release, validation, acceptance/rejection, and subsequent drawing. AD-4 permits one outstanding create and retains final immutable geometry; interface line 120 retains the input preview only until controller receipt, while charging waits for the physics acknowledgement.
- **Gap:** There is an interval between controller receipt and the physics outcome in which the previous preview's visibility, the next press/drag, and pause input have no explicit behavior. The reliable transport prevents duplicate insertion but does not specify whether a new gesture is ignored, captured separately, or queued. In particular, an additional drag can start while the last available stroke is awaiting acceptance.
- **Required clarification:** Define an admission-pending interaction substate or equivalent gate. Specify which preview remains visible, which control actions remain available, when drawing becomes eligible again, and how acceptance, rejection, goal precedence, and a pending pause clear that state. Preserve the one-outstanding-request and accepted-only charging rules. Exact processing latency remains an implementation measurement.

### 3. P2 — Give transient feedback a display lifetime and completion rule

- **Evidence:** EXPERIENCE lines 75–76 require brief VGA rejection/exhaustion messages. AD-4 specifies their text and AD-9 permits superseded visual snapshots to be dropped; interface line 124 supplies a generic transient-feedback field. The spine additionally rejects zero-length strokes but does not define their player-facing treatment.
- **Gap:** No rule says when a message is triggered or cleared, which event has priority over pause/victory/menu changes, or how it survives dropped frames. A timer started at physics rejection can expire before any frame showing the message is displayed. Conversely, interpreting “at zero allowance ... show” as a continuous condition can make the intended brief message permanent. A plain click or tiny invalid drag can also be silently discarded or mislabeled as overlap by different modules.
- **Required clarification:** Let the controller own a generation-scoped feedback code and lifetime. Define the exhaustion trigger, invalid/zero-length treatment, replacement/clear priorities, and a bounded visible interval measured from presentation or otherwise guaranteed to reach the screen. Keep transient visibility separate from the persistent zero OLED count and preserve a rejection message when admission is followed immediately by pause, as required by the UX state pattern.

## Covered without a reconciliation issue

- Lobby on startup; three immediately starting stage choices; Resume, Reset Stage, and Back to Lobby; outside-menu click suppression; no automatic stage advance; stage-specific Victory actions.
- Accepted-only allowance charging, overlap rejection without side effects, tangency allowance, gravity/collisions/rotation, fixed obstacles, and ball/stroke containment.
- Full-height left-boundary goal, ball-only trigger, tangency win, frozen winning scene, and goal precedence over pending interaction.
- Coherent VGA/OLED/LED roles, distinguishable cursor/preview, non-colour presentation cues, and a shared hit-region/display layout. Exact visual dimensions are appropriately deferred to the shared UI definition.
- A pause at the next atomic physics boundary is a reasonable synchronous realization of the UX's “immediately,” provided the bounded completion contract is met and the menu reflects the completed pause. It is not a reason to expose partial world state.

## Intentional additions accepted for this review

Continuous simplification to eight points while retaining endpoints, previewing the actual admitted collision shape, bounded linear/angular speed with two internal physics substeps, and the assumed black/white double buffer with magenta overlays are the latest accepted decisions. Their absence from the older experience document is not a finding. Resource fit, timing, and physical validation remain the architecture's declared implementation gates.
