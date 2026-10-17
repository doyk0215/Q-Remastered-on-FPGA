# Buffered renderer and frame-transfer design proposal

Prepared 2026-10-17 for G-5/R4. Status: concrete implementation design for Choon Hsiang's ownership, Doyeon's geometry/resource review and Qi-Ze's UI/epoch review. It establishes a design to build and measure, not a claim that RTL meets timing or fits after integration.

Use [module-contracts.md](module-contracts.md), [core-wiring-proposal.md](core-wiring-proposal.md), [input-ui-design-proposal.md](input-ui-design-proposal.md) and external interface revision 2. The selected framebuffer seed remains two one-bit banks plus frame-local magenta ball and UI metadata.

## Memory packing and ownership

Use 32 useful pixels per 36-bit BRAM word, LSB first. Address is `20*y + floor(x/32)`, bit is `x mod 32`, for x=0..639 and y=0..479. Each row is exactly 20 words, each bank 9600 words. Unused four bits are zero. Use ten RAMB36-equivalent 1024×36 simple/true-dual-port blocks per bank, decoding the upper address to one block; 640 unused words at the end of each bank are never addressed. Actual primitive inference/configuration must be confirmed in synthesis.

Allocate port A of each bank to the 100 MHz renderer, port B to 25.2 MHz scanout. The renderer writes only a bank it owns. It may read the front bank for an explicitly safe copy when world/preview coverage is unchanged; it never writes it. Disable unused port operations. Treat cross-port same-address read/write as prohibited by ownership, not as a selectable read-during-write mode.

| Initial allocation | RAMB36 equivalents | Allocated capacity |
| --- | ---: | ---: |
| Two monochrome banks | 20 | 90 KiB; logical image data is 75 KiB |
| One 4096×18 sine table | 2 | 9 KiB; schedule adjacent sine/cosine reads over multiple cycles rather than silently replicate ROM |
| Font/status allocation ceiling | 1 | 4.5 KiB; small assets may instead use distributed ROM |
| Reserved physics/contact/table working storage | 20 | 90 KiB; provisional allowance, not a completed contact-storage implementation |
| Unallocated integration margin | 7 | 31.5 KiB |
| Total board budget | 50 | 225 KiB |

RAMB18 use counts as half an equivalent. This budget does not reserve LUT/DSP/FF counts by assertion: the owners must measure those. If ROM port replication, solver storage or memory inference changes the allocation, update the aggregate budget before merging dependent work. Do not silently consume the margin twice.

## Exact scanline capsule rasterization

Render each of at most 35 stroke segments, eight fixed capsules and seven preview segments: at most 50 primitives. Ball geometry is omitted from the white banks. Use the published transformed Q6 endpoints/radius; evaluate coverage at pixel coordinate `(64*x,64*y)`, with inclusive capsule boundary. Preview stipple masks coverage without changing geometry.

For segment A→B, v=B-A, d=dot(v,v), the capsule is the union of two endpoint disks and the interior strip. When d=0 draw one disk. For a row Y, a disk center C contributes integer x satisfying:

```text
h = radius_q6^2 - (64*Y - Cy)^2
if h >= 0:
    k = isqrt_floor(h)
    xlo = ceil_div(Cx-k, 64)
    xhi = floor_div(Cx+k, 64)
```

The interior strip has `0 <= dot(P-A,v) <= d` and `abs(cross(P-A,v)) <= K`, with `K=isqrt_floor(radius_q6^2*d)` precomputed once. At fixed Y both dot and cross are affine functions of integer x, so solve their lower/upper linear inequalities exactly and intersect their integer x intervals. Normalize negative coefficients; a zero coefficient yields an all-row or empty constraint, never division by zero.

For signed division use mathematical floor with remainder `0 <= remainder < positive_denominator`; ceil is floor plus one if remainder is nonzero. Truncation toward zero is incorrect for negative positions. For each nonzero-coefficient strip edge, initialize its quotient/remainder once per primitive. Across rows its numerator changes by a constant. Predivide that change into quotient-step and nonnegative remainder-step, then update by addition and at most one remainder carry per row. This exact incremental edge stepping avoids four long divisions on every row.

Disk spans and strip span form at most three intervals. Clip to x=0..639, merge overlaps/adjacent spans, and write their union. Clamp the primitive's conservative row range to y=0..479. Endpoint disk square roots are evaluated only on rows intersecting that disk, not on all 480 rows. Reject malformed counts/radii and fault on arithmetic overflow; do not convert an invalid interval into a huge unsigned memory walk.

Use a word mask for each clipped span. Full words can be written directly for solid coverage; partial or stippled words use serialized read/OR/write with a two-core-cycle processing target per touched word. Consecutive updates to the same word wait for the prior write; there is no stale read/modify/write overlap. The logical OR is appropriate because these banks contain only white masks on black and are cleared before a new geometry/preview render.

### Bounded processing target

Clear exactly 9600 words. Proposed per-primitive setup target is 512 processing cycles, including wide products, K square root and edge quotient initialization. Proposed base row target is 24 bookkeeping/edge/merge cycles plus two cycles per touched word, at most 64 cycles for a full-width row. Endpoint-disk square root/setup target is 24 cycles per participating endpoint row. These are implement-and-measure bounds, not observed performance.

For 50 primitives, all with radius eight pixels and every bounding box conservatively spanning 480 rows, reserve:

```text
clear                         9600
primitive setup             50*512
base rows                50*480*64
endpoint disk rows        50*2*17*24
control/drain allowance      20480
total                     1632480 core cycles = 16.3248 ms
```

