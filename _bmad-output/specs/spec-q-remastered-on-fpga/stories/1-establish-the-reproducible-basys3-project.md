---
title: Establish the reproducible Basys3 project
type: chore
created: 2026-10-16
status: in-progress
baseline_commit: f6cb0d73080334545b0fe4f98ab3c832dd79341d
route: dispatch
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/specs/spec-q-remastered-on-fpga/SPEC.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

Provide a reproducible Basys3 foundation in Vivado 2025.2: unchanged supplied drivers, clocks/resets, VGA timing and constrained board adapters.

## Boundaries & Constraints

**Always:** Target xc7a35tcpg236-1; application Verilog-2001, supplied VHDL permitted. Consume shared headers. Core/mouse: 100 MHz; VGA: 25.2 MHz; OLED: 6.25 MHz. Require and record an explicit JA/JB/JC build argument; the physical OLED connection remains unconfirmed.

**Never:** Add gameplay buttons, TMDS, physics, framebuffers, menus or status text. Preserve local work/notices; stage reset must not restart clocks. Device compatibility remains a board gate.

## I/O & Edge-Case Matrix

| Condition | Required behavior |
| --- | --- |
| Startup or clock-lock loss | Hold domain resets; recover clocking and release each reset synchronously after lock. |
| Mouse initialization | Program 12-bit bounds 639/479 and position 320/240 before publishing samples. |
| Mouse consumer stalled | Hold the exposed sample; queue reports without overwriting button transitions; latch INPUT_OVERFLOW if capacity is exhausted. |
| Missing/invalid OLED header | Fail project creation with a clear error. |
| Foundation top running | Valid VGA timing with black RGB, black OLED pixels and LEDs off; drain mouse samples without generating game actions. |

</frozen-after-approval>

## Code Map

- `rtl/include/`: preserve all four headers, contract revision 2 and parameter profiles.
- `/Users/doyeon/Desktop/FDP2026/FDP2026.srcs/sources_1/new/`: `Mouse_Control.vhd` declares `MouseCtl`; `Ps2Interface.vhd` has fixed 100 MHz delays; `Oled_Display.v` captures pixels on falling edges. All three hashes match ARCHITECTURE-SPINE.md.
- Supplied `constrs_1/new/Basys3_Master.xdc`: commented pin baseline; supplied `My_Top_Module.v` is empty. Do not edit either source project.
- Project F `display_controller`, commit `dafbe3385749da4ae2100bba2945350ace7ec04e`: inspected `rtl/display_timings.v` and MIT license; signed coordinates include negative blanking positions.

## Tasks & Acceptance

Primary role: integration. Reviewer role: graphics.

**Execution:**

- [x] `third_party/supplied/`: copy the three drivers unchanged; `third_party/projectf/`: import pinned timing and license. `hardware/source-manifest.json`: record origins, full revisions, hashes, languages, notices and compile order; distinguish supplied provenance from open-source licensing.
- [x] `scripts/vivado/create_project.tcl`: use repository-relative paths, mixed HDL, include paths and explicit top; reject wrong Vivado version/header. Generate under `build/`; create `.gitignore` for generated outputs.
- [ ] `scripts/vivado/create_clocks.tcl`, `rtl/platform/q_clock_reset.v`: generate exact Clocking Wizard outputs, global buffers, domain reset synchronizers and lock-loss recovery. Retain IP settings; permit separate clock managers.
- [ ] `scripts/vivado/board_pins.tcl`: generate `build/basys3_io.xdc` from the supplied baseline: W5/10 ns clock, VGA, PS2 C17/B17/pull-ups, LEDs and selected header. Map OLED CS/MOSI/NC/SCK/DC/RES/VCCEN/PMODEN in order; leave NC undriven. Treat generated clocks and I/O/CDC explicitly, without blanket timing exceptions.
- [x] `rtl/platform/q_mouse_adapter.v`: initialize, capture coherent reports, implement eight-entry FIFO, Q_MOUSE packing and stalled-payload retention; latch `Q_FAULT_INPUT_OVERFLOW_BIT`. Preserve 40 reports/s and 12-bit driver ports before clamping/narrowing.
- [x] `rtl/platform/q_oled_adapter.v`: expose pixel request/index/data stable before falling-edge capture; defer status rendering/CDC to Story 9. `rtl/platform/q_vga_timing.v`: expose signed coordinates/frame/enable/sync; use shared dimensions and negative sync.
- [x] `rtl/q_top.v`: connect matrix outputs. `docs/hardware-bringup.md`: record creation command, wiring/orientation, clocks/resets, interfaces and pending evidence. Link it from `README.md`.

**Acceptance Criteria:**

- Given a fresh checkout/Vivado 2025.2, when creation receives a valid header, then HDL/IP/constraints resolve without the Desktop project.
- Given imports, when compared with recorded sources/hashes, then supplied bytes/notices match and Project F is pinned/licensed.
- Given startup, lock loss, report backpressure or invalid header selection, when handled, then the matrix behavior holds without gameplay input or silent event overwrite.
- Given the design, when timing is examined, then all clocks, reset crossings, OLED capture and top-level pins are covered; warnings are resolved or explained.
- Given VGA timing, when one frame is counted, then it has 800×525 pixel periods, 640×480 active pixels and 96-pixel/2-line negative sync pulses, with black RGB outside active video.

## Implementation Notes

- Approved on 2026-10-16. Existing BMAD documents and shared headers are pre-existing work to preserve; no commits or pushes are authorized. A planning-only upstream checkout is available at `/private/tmp/q-story1-projectf-dafbe338-20261016`; import the specified pinned files from it after checking its revision. No network operation is required.

- Source implementation authored on 2026-10-16: imports/manifest, four Vivado setup/constraint files, five platform/top RTL files, generated-output ignores and bringup documentation. Checked tasks indicate authored source or inspected imports, not runtime acceptance. Clock/IP and active-XDC generation tasks remain unchecked until Vivado and an explicit physical header selection are available.
- Source review corrected partial-startup lock-loss recovery by remembering each manager's acquisition independently; mouse report capture waits an additional core cycle for the supplied registered Y output. Preserved vendor bytes and corrected the manifest description of the OLED's three-condition redistribution notice.
- Manifest hashes match every listed source. All 30 pre-existing planning/header inputs in the preservation snapshot are unchanged. The full baseline/untracked diff is `/private/tmp/q-story1-all-changes-vkdokqo3.diff`; inspection focused on Story 1 additions and the README change, with copied-source identity established by hashes.
- Acceptance evidence: imported source identity is satisfied by hash comparison. Project creation, reset/FIFO behavior, generated clocks, actual constraint endpoints, frame waveforms and board operation remain unverified. No tests were added or run; no synthesis/bitstream was generated. Status stays in-progress; Stories 2..12 have not been dispatched.

## Spec Change Log

## Review Triage Log

## Verification

Source/hash inspection only; Vivado is absent from this host's PATH. Future authorized elaboration/reports/board checks must record results; missing evidence leaves acceptance pending. Add/run no tests without a user request. This plan does not close G-1/G-2.

References: [Project F](https://github.com/projf/display_controller), [AMD clock primitives](https://docs.amd.com/r/2025.2-English/ug953-vivado-7series-libraries/MMCME2_BASE), [OLED pinout](https://digilent.com/reference/_media/reference/pmod/pmodoledrgb/pmodoledrgb_rm.pdf).
