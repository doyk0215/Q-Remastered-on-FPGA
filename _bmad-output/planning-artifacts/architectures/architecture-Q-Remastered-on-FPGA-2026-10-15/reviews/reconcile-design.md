# DESIGN reconciliation review

Date: 2026-10-15  
Scope: Visual compatibility of the architecture spine with the current UX design. Document review only; no HDL, synthesis, display rendering, board validation, or code tests were performed.

## Verdict

**Compatible, with implementation gates already acknowledged by the architecture.** There is no blocking contradiction between the selected black/white/magenta visual system and the assumed two 640×480 one-bit image banks with magenta composition during scanout. The accepted assumption does not promise arbitrary full-color framebuffer content, measured resource fit, or finalized component geometry.

The current DESIGN is authoritative for the selected palette, typography, first-pass screen roles and component inventory. Exact shapes, depth, glyph sizes, component coordinates and hit regions remain open in DESIGN itself. The architecture appropriately makes these shared prototype decisions rather than treating an unspecified full-color UI as a commitment.

## Sources and interpretation

- `../ARCHITECTURE-SPINE.md`, especially AD-3/4/5/6/9/11/12, Structural Seed, the presentation paragraph following the capability map, and Deferred and Prototype Gates.
- `../../../ux-designs/ux-q-remastered-on-fpga-2026-10-15/DESIGN.md`, especially Colors, Typography, Layout & Spacing, Shapes and Components.
- Review assumption supplied for this reconciliation: the user accepted assumed two-color buffering plus magenta overlays; full-color storage and exact component layouts are not promised.

Line references below identify the reviewed snapshot and may move after editing.

## Findings and required follow-through

### 1. Define the bounded magenta compositor before graphics implementation

**Severity: implementation gate; no current contradiction.** DESIGN lines 30–36 assign magenta to the goal edge, active controls, cursor emphasis and brief feedback. The spine lines 146–152 supplies black/white image banks and scanout magenta overlays; AD-9 already requires frame-local coherent overlay metadata.

A one-bit bank can represent the black/white base but cannot independently remember which arbitrary white pixels should become magenta. All retained magenta roles therefore need a bounded procedural shape, mask, text/icon selection or other explicitly budgeted overlay representation. A full-height edge and a bounded cursor are straightforward candidates; the active-control and feedback roles still need their own representation and priority. The phrase “magenta/UI overlay geometry” is a contract for coherent transport, not evidence that any desired overlay complexity fits.

Graphics/integration should publish overlay fields and bounds, mask or glyph access, composition order, memory/pixel latency alignment and resource allowance as part of the gate at spine line 191. This can preserve the selected palette without changing the assumed bank depth. The patterned white preview fallback at line 191 is compatible: DESIGN does not require every provisional stroke pixel to be magenta.

### 2. Preserve role cues through overlap and preview rasterization

**Severity: implementation gate; required UX invariant.** DESIGN lines 34, 56 and 68 require role separation beyond color and legible overlapping objects. The spine lines 64, 82 and 178 preserves actual sampled capsule geometry and explicitly requires cursor/preview distinction. These are compatible requirements, but the exact visual encodings are still open.

A patterned white preview drawn into the one-bit world image must remain identifiable over white strokes, obstacles and the ball, as well as on black background. Similarly, a magenta cursor can cross the magenta goal or an active control. Simply sharing a color or painting an opaque white capsule is insufficient to guarantee separation. Choose and document role-specific shape/outline/pattern cues and ordering in the shared UI definition; any examples such as an outlined cursor or patterned preview remain candidates until that decision is made.

The preview's visual marking must preserve the actual admission envelope and radius rather than presenting a thinner or differently simplified candidate. Distinguish fixed obstacles, accepted strokes and the ball as required by DESIGN; color is available as an emphasis channel, not their only cue. A planned display review should include these overlaps and the transition from provisional preview to accepted body. No claim that those cases have already been rendered or validated is made here.

### 3. Freeze one shared component and hit-region layout, including edge priority

**Severity: implementation gate; small traceability opportunity.** DESIGN lines 44–50 and 60–64 specifies the full VGA lobby/playfield, the upper-left two-bar pause control, pause/victory overlays and twelve component roles. The architecture preserves the display roles, menu actions, inert pause backdrop and shared hit/display definition through AD-5, line 150 and line 178. It does not spell out the pause icon's shape/location in its own text; the source DESIGN supplies that requirement and it should be copied into the shared UI contract when layout is frozen.

