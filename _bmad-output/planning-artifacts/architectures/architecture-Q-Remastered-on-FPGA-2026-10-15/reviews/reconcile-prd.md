# PRD and Addendum Reconciliation

**Verdict: PASS WITH FOLLOW-UPS.** No missing core PRD capability, contradictory world ownership, incompatible shared geometry units, or blocking feature-level architecture gap was found. Two planning/traceability corrections remain. This review does not certify hardware behavior or implementation fit.

## Inputs reviewed

- `../ARCHITECTURE-SPINE.md` (draft dated 2026-10-15).
- `../../../prds/prd-Q-Remastered-on-FPGA-2026-10-15/prd.md`.
- `../../../prds/prd-Q-Remastered-on-FPGA-2026-10-15/addendum.md`.

Line references below refer to the reviewed source files. No source input or spine was modified.

## Findings

### 1. Restore the before-story-planning gate for the rotation demonstration

**Priority: medium; planning follow-up, not a missing physics capability.** PRD lines 235–236 require the physics/game-control owners to identify the prepared stage or physics setup for repeatable off-center collision and visible rotation before story planning. Spine line 195 defers stage layouts, initial state and demonstrable solutions until demo acceptance; it does not separately retain this earlier rotation checkpoint. AD-7 adopts angular response and the capability map covers it, so the behavior is supported, but its demonstrability can be discovered too late.

**Resolution:** Add a named physics/controller checkpoint before story planning for a repeatable off-center impact and observable stroke rotation. Complete stage layouts and solutions can remain due before demo acceptance. A fully synthesized kernel or measured numeric constants are not required to name this scenario.

### 2. Record the addendum as an explicit input and preserve its delivery reference

**Priority: low; traceability follow-up.** Spine lines 12–15 list the PRD and two UX documents but omit the adjacent addendum. The addendum supplies the implementation context being reconciled here, including static-capsule obstacles and separate wall counts (lines 41–45), shared ownership (line 23), and course packaging obligations (line 22). The spine incorporates the technical constraints, but its release-checklist row (line 197) says it follows the PRD, while the detailed archive/report obligations are actually recorded in the addendum.

**Resolution:** Add `addendum.md` to spine source metadata and identify it as the source for the release checklist. Keep the board-tested bitstream, archive size/verification and report/disclosure obligations in that separate checklist, as the addendum explicitly requests. No hardware subsystem or expanded product scope is required.

## Requirement coverage

| PRD requirement | Spine coverage | Reconciliation |
| --- | --- | --- |
| FR-1..3: lobby, direct launch, pause/resume, reset and return | AD-1, AD-5, logical control interface | Preserved, including no outside-menu resume and admission before a pending pause. Discarding the attempt on lobby return has the required observable reset behavior. |
| FR-4..6: cursor, released-stroke admission, five accepted strokes, OLED count and rejection feedback | AD-2..4, AD-9, AD-11, presentation contract | Preserved; authoritative validation, tangency, atomic rejection, exact charge and both VGA feedback messages are explicit. |
| FR-7..8: gravity, translation, collision, visible stroke rotation, four-wall containment | AD-2..3, AD-6..8 | Preserved; wire mass approximation and bounded sequential impulses are architecture selections permitted by the PRD's non-exact-physics scope. |
| FR-9..10: full-left-boundary goal, tangency, latched victory, stopped world and explicit navigation | AD-5..6, AD-9 | Preserved; winning contact survives correction and is not a droppable visual event. |
| FR-11..13: full playfield, overlays, OLED information and LED state | AD-9..11, capability map and shared layout requirement | Preserved, including final-stage navigation and distinguishable cursor/preview. |
| Three stages, bounded objects, mouse-only input, one bitstream, reliable demonstration and resource evidence | AD-1..2, AD-5, AD-10..12, prototype gates | Preserved; physical mouse/converter compatibility and timing/resource claims remain explicit acceptance gates. |

## Architecture selections and permissible deferrals

- The signed 18-bit/Q6 position, radius, length and linear-velocity contract is explicit, including coordinate orientation and pixels per outer-update velocity units. Physics owns admitted mutable geometry; displays receive its transformed points, avoiding a competing transform authority.
- The 60 Hz outer update is stronger than the addendum's candidate near-60 Hz direction, but it is an explicit architecture choice with a worst-case acceptance gate, not an unsupported claim of achieved performance. Two internal substeps are a revisitable seed, with shared velocity units preserved.
- The double one-bit framebuffer remains marked assumed, has a resource-budget explanation and revisitation gate, and does not claim measured fit. This respects the addendum's warning against assuming a full RGB double framebuffer fits.
- Exact contact kernels, solver limits, arithmetic scales, gravity/radius values, simplification thresholds, packing and level contents can be finalized in their stated prototype/shared-definition checkpoints. Those deferrals do not remove PRD capabilities. AD-12 and the gate preamble prohibit independent incompatible interfaces.
- Rejecting zero-length input without charge is a necessary admission rule for the adopted wire body. It does not consume allowance or silently create an unsupported body.

**Blocking gaps:** None at feature architecture altitude. Hardware validation, kernel choices and integrated acceptance evidence remain future work rather than evidence already supplied by this architecture. No implementation or code tests were performed.
