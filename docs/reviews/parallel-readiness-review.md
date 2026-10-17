# Parallel implementation readiness review

Date: 2026-10-17. Reviewer: Codex, acting as a technical document reviewer. This does not represent review or approval by Kim Doyeon, Han Qi-Ze or Chua Choon Hsiang.

## Verdict

**Planning/design bundle prepared for human before-coding approval.** Concrete R1–R4 proposals and bounded first-build handoffs are now supplied. Reference/design checks validate selected mathematics and consistency, not the eventual RTL. Owner adoption, the provisional-short-preview clarification and named before-coding approvals remain pending; M0 is not falsely marked complete. See the [start checklist](../parallel-start-checklist.md).

Scope: the parallel plan, draft Stories 2/3/6 and four implementation-design proposals, checked against the architecture spine, revision 2 contracts/headers, profiles and G-1 through G-5. The reference checker exercises design mathematics/invariants; no HDL simulation or board checks were run. The existing Story 1 Vivado results remain separate evidence.

## Findings corrected in the drafts

| ID | Issue and consequence | Correction |
| --- | --- | --- |
| F1 | Story 2's epoch transfer task did not restate who owns the desired epoch or the requirement to wait for the complete epoch handshake before new-attempt frame publication. Different owners could publish against an uncommitted display epoch. | Assigned desired-epoch/pending policy to controller/integration, retained display-side transport ownership, and added the acknowledged-and-idle publication barrier and acceptance case. |
| F2 | Story 3 specified a 60 Hz cadence without requiring a rational enable at 100 MHz. A rounded divider or added clock domain could diverge from the architecture. | Added rational core-domain enable and long-run cadence evidence, preserving the no-overlap/fault policy. |
| F3 | Story 6 left press/release behavior described as an agreement to make even though the common contract already requires a fresh press/release inside the same current control. | Restated the adopted rule explicitly; no new UI gesture decision is needed for that behavior. |

## Remaining implementation prerequisites

| ID | Required concrete output | Owner and review | Blocks |
| --- | --- | --- | --- |
| R1 — Core context and presentation routing | Concrete [core wiring proposal](../../_bmad-output/specs/spec-q-remastered-on-fpga/core-wiring-proposal.md) prepared: single-capture frame return and reliable core relay, registered private input context, terminal retirement and blocked-draw feedback paths, capacity/backpressure and epoch arbitration. Proposed local port names are not published header macros. Status: specified for review; adoption/implementation evidence pending. | Qi-Ze coordinates controller/input wiring with Choon Hsiang; Doyeon checks required-world/admission joins. | Owner approval of dependent input hit-testing/lifecycle and integrated frame feedback; the previously unspecified route now has a concrete review artifact. |
| R2 — Shared length and numerical design | Concrete [numerical proposal](../../_bmad-output/specs/spec-q-remastered-on-fpga/numerical-design-proposal.md) prepared: floor-square-root Q6 length, widths/scales/rounding, body-property formulas/floors/inverses, turn-phase transforms, rational cadence, movement/correction allocation and kernel-cycle targets. Status: specified for review; range/error proof, adoption and implementation measurements pending. | Doyeon reviews/adopts the numerical design; Qi-Ze agrees its deliberate length quantization; Choon Hsiang reviews Q6 geometry and resources. | Numerical RTL freeze and dependent admission/capture integration await owner review and evidence; the previously unspecified numerical choices now have a concrete review artifact. |
| R3 — Capture and visual design | Concrete [capture/UI proposal](../../_bmad-output/specs/spec-q-remastered-on-fpga/input-ui-design-proposal.md) prepared: 2-pixel anchor-relative sampling, nine-to-eight exact error ranking/tie rule, gesture states, half-open VGA hit rectangles, bitmap font/scaling and wrapped OLED layout. Status: specified for review; provisional-short-preview wording clarification, owner adoption and behavioral/readability evidence pending. | Qi-Ze reviews/adopts capture; Choon Hsiang reviews/adopts visual definitions; Doyeon checks shared length/geometry. | Dependent capture/UI freeze and Story 2 UI layers await adoption, the explicit preview clarification and evidence; the design choices now have a concrete artifact. |
| R4 — Renderer implementation design | Concrete [renderer proposal](../../_bmad-output/specs/spec-q-remastered-on-fpga/renderer-design-proposal.md) supplied: two 9600-word banks, 20 RAMB36-equivalent allocation, exact scanline disk/strip spans, cycle budget, pixel pipeline and four-phase capture/release timing. Status: specified for review; implementation/resource/timing/CDC proof remains build work. | Choon Hsiang reviews/adopts; Doyeon reviews geometry/resources; Qi-Ze reviews UI/epoch joins. | Human before-coding adoption for dependent work; actual scanout acceptance retains the relevant G-2 gate. |
| R5 — Platform evidence | Disposition of two PS/2 CDC-1 and two reset CDC-10 endpoints; reset/lock-loss/input behavior; physical JB/peripheral confirmation; checkout source-byte policy. A passing timing/DRC run does not waive these. | Choon Hsiang leads Story 1; Qi-Ze contributes mouse checks; Doyeon reviews contract effects. | Relevant G-2 peripheral/scanout acceptance and board claims, not all isolated design work. |

Preparation review additionally corrected the numerical transform guard from 1/16 to 1/8 pixel, with integrated motion reduced to 27/8 pixel per substep so the adopted four-pixel total is preserved. The source-byte policy is now explicit in `.gitattributes`; the guarded repair utility and reference checker verify the original hashes rather than changing the manifest to bless converted files. The hardware manifest distinguishes requested clock ratios from the previously verified resolved ratios and no longer describes Vivado evidence as absent.

## Review order

1. Review/adopt R1's supplied core module/port proposal with Qi-Ze and Choon Hsiang, with Doyeon checking admission barriers. Its specified wiring closes the drafting gap; it does not supply named sign-offs or functioning RTL.
2. Doyeon reviews/adopts R2's supplied numerical proposal while Qi-Ze and Choon Hsiang define R3/R4. These are independent design tasks except for the explicit length/layout handoffs. Proposed cycle bounds and transform guards are not measured/proven acceptance results.
3. Update the affected story drafts with selected decisions and their canonical definitions. Do not mark a proposed format, schedule or algorithm as validated before obtaining evidence.
4. Kim Doyeon reviews Story 2; Chua Choon Hsiang reviews Stories 3 and 6. Record actual outcomes. Their named approvals cannot be inferred from this review.
5. Dispatch only the reviewed independent portions. Keep Story 1 evidence work active and join the tracks under Story 7 when its required prerequisites are available.

## Publication and schedule

The planning handoff consists of the commit containing the [start checklist](../parallel-start-checklist.md), its linked design/story drafts, inactive shared declarations, reference checker and review records. The earlier baseline `d96adc2` contains the platform fixes. Developers should pull the published planning commit as their common source before acting on the approved plans; publication of a draft is not reviewer approval.

Course calendar dates are still unconfirmed. Qi-Ze must record the actual demonstration, submission and peer-feedback deadlines before assigning dated M0–M5 targets. This review creates no estimated completion dates or claims of reviewer availability.