The component contract should cover Stage card, Gameplay playfield, Mouse cursor, Pause control, Pause menu, Drawn stroke, Ball, Fixed obstacle, Goal boundary, OLED status, Status LEDs and Victory state. Each interactive item needs the same rectangle or other agreed hit geometry in input and graphics, along with mode-dependent action ownership. In gameplay, the pause control takes its intended click rather than also beginning a stroke; in pause, only menu items act, as AD-5 requires.

Set an explicit composition and placement policy for the upper-left pause control, full left goal marking, cursor, feedback and menus. This resolves the possible visual collision at the upper-left without reserving a permanent VGA status strip or silently changing the 640×480 world. Menu overlays can use opaque black/white panels and bounded magenta emphasis; DESIGN leaves shadows/depth open and does not require alpha blending.

### 4. Bitmap fonts fit the model; OLED text needs a measured layout decision

**Severity: implementation gate; no current contradiction.** DESIGN line 40 and the spine line 150 agree on bitmap headings and readable bitmap labels. AD-11 supplies the previously unresolved dimensions: VGA 640×480 and OLED 96×64. The one-bit banks support hard-edged bitmap glyphs; the selected UX does not require antialiasing, arbitrary font rendering or grayscale.

The shared definition still needs glyph dimensions, sizes/scales, exact label strings, character coverage, line spacing, text locations, clipping and font storage budget. OLED must fit stage, objective, remaining allowance and status in its 96×64 view. For example, “Touch the left edge” has 19 characters; a fixed six-pixel character advance would require 114 pixels, so that common candidate cannot display the objective on one 96-pixel line. Wrapping or a different readable layout is needed if that candidate is selected. This is a sizing example, not an adopted font or a finding that the OLED requirement is impossible.

Keep the agreed objective wording and rejection message. VGA has ample nominal width for the short labels, but actual readability, menu spacing and feedback persistence remain prototype/display decisions. Font ROMs, overlays and OLED storage belong in the aggregate budget at spine lines 152 and 191; the 75 KiB image payload alone is not a whole-system fit result.

## Compatibility matrix

| UX requirement | Architecture support | Assessment |
| --- | --- | --- |
| Black background, white foreground, magenta accents | One-bit black/white base plus magenta compositor; palette reiterated at line 178 | Compatible under accepted assumption; bounded overlays still to define. |
| Full left edge goal plus non-color cue | AD-2 and AD-6; visual mark cannot move `x_ball - r_ball <= 0` boundary | Aligned. Select an edge-anchored cue and priority without creating a separate target body or inset win line. |
| Ball/cursor/strokes/obstacles visually distinct | AD-4/7 shared geometry and line 178 role cues | Aligned invariant; exact encodings and overlap appearance remain open. |
| Full VGA lobby and gameplay; no permanent status strip | AD-3 and line 178 | Aligned. |
| Upper-left two-bar pause control | DESIGN binds it; architecture exposes mouse UI actions and shared layout gate | Retain explicitly in the forthcoming shared UI definition. |
| Pause and victory menus over retained scene | AD-5 and presentation snapshot contract | Aligned; no alpha/depth requirement has been adopted. |
| Outside pause menu is inert | AD-5 | Aligned. |
| Rejection feedback on VGA; invalid preview clears; allowance unchanged | AD-4 and controller presentation record | Aligned; style, position and duration remain shared decisions. |
| Pixel bitmap heading and readable bitmap labels | Structural Seed text/UI row | Aligned; glyph/layout/storage choices remain gated. |
| OLED stage, objective, strokes and status | AD-9/11, status record and line 178 | Aligned; 96×64 arrangement requires font and wrapping decisions. |
| LEDs support status without becoming the only explanation | Controller/status interface | Aligned; exact LED mapping remains a status implementation detail. |
| Open corners, outlines, shadows, depth and exact component geometry | Shared UI definition and graphics/integration prototype gate | Correctly open; no new style or full-color promise is needed to finalize the architecture. |

## Goal-marker audit

The goal requirement is specifically the full left visible edge at every height, with magenta plus an outline/pattern/directional cue. AD-6 correctly keeps that decorative representation separate from the physical ball-contact test and keeps other walls non-goal. The cursor and upper-left pause affordance require readable composition where they meet the marking; a local UI overlap must not redefine the winning range or turn the marker into an inset target strip. VGA blanking must remain excluded as AD-6/11 states. The OLED objective exactly matches DESIGN: “Touch the left edge.”

## Disposition

No source edits are required to resolve a blocking DESIGN conflict. Preserve the accepted one-bit double-buffer assumption and the selected three-color visual output. Carry findings 1–4 into the existing graphics/integration prototype gate and the one shared UI definition before input/display stories are finalized. Architecture finalization can proceed with those gates explicit; display quality, actual resource fit, and timing remain implementation evidence to be produced later.