This arithmetic target is just below the shortest 60 Hz tick interval of 1666666 cycles; it is not proof of 60 Hz frame production. Thicker fixed capsules increase endpoint-disk work; use `min(480, ceil(2*r_pixels)+1)` participating rows per endpoint and the actual clipped row counts. Additional arithmetic stalls, primitive setup cost or memory latency can also invalidate the target. Measure actual worst cases and revise the schedule before claiming throughput. Physics cadence remains independent; slow rendering repeats the last complete frame and never increases a physics timestep.

If only metadata such as cursor changes and world plus rasterized preview coverage is identical, a front-to-free-back copy can reuse the mask: 9600 serialized read/write words, target 19200 cycles plus metadata. If preview geometry changed, rerasterize; copying an old stippled preview would leave ghosts. Copying still requires a genuinely free destination bank and immutable source ownership through the read pass.

## Snapshot selection and pixel composition

Retain complete WORLD and UI records in the core. Select one same-attempt pair with `world_rev >= ui.required_world_rev`, then freeze that pair throughout clear/raster/assembly. A new incoming record can coalesce only in a separate unexposed pending slot. If the current pair becomes obsolete, either finish and drop it according to protocol or cancel before exposing a frame request; never mutate a live frame.

FramePacket holds the exact world's ball/has_ball and the selected UI, with controller-owned view/feedback identity. Pixel-side UI/text/cursor/control logic is a bounded compositor using that frame-local UI, the agreed hit rectangles and a pinned bitmap font. Modal backdrop, goal marks and cursor do not change collision or goal coordinates. Preview capsule coverage is rasterized into the back mask; its radius/polyline matches the selected UI record.

Pixels use a proposed three-cycle output pipeline, with BRAM output register disabled (one synchronous memory read):

| Edge | Token and data action |
| --- | --- |
| n, S0 | Sample signed raw beam coordinates, enable/sync, selected front identity and frame-local metadata; issue the matching BRAM read when active and front valid. |
| n+1, S1 | Capture the read word, block selector and the same token's bit index, coordinates and metadata. |
| n+2, S2 | Select the monochrome bit and compute bounded ball/UI/glyph/cursor coverage for that token; register the results. |
| n+3, S3 | Register final RGB and matching delayed hsync/vsync/display-enable; force RGB black for inactive/invalid tokens. |

If actual RAM/font/compositor timing needs another stage, change one declared latency and delay every token/control consistently; do not move only RGB. No active-video address comes from negative blanking coordinates. Ball-circle arithmetic uses frame-local Q6 center/radius and exact widened squared distance at integer pixel coordinates, with inclusive boundary. The compositor must meet 39.683 ns pixel timing in synthesis/route before acceptance.

## Four-phase mailbox timing

Frame source and epoch source have one transaction each. Register held data, wait one source-clock edge, then raise req. Destination uses two ASYNC_REG control synchronizer stages, observes synchronized req and waits two additional destination edges before capturing the held multibit data. Payload bits are not synchronized independently. A real protocol reset coordinates both peers; stage reset does not clear either transport unilaterally.

At the safe raw frame boundary, apply a captured pending epoch before considering a frame swap. Tag the new pipeline tokens with the new epoch/front validity; retire all old tokens before declaring a release. With the proposed pipeline, wait at least three pixel edges after the final old token issue before releasing its bank. Commit visible epoch/presentation at the corresponding delayed output boundary so old pipeline pixels cannot reappear after the new visible boundary.

Frame ack_data is registered after commit/drop and pipeline retirement, then held for one pixel edge before raising ack. The core source synchronizes ack through two control stages, waits two extra core edges and captures the held ack_data once. It updates bank accounting and fills the reserved core presentation-event relay. It lowers req; destination later observes req low and lowers ack; source waits for synchronized ack low before reuse/new request. Data/ack_data remain stable through their full return-to-idle phase.

A dropped frame does not release the front bank (`released_valid=0`); its submitted back bank is reusable only after the mailbox is idle. A presented frame releases an old valid front only after pipeline safety; startup's invalid front is not represented as valid released storage. Epoch uses the same transport discipline and echoes the committed attempt. Core publishes a new attempt's frame only after its epoch handshake is acknowledged and idle. Frame-event relay backpressure must not stop epoch transport.

Proposed physical implementation budgets for held bundles are 20 ns core→pixel and 10 ns pixel→core, with endpoint-specific constraints and review of actual capture/storage timing. These are route targets, not external electrical measurements. Control exceptions stop at first synchronizer inputs; no blanket asynchronous clock grouping or false path on an entire payload bus is permitted. Verify path endpoint counts, bundled-data hold intervals and synchronizer placement against actual post-synthesis hierarchy. The related generated clocks and existing Story 1 findings still require review; a functional handshake description does not close CDC acceptance.

## Modules, handoff and acceptance

Proposed graphics decomposition: snapshot join/retention, capsule scanline setup, exact edge/disc span engine, word-mask writer, two-bank memory, frame-source/ack relay, pixel scanout and bounded UI compositor. Controller/integration retains desired-epoch policy; Choon Hsiang owns the transport implementation and coordinates one source FSM with Qi-Ze. Do not duplicate controller state inside graphics.

Before completion, demonstrate exact span coverage at negative/fractional/clipped coordinates, zero-length segments, tangencies and maximum radius/counts; single-writer ownership; no front writes; pipeline alignment; repeated-frame behavior; stale epoch/frame draining; safe release and event-relay backpressure. Publish actual RAM primitives/port modes, ROM initialization, frame cycles, maximum disk/strip workload, LUT/DSP/FF/BRAM totals and post-route pixel/core timing/CDC reports.

This proposal makes R4 reviewable. It does not close G-5, establish the proposed cycle bounds, validate the font or waive hardware evidence. Stories 2/6 may build reviewed isolated portions using controlled records while physical G-2 acceptance continues separately.
