# Planning reference-validation record

Date: 2026-10-17. This records preparation checks on the proposed parallel-build design. It does not certify hardware, replace the named human reviews or mark Stories 1/2/3/6 complete.

## Reproduce

From the repository root with Node available:

```sh
node scripts/planning/restore_source_bytes.mjs
node scripts/planning/validate_parallel_plan.mjs
vivado -mode batch -log build/planning_headers.log -source scripts/planning/check_headers.tcl
```

The first command repairs only newline conversions that restore the existing approved manifest hashes, after validating all sources before writing any. It refuses content modifications. The reference checker writes ignored `build/planning-validation.json` and `build/planning-reference-vectors.json`. The Vivado command only parses temporary source/sink modules expanding the proposed port/constant headers; it does not synthesize behavior, generate a bitstream or access a board.

## Results and limits

- Node v24.19.0 reference/design checks pass: 12437 assertions in the completed run, including additive draft constants and handoff links. The exact count/runtime are also printed in the generated report; later link additions can change the count.
- All fifteen approved platform source hashes match directly after guarded line-ending restoration. A fresh `git checkout-index` export of the staged tree also passed all reference checks with zero newline repairs. `.gitattributes` pins source/RTL to LF and disables conversion for the supplied master XDC, preserving its original CRLF bytes in Git and on disk. No baseline HDL or imported-source content is changed by the final staged patch. Release must still verify the final archive and a complete fresh release checkout.
- Integer square-root/RNE/reciprocal vectors, closed/backtracking/duplicate lengths and protected simplifier endpoints/counts pass the reference checks. This is a mathematical software model, not evidence that a future RTL FSM implements it correctly or meets the proposed cycle targets.
- Half-open control borders, same-view separation, selected label widths and draft header coordinates/thresholds are consistent. Actual font glyphs, readability and mouse/display usability remain implementation/board evidence.
- Exact signed incremental edge stepping matches direct division on selected negative/positive sequences. Scanline disk/strip union matches an independent direct capsule-distance predicate on the checked fractional, clipped, horizontal, vertical and zero-length examples. This does not prove every full-width hardware product or all possible coordinate/radius combinations.
- Proposed framebuffer allocation is 20 RAMB36 equivalents, with a 50-equivalent aggregate reservation. The default radius-eight arithmetic frame target is 1632480 cycles; it is not an implemented cycle count or guaranteed frame rate, and thicker obstacles need the actual extended budget.
- Rational tick arithmetic yields intervals of 1666666/1666667 cycles and 60 ticks per 100 million cycles. Busy/paused/fault behavior still needs actual implementation evidence.
- The conservative proposed two-pose transform-error envelope is about 0.085822 pixel at extent 1024, before final implementation review. The original 1/16 guard was insufficient; the revised 1/8 reserve fits the checked bound, and 27/8 integration +1/2 correction +1/8 reserve preserves the adopted four-pixel maximum. Actual coefficient generation and RTL rounding must stay within that envelope.
- Vivado 2025.2 completed `check_syntax` successfully for the draft source/sink declarations; `build/planning_headers.log` reports `Q_DRAFT_HEADERS_PARSE=PASS` with no errors. This establishes declaration syntax, not behavioral implementation. The accepted four headers remain unchanged and current application sources do not include the inactive draft headers.

## Outstanding human and hardware gates

The [start checklist](../parallel-start-checklist.md) identifies the remaining human approval, short-preview semantics and exact course-date inputs. Existing two PS/2 CDC-1 and two reset CDC-10 findings remain assigned platform work; none is waived here. Numerical range/error closure, kernel/raster cycle measurements, aggregate synthesis/route and all physical peripheral acceptance remain the implementation's proof obligations.
