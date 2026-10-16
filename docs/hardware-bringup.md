# Basys3 foundation — Story 1

This foundation targets **xc7a35tcpg236-1 with Vivado 2025.2**. It produces VGA timing with black RGB, black 96×64 OLED pixels, LEDs off, and drains mouse reports without game actions. Creation and physical compatibility are awaiting Vivado/board evidence; this document does not close G-1 or G-2.

## Create the project

From the repository root, run the following in Vivado 2025.2's environment, replacing `JA` with the explicitly selected **JA, JB or JC** header:

```sh
vivado -mode batch -source scripts/vivado/create_project.tcl -tclargs JA
```

The command rejects missing/invalid header arguments and other Vivado versions before project creation. **JA in this example is not a confirmed physical connection.** The selected header, tool version, part and top are recorded in `build/build-selection.txt`. The project is `build/vivado/q_remastered.xpr`; all generated artifacts are ignored by Git. Recreating overwrites that generated project, so retain any evidence elsewhere before repeating creation.

All inputs resolve relative to the script's repository location, including the unchanged supplied pin baseline. The original Desktop project and temporary upstream checkout are not build dependencies. Mixed VHDL/Verilog sources use `xil_defaultlib`; application files use Verilog-2001 syntax and `rtl/include`. `q_top` is explicit. Synthesis preserves hierarchy so scoped timing constraints can resolve their intended endpoints.

`hardware/source-manifest.json` records import origins, full upstream revision or supplied SHA256 identity, hashes, language, notices and compile order. The three supplied drivers retain their bytes and notices. The mouse sources have supplied provenance without a separately asserted open-source license; the OLED's embedded redistribution notice is retained. Project F timing and its MIT license are copied unchanged from commit `dafbe3385749da4ae2100bba2945350ace7ec04e`. Shared contract revision 2, geometry profile 3 and physics profile 1 are preserved.

## Connect the board

- Plug the compatible mouse into Basys3 USB-A; the PIC24 presents PS/2-style signals on **C17 (clock)** and **B17 (data)**. Both FPGA pins use LVCMOS33 and pull-ups. Do not connect an external 5 V PS/2 cable to these FPGA pins.
- Connect Basys3 VGA to the external **active VGA-to-HDMI converter**, then the HDMI monitor. No TMDS transmitter is implemented. Exact mouse and converter models remain unconfirmed.
- Connect the 96×64 colour **PmodOLEDrgb**, using the header selected at creation. Match the Pmod's marked pin 1 to the board header's pin 1; do not infer orientation from the display face. Check both ground/power positions against the connector markings before applying power. Header physical pins 5/11 are ground, 6/12 are 3.3 V; these are board power pins rather than FPGA signals.

The adapter maps the Pmod's eight signal positions in this order:

| Physical Pmod pin | Function | JA FPGA pin | JB FPGA pin | JC FPGA pin |
| --- | --- | --- | --- | --- |
| 1 | CS | J1 | A14 | K17 |
| 2 | MOSI/SDIN | L2 | A16 | M18 |
| 3 | NC — no FPGA port or drive | J2 unused | B15 unused | N17 unused |
| 4 | SCK | G2 | B16 | P18 |
| 7 | DC | H1 | A15 | L17 |
| 8 | RES (active low) | K2 | A17 | M19 |
| 9 | VCCEN | H2 | C15 | P17 |
| 10 | PMODEN | G3 | C16 | R18 |

`board_pins.tcl` extracts active mappings from the copied master XDC and emits `build/basys3_io.xdc`. W5 has the 10 ns board clock; all VGA, PS/2, LED and seven OLED signal ports are constrained. No gameplay switches or buttons are present. Unused header positions, including NC, have no application output buffer; the bitstream's unused-pin setting is explicitly `Pullnone`.

## Clocks, startup and recovery

| Domain | Frequency | Source |
| --- | --- | --- |
| Core/mouse | 100 MHz | W5 → IBUF → BUFG |
| VGA | 25.2 MHz | Clocking Wizard MMCM: 100 × 31.5 / 5 / 25; VCO 630 MHz; BUFG output |
| OLED | 6.25 MHz | Separate Clocking Wizard MMCM: 100 × 8 / 1 / 128; VCO 800 MHz; BUFG output |

`create_clocks.tcl` retains generated XCI/settings under `build/`, records resolved IP properties, and rejects a resolved output ratio differing from the requested frequency. These are intended configurations, not measured clocks. Two managers permit each exact rate within a separate VCO plan. Vivado must still establish legal target-specific configuration and routes.

