# Independent Technical Reality Check

**Verdict: PASS.** The committed platform, driver contracts, rendering envelope, numeric geometry representation and physics algorithm families have primary-source or actual-source support. No named dependency is fictional, no unimported candidate is represented as pinned, and no measured hardware fit is claimed. Both clarifications identified during this review were independently confirmed addressed in the spine updated 2026-10-16. Existing prototype and integration gates remain required.

Reviewed `ARCHITECTURE-SPINE.md` and its adjacent `.memlog.md`, the actual supplied project at `/Users/doyeon/Desktop/FDP2026`, and primary sources linked below. The coaching question about a pause gesture during a drag remains unresolved and is not answered by this technical review. Only this review file was written. No code tests, synthesis, implementation, downloads, or supplied-source edits were performed.

## Findings

### T1 — Distinguish segment length storage from total polyline length

**Priority: medium; addressed.** The initially reviewed AD-3 said “lengths” use signed 18-bit storage with six fractional bits. That format reaches 2047.984375 pixels. AD-7 needs total segment length for wire mass. A valid bounded stroke can have a larger total: a five-vertex rectangular path using coordinates (10,10), (629,10), (629,469), (10,469), (10,10) has length 2156 pixels. The seven-segment unrestricted playfield bound is approximately 7×sqrt(639²+479²)=5590.2 pixels.

AD-3 already allows separately documented accumulator widths, so this is not evidence that the architecture intends wrapped arithmetic. However, “lengths” could be interpreted as forcing a cached total back into 18 bits.

**Resolution confirmed:** Current AD-3 explicitly limits the 18-bit/Q6 length commitment to bounded per-segment lengths and requires wider storage for accumulated polyline length and mass moments. Signed 20-bit/Q6 can represent the complete in-playfield seven-segment total-length bound; intermediate squares, products and other mass calculations still need their own analysis. Physics publishes final widths in its existing numeric contract gate. The correction does not add a shorter maximum accepted path length.

### T2 — Preserve PS/2 electrical pull-ups in the integration gate

**Priority: low; addressed.** AD-11 correctly adopts the Basys3 USB-A/PIC24 PS/2-style chain and AD-12 requires active pin constraints. The electrical pull-up requirement was not explicit in the initial spine. The [Digilent Basys3 manual, §6.1](https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys3_rm.pdf) requires internal pull-ups on these idle-high lines. Actual supplied `Basys3_Master.xdc` lines 138–139 include `PULLUP true` for PS2Clk/C17 and PS2Data/B17, but those entries are commented out.

**Resolution confirmed:** The current clock/XDC/CDC integration gate explicitly requires activating and auditing mouse PS/2 clock/data pull-ups and notes the commented supplied entries. Actual constraint activation remains implementation work. This does not require a new input architecture.

## Platform and actual-source evidence

### Tool and device

