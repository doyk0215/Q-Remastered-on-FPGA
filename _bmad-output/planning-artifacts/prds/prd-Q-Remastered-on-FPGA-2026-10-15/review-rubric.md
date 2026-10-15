# PRD Quality Review — Q Remastered on FPGA

## Overall verdict
The PRD has a clear, coherent course-demo experience, and the revised MVP consistently includes visible rotation and angular collision response for released strokes. It is ready to feed into UX and architecture exploration, but not yet a crisp implementation baseline: several acceptance conditions remain qualitative, hardware-dependent scope is unresolved, and the mouse-only exception is inaccurately summarized in the assumptions index.

## Decision-readiness — adequate
The core interaction choices are explicit: stage selection starts immediately (§4.1, FR-1), the pause icon opens the named menu (§4.1, FR-2), leaving resets the attempt (§4.1, FR-3), and any ball-target overlap wins (§4.4, FR-9). The PRD also surfaces real hardware trade-offs in §9 and in addendum.md §3, including object budgets, collision geometry, rotation, and VGA availability. These are appropriately assigned to architecture rather than disguised as settled decisions.

The course-input exception is reported as confirmed in §5, but §10 describes mouse use as permitted by the manual, while addendum.md §2 says the manual requires switches and buttons and that staff approved mouse-only input. This weakens the decision record for a deliberate deviation. The mechanics for what a visible rotation must demonstrate are also only qualitative (§4.3, FR-8).

### Findings
- **medium** Mouse-only exception is misattributed (§5, §10; addendum.md §2) — The PRD says staff confirmed mouse-only input, but the assumptions index says the manual permits mouse use, which is not the same claim and conflicts with the addendum's account of the switch/button requirement. *Fix:* State in §10 that mouse-only game input is a course-staff-approved exception; separately describe the mouse as an optional device under the manual.
- **medium** Rotation acceptance lacks a reproducible scenario (§4.2, FR-5; §4.3, FR-8; §8, SM-1) — The requirement says an off-center impact “can change” angular motion and visibly rotate a stroke, without naming a deterministic collision setup or minimum observable result. *Fix:* Define a test level/setup and observable pass condition for angular response, while leaving the implementation model to architecture.

## Substance over theater — strong
The content is specific to a mouse-controlled drawing puzzle on Basys3: the lobby, stroke budget, target overlap, pause/retry flow, integrated bitstream, and brief live demonstration all support the stated experience (§1, §2.2, §§4–5). The single named protagonist is explicitly marked as an assumption rather than presented as research, and the assessor role is tied to the demo job (§2.1–2.2). There is no unsupported market differentiation or padded persona set. Some quality statements are still broad, but the PRD identifies them as observed/verified project outcomes rather than generic scale or security boilerplate (§5).

### Findings
- **low** Demo-fit threshold remains interpretive (§5) — “Straightforward to show” within a typical 2–5 minute demonstration is useful context but not a pass/fail criterion. *Fix:* During planning, identify the core sequence and a target completion time if the course assessment needs a demonstrable threshold.

## Strategic coherence — strong
The thesis is that a player can draw a limited movable stroke and directly observe gravity and collision effects while guiding a ball to a target (§1). The feature set and success metrics follow that arc: SM-1 tests the complete puzzle loop including stroke rotation, while SM-C1 protects retry and integration from scope growth (§8). The MVP is an experience/product slice, not a collection of unrelated FPGA capabilities. Scope is deliberately bounded to one ball and small, resource-limited levels (§7.1; addendum.md §3).

### Findings
- **medium** Success metric depends on a suitable authored level (§8, SM-1; §9) — SM-1 requires visible rotation “after an off-center collision,” but no confirmed level or test setup guarantees that such a collision can be produced within the demonstration. *Fix:* Make one acceptance level/setup part of the planned verification, or define how the demo operator creates the off-center impact reliably.

## Done-ness clarity — thin
The FRs generally include observable consequences and cover the key states: stage selection, pause/resume, reset, allowance, collision containment, goal overlap, display status, and LEDs (§4). Several statements nevertheless lack bounds needed to decide whether an implementation passes. Examples include “a visible cursor” and positions that “correspond” to the playfield (§4.2, FR-4), a rotation that “can visibly change” (§4.2–4.3), distinguishing status during the demo (§4.4, FR-10), and cursor/physics “responsiveness” with rates to be recorded later (§5). The constraints are acknowledged but there are no minimum supported object/stroke counts, update rate, response limits, or utilization target. This is a reasonable draft for architecture discovery, but story-level acceptance will need measurable criteria.