`q_clock_reset` powers up with both managers held in reset for 16 board-clock cycles. Resets assert asynchronously whenever either raw LOCKED signal drops or manager reset asserts. Three-stage synchronizers release reset on each domain's rising edges after both managers lock. The board-clock supervisor synchronizes both LOCKED signals and remembers each manager's successful acquisition independently. Loss from either previously locked manager restarts both for 16 board-clock cycles, including loss during partial startup before the other manager locks. Restart clears both acquisition histories. The supervisor continues operating while a generated clock is stopped. FPGA configuration initializes the supervisor; no gameplay reset reaches clock managers or peripheral resets. A future stage reset must use the ordinary logical transaction contract.

## Interfaces and timing

`q_mouse_adapter` uses `Q_CORE_PORTS`, `Q_MOUSE_SOURCE_PORTS` and `Q_FAULT_SOURCE_PORTS`. It explicitly programs 12-bit maximum coordinates **639/479**, then position **320/240**, waits for registered coordinates to settle, and only then accepts reports. The unchanged driver retains its **40 reports/s** setting and all 12-bit coordinate/value ports. Report capture occurs one core cycle after observing `new_event`: the supplied non-wheel path can assert that event while its registered `ypos` is still receiving the final Y update. This delay captures coherent final coordinates/buttons, clamps at 12-bit width, then packs the shared `Q_MOUSE` fields. An eight-entry FIFO preserves report/button order. The exposed entry and valid remain stable while stalled. A simultaneous pop permits a push even when full. A full FIFO with no pop rejects the incoming report and latches `Q_FAULT_INPUT_OVERFLOW_BIT`; it never overwrites queued transitions. This fault clears only with coordinated startup/peripheral reset. Invalid FIFO data while valid is low is unspecified.

`q_vga_timing` wraps the pinned Project F module with signed 16-bit beam coordinates. Horizontal coordinates run **−160..639**; vertical coordinates run **−45..479**. One frame contains **800×525** pixel periods, including **640×480** active periods, **96-pixel** negative horizontal sync and **2-line** negative vertical sync. At 25.2 MHz the intended frame rate is exactly 60 Hz. Frame pulses occur at the first blanking coordinate. Top-level RGB is black in active and blanking periods, with no added RGB/sync latency. Counts are derived from source parameters; no frame simulation or measurement has been run.

`q_oled_adapter` exposes the driver's 13-bit pixel index, request, frame and sending indicators. The renderer must provide a combinational 16-bit pixel value in the OLED domain for the exposed index. The index/request change after a driver falling edge; the adapter registers pixel data on the intervening rising edge, allowing **80 ns nominal half-cycle setup** before the next falling-edge driver capture. A synchronous memory with an extra read cycle requires a separately designed pipeline. Foundation pixels are constant black. Story 9 owns status rendering and its core-to-OLED mailbox; there is no multibit payload CDC in this foundation.

`foundation_timing.xdc` runs late during implementation. Clocking Wizard constraints provide generated clocks; all three domains retain their board-clock relationship. VGA outputs have an explicit 0..5 ns budget and OLED outputs 0..10 ns relative to the OLED falling edge. These are provisional board routing budgets, not monitor/OLED electrical measurements. LEDs/RGB are constants in this build and may be optimized. PS/2 output paths have a local 10 ns datapath bound because the receiver is asynchronous. Exceptions cover only first LOCKED synchronizer stages, async preset pins of reset synchronizers, and the supplied PS/2 deglitch frontend's async input capture/counter endpoints. Later synchronizer stages, reset release/recovery paths and OLED rising-to-falling pixel capture remain timed. Endpoint queries fail if empty; no blanket asynchronous clock grouping is used.

The unchanged PS/2 driver compares raw inputs in its deglitch/counter frontend before the downstream synchronization described in its source. Its CDC behavior requires board/CDC review; source preservation does not establish electrical reliability. No timing exception is evidence that this frontend has passed a CDC check.

## Evidence and remaining acceptance

On 2026-10-16, source inspection confirmed the supplied three driver hashes match the approved architecture; the copied baseline and Project F timing/license hashes are recorded in the manifest. The upstream checkout's full revision was inspected before import. Existing shared headers were not edited. **No tests were added or run. Vivado is absent from this host's PATH.** Project creation, mixed-language elaboration, IP legality, hierarchy/constraint endpoint resolution, synthesis and implementation have not been demonstrated.

When authorized and Vivado/board access is available, record the selected header and exact peripheral models, creation log/resolved settings, elaboration, clock/timing/CDC/DRC reports, unconstrained-path review, reset/lock-loss behavior, queued report/backpressure/overflow behavior, VGA frame counts and sync waveforms, and black OLED operation. Resolve or explain every warning, including intentionally unused foundation signals, source-supplied HDL constructs and constant-output optimizations. Confirm timing exception endpoints still match after synthesis, that every generated clock is recognized, and that no unreviewed path is unconstrained. Physical wiring, compatibility, timing/resource measurements and G-1/G-2 acceptance remain pending; this implementation makes no bitstream fit claim.