- Actual `FDP2026.xpr` line 2 identifies Vivado v2025.2; line 11 selects `xc7a35tcpg236-1`. The design files are mixed VHDL/Verilog, consistent with preserving supplied drivers behind Verilog project adapters.
- [AMD UG973, Vivado 2025.2 Supported Devices](https://docs.amd.com/r/2025.2-English/ug973-vivado-release-notes-install-license/Supported-Devices?contentId=AQCDGBAgcuPR5llQMp1Hgg) lists XC7A35T. The short original URL initially returned an error; this official content URL was accessible. Tool/device selection is supported independently of the local project metadata.
- The local project does not demonstrate implementation: `My_Top_Module.v` is an empty module and the relevant clock/peripheral entries in the master XDC are commented. This agrees with the spine's warning that present drivers are not integrated drivers.

### Supplied source identity and interfaces

The following SHA256 values were recalculated from the actual local files and exactly match the spine:

| File | SHA256 | Actual interface/timing observations |
| --- | --- | --- |
| `Mouse_Control.vhd` | `f57b58c4c35b21e569b0d279a2014c41f19a57bf10990338463e0480944d9ca7` | Entity `MouseCtl`; 100000000 Hz generic; actual xpos/ypos/value ports are 12 bits, despite older comments describing 10 bits. `SAMPLE_RATE=x"28"` requests 40 samples/s. Explicit setx/sety/setmax_x/setmax_y inputs exist. |
| `Ps2Interface.vhd` | `7c2af6f51bd408549435bbbbafcb9d33053a98a1a63bdc1046c9872f52c499eb` | Required `Ps2Interface` dependency is instantiated by MouseCtl. Timing constants and synchronization/debounce logic support retaining the supplied 100 MHz baseline. Lines drive low or release to Z. |
| `Oled_Display.v` | `f0f7b4a7a5b65a40598ccbb8f985ac826e788ce381c613409e92cea52528ffe5` | Width=96, Height=64, pixel count=6144, `$clog2` index width=13, pixel_data=16 bits, ClkFreq default=6250000. Main sequential process is on negedge clk. |

Mouse bounds initialization is necessary: source defaults are x"3C0" and x"280", which are 960 and 640, regardless of stale adjacent decimal comments. Source position processes support the explicit initialization required by AD-10/11; merely resetting the mouse FSM is not an adequate substitute.

OLED `sample_pixel`/`pixel_index` are combinational indications derived from the driver state/counter; `SendPixel` captures `pixel_data` in the negedge process. The spine correctly requires meeting this actual setup/sampling contract rather than promising that an arbitrary registered pixel provider will work. Its exact adapter timing remains an integration deliverable. [Digilent's Pmod OLEDrgb specification](https://digilent.com/shop/pmod-oledrgb-96-x-64-rgb-oled-display-with-16-bit-color-resolution/) independently confirms 96×64 and 16-bit colour.

### Board and display envelope

[Digilent's Basys3 reference manual](https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys3_rm.pdf) confirms 5200 slices, four LUTs/eight flip-flops per slice, 1800 Kbits BRAM, 90 DSP slices, the 100 MHz oscillator, VGA output, and PIC24 USB HID to PS/2 emulation. These support the architectural envelope; they do not prove aggregate resource fit. The external active VGA-to-HDMI conversion chain does not require FPGA TMDS logic. Converter and Logitech model compatibility remain unverified physical gates, honestly identified as such.

[Project F's display-controller repository](https://github.com/projf/display_controller) documents Verilog VGA output and 640×480p60 at 25.2 MHz. The actual upstream [display_timings.v](https://github.com/projf/display_controller/blob/main/rtl/display_timings.v) exists. The repository is MIT licensed. Its example constraints target other boards, so the architecture correctly requires Basys3 project constraints and a pinned/audited import. The presence of HDMI-related modules in that repository does not require importing them.

## Numeric and resource reality checks

These are analytical checks, not executed RTL tests or timing measurements.

- Signed 18-bit/Q6 spans -2048 through 2047.984375 with 1/64-pixel steps; all 640×480 point coordinates and ordinary individual segment lengths fit. General subtraction needs 19 bits; a pair of such operands needs 38 product bits and a two-product sum needs 39. AD-3 explicitly warns that downstream wider comparisons retain their precision. See T1 for total length.
- [AMD DSP48E1 documentation](https://docs.amd.com/r/2024.1-English/ug953-vivado-7series-libraries/DSP48E1) identifies a 25-bit multiplier A operand and an 18-bit B operand. An 18×18 multiply fits; a general 19×19 multiply does not fit one multiplier unchanged. The spine correctly calls for shared multicycle arithmetic and wider intermediates rather than claiming one-DSP complete contact kernels.
- Two 640×480 one-bit banks total 614400 bits = 75 KiB. Against 1800 Kibit = 225 KiB raw BRAM, that is one third before packing and other storage. One 12-bit frame is 450 KiB; two two-bit banks total 150 KiB. The spine's corrected arithmetic is sound. Actual allocation, fonts, contact records and LUT use remain unproved.
- A 4096×18 table contains 73728 bits = 9 KiB. [Project F's sine-table reference](https://projectf.io/posts/fpga-sine-table/) supports lookup rotation and quarter-wave alternatives; it supplies SystemVerilog examples rather than certifying this project's exact table or binary point. The architecture treats its phase/coefficient scales, approximation error and source pin as unresolved, correctly.
- 100 MHz/60 is 1666666⅔ cycles. A rational enable schedule can alternate bounded integer intervals without adding a clock domain. 25.2 MHz scanout has a 39.68 ns pixel period; shared sequential capsule kernels cannot simply be reused per pixel across all geometry. A bounded rasterizer plus complete framebuffer ownership remains a credible candidate, with throughput proof deferred.
- Primitive counts agree: 35 ball–stroke pairs, 8 ball–static pairs, 10×49=490 inter-stroke pairs and 35×8=280 stroke–static pairs total 813, excluding walls. Admission before the fifth accepted stroke adds 7+4×49+7×8=259. Two full substep scans give 1626. These are candidate counts, not cycle cost or solver iteration proofs.

## Committed decision evidence and provisional boundaries

| Decisions | Reality-check basis | Result and remaining boundary |
| --- | --- | --- |
| AD-1/2: ownership and bounded scene | PRD/addendum reconciliation; finite object/capsule counts checked above | Supported project design decisions; not imported engine facts. Eight-point resource acceptance remains gated. |
| AD-3: geometry and shared units | Numeric range/width analysis above; AMD operand constraints | Supported; T1 clarification is confirmed addressed. No universal mass/impulse scale is asserted. |
| AD-4/5/6: admission, attempt transitions and goal | PRD semantics; transaction/ownership derivation; widened goal expression | Internally consistent feature contracts. Exact interface packing/cancellation implementation is explicitly due before dependent RTL. Pending pause-drag gesture remains a coaching question. |
| AD-7: wire approximation, transform authority and solver | [Box2D simulation documentation](https://box2d.org/documentation/md_simulation.html); [Catto's original sequential-impulse presentation](https://box2d.org/files/ErinCatto_SequentialImpulses_GDC2006.pdf), especially pp. 24–32 | Fixed iteration sweeps, angular response and accumulated/Coulomb-clamped impulses have primary algorithm support. Wire mass is a deliberate project approximation. No software-engine dependency or FPGA performance is implied. |
| AD-8: fixed 60 Hz, bounded substeps and scheduling | [Box2D fixed timestep/substep discussion](https://box2d.org/documentation/md_simulation.html); cycle/count analysis above | Algorithm family is established; exactly two substeps and chosen caps are revisitable seeds. No proof of grazing-contact completeness is asserted. |
| AD-9/10: snapshot coherence, buffer ownership, clock/reset crossings | [AMD full-handshake documentation](https://docs.amd.com/r/en-US/pg382-xpm-cdc-generator/XPM_CDC_HANDSHAKE); [7 Series UG953](https://docs.amd.com/api/khub/documents/X1vw2XtgZBe~kIsz8YrO7g/content); [Project F buffering example](https://projectf.io/posts/animated-shapes/); actual driver clock requirements | Held-data request/acknowledgement is supported. XPM is a candidate, not a chosen generic component assumed to solve bank-release safety. Actual clock networks, reset release and constraints remain gates; no single-MMCM feasibility claim is made. |
| AD-11/12: adapters, versions, imports and acceptance | Actual local files/hashes/XPR/XDC plus AMD/Digilent/Project F sources above | Supported. Candidate pinning is honestly required before import. Driver presence does not imply integration. |
| Continuous simplification seed | [PostGIS ST_SimplifyVW primary documentation](https://postgis.net/docs/ST_SimplifyVW.html) | Endpoint-preserving area-based reduction exists, but neither a bounded streaming RTL algorithm nor preservation of arbitrary topology follows from that reference. Spine correctly leaves exact algorithm/thresholds unresolved. |

The full framebuffer strategy, exact sine table, two-substep seed, simplifier details, feedback duration, font/raster schedule, clock primitives, math/CDC imports, kernel constants and contact caps are expressly provisional or deferred. They should not be promoted to measured commitments by a story without completing their stated gates.

**Blocking technical gaps:** None identified at feature architecture altitude. The prototype gates remain required work: full 60 Hz worst-case admission/physics deadline, overflow/error bounds, aggregate implementation resources, frame throughput and latency, and physical peripheral operation. Those results cannot be inferred from this source review.