### Findings
- **high** Core input, physics, and capacity criteria are not bounded (§4.2–4.5; §5; §7) — Terms such as “visible,” “correspond,” “continuous,” and “small set” do not define minimum pointer accuracy, update behavior, level/object capacity, or acceptable collision behavior. *Fix:* After hardware/interface discovery, set minimum demonstrable values and repeatable pass conditions for cursor/drawing, physics updates, rotation, and supported content. Keep them modest and aligned with measured Basys3 capacity.
- **medium** Status and LED acceptance is underspecified (§4.4, FR-10; §4.5, FR-13) — FR-10 requires distinguishable active, paused, and victory states, but FR-13 only requires LED changes for pause and victory; neither assigns exact signals or a check procedure. *Fix:* Specify which visible indicator communicates each state and how each transition will be verified.
- **medium** Pause semantics omit input and drawing edge cases (§4.1, FR-2; §4.2, FR-4) — “Immediately freezes” names the ball and released strokes, but does not say whether the cursor, an in-progress stroke, or input clicks remain active while the menu is open. *Fix:* State whether pausing cancels or preserves an active stroke, and define which menu region receives clicks while paused.

## Scope honesty — adequate
The PRD separates MVP in-scope from non-goals and explicitly limits geometry, object counts, and fidelity (§§6–7). The addendum is clear that fixed-point formats, geometry, angular response, update rate, mouse mapping, and rendering strategy are proposals or architecture questions rather than settled implementation facts (addendum.md §§1, 3–4). Five open questions identify owners and revisit points (§9), a reasonable density for an FPGA course project entering architecture. The unresolved VGA path and resource-derived content budget are genuine scope gates; they are visible rather than silently assumed.

### Findings
- **medium** Hardware-dependent scope is open at story-planning time (§5, §7, §9) — The PRD commits to rotation, VGA, mouse-only interaction, and an integrated one-bitstream demo while the VGA path, resource capacity, mouse protocol, and angular model remain open. The mouse exception is already staff-confirmed, but the other choices can still change feasible scope. *Fix:* Resolve interface and utilization questions in architecture, then explicitly confirm or revise the committed MVP before story breakdown.

## Downstream usability — adequate
The PRD has a glossary, one named journey, globally sequential FR-1–FR-13 IDs, and SM-1–SM-4/SM-C1 trace links that resolve (§§2–4, §8). The addendum keeps technical detail in a downstream-friendly place and lists the exact angular/body-geometry decisions for architecture (addendum.md §3). A few terms and interfaces still need normalization: “level” and “stage” are used interchangeably; the glossary calls a ball a “physics object” while orientation and angular-response requirements mostly make sense for released strokes; and the pause-menu input and mouse/renderer coordinate contract are deferred (addendum.md §3–4).

### Findings
- **medium** Domain vocabulary and object applicability need one pass (§3; §4.3, FR-7–FR-8; §7.1; addendum.md §3) — “Level (stage)” permits two names, and “physics object” includes the ball although rotation is only visibly meaningful for a stroke. *Fix:* Pick a canonical term for level/stage and clarify which object types have linear versus angular state and response.
- **low** PRD frontmatter remains draft (§1–§10) — The file is explicitly marked `status: draft`; downstream consumers should treat the open items as unresolved rather than as final implementation contracts. *Fix:* Before story creation, close or defer the listed architecture gates and update the lifecycle status through the PRD finalize workflow.

## Shape fit — strong
This is a player-facing game with meaningful multi-step interaction, so a user journey is appropriate. UJ-1 has a named protagonist, carries the first-time demo context inline, and covers the complete startup-to-victory/retry path (§2.2). The FR structure then maps the journey to capabilities, while the assessor is treated as a secondary audience rather than given an artificial second journey (§2.1–2.2). The additional hardware and course-assessment sections fit a chain-top PRD for UX, architecture, and story planning.

### Findings
No shape-fit finding.

## Mechanical notes
- **Glossary:** “Level (stage)” intentionally aliases terms, but use one consistently in requirements and screens. “Drawing allowance” is clearly defined; “stroke budget” occurs only as a synonym in earlier context and is not in this draft.
- **IDs and cross-references:** FR-1 through FR-13 are unique and sequential. UJ-1 and SM-1 through SM-4 plus SM-C1 are unique; all FR references in success metrics resolve. No broken “Journey served” references found.
- **Assumptions Index roundtrip:** The Alex assumption at §2.2 is indexed. §10's claim that “Mouse use is permitted by the course manual” is not an assumption as currently stated and should be replaced with the confirmed staff approval / manual distinction. VGA availability is correctly called out as unconfirmed in §5 and indexed in §10.
- **Journey protagonist:** UJ-1 names Alex and carries the first-time live-demo context inline. The assumed nature of this persona is disclosed.
- **Required sections and artifact state:** Purpose, vision, target user/JTBD, journey, glossary, features/FRs, cross-cutting requirements, non-goals, MVP scope, success metrics, open questions, and assumptions index are present. Both PRD and addendum remain draft as of 2026-10-15.
