# Module Contracts — Interface Revision 2

Derived from the cumulative specification log and architecture AD-1..AD-12. The published declarations are [q_contract.vh](../../../rtl/include/q_contract.vh) and [q_ports.vh](../../../rtl/include/q_ports.vh). All participants include these files with `rtl/include` on the Verilog include path. They are the single source for wire widths, offsets, encodings and port names. [q_geometry_params.vh](../../../rtl/include/q_geometry_params.vh) supplies the initial ball/stroke dimensions, fixed-geometry minimum and RGB444 colours. [q_physics_params.vh](../../../rtl/include/q_physics_params.vh) publishes rational initial gravity/contact/mass settings and integer substep/motion limits (physics profile revision 1); [geometry-profile.md](geometry-profile.md) records the user reference and proportion calculation.

This publishes G-1's declaration portion. It does not establish consuming-module behavior, CDC logic or hardware timing.

## Language and record representation

- Use Verilog-2001-compatible packed vectors and ANSI ports. Reused supplied HDL in other languages stays behind adapters.
- Record fields are packed from bit zero upward in the header's listed order. Nested array element zero occupies the lowest bits; index only the active count. Zero unused geometry fields/slots. Non-geometry sentinels use their explicit enums.
- Geometry slices are signed 18-bit two's complement with six fractional bits; enclosing record buses are unsigned. Extract with an explicit signed conversion. Extend integer cursor coordinates to 18 bits before shifting left by six.
- Geometry applies to world/local positions, radii, bounded per-segment lengths and linear velocity in pixels per 1/60-second outer update. Wider accumulated path lengths, moments, intermediate arithmetic and physics-only scales remain G-3 work.
- A visible provisional stroke uses 2..8 ordered vertices with at least two distinct points and the positive shared radius; while held it may be shorter than 16 pixels. With one distinct point show the cursor alone. Final admission requires total sampled-polyline length at least 16 pixels (Q6=1024); shorter releases or fewer than two distinct vertices return REJECTED/DEGENERATE without body/impulse/allowance charge. Input and physics share Q_STROKE_MIN_LENGTH_PIX/Q6. This provisional-versus-final clarification was explicitly approved by the user on 2026-10-17; packed record revision 2 is unchanged. Snapshot stroke slots beyond stroke_count have count zero; body i+1 is stroke slot i.
- Internal stage keys 0/1/2 display as Stages 1/2/3. Stage value3 means no stage. Body0 is the ball, bodies1..5 are strokes, body7 is invalid.
- Every request/world/UI/view/frame/feedback identifier is unsigned32 bits. The distinct counters are not interchangeable. Zero denotes unissued requests/frames/feedback; boot attempt/world revision zero denotes the empty lobby.

Example extraction after selecting a point using the header's array offset:

```verilog
wire signed [`Q_GEOM_W-1:0] point_x =
    $signed(point_data[`Q_POINT_X_LSB +: `Q_GEOM_W]);
```

[AMD UG901 for Vivado2025.2](https://docs.amd.com/r/2025.2-English/ug901-vivado-synthesis/Variable-Part-Selects-Verilog-Coding-Example) documents the indexed part-select syntax used here.

## Record catalog

Offsets, member widths and nested element helpers are in q_contract.vh; this catalog summarizes their purpose/shape.

| Width macro | Bits | Fields in increasing bit order |
| --- | ---: | --- |
| `Q_POINT_W` | 36 | x, y |
| `Q_CAPSULE_W` | 90 | a, b, radius |
| `Q_STROKE_W` | 310 | count, radius, points |
| `Q_BALL_W` | 54 | center, radius |
| `Q_MOUSE_W` | 22 | x, y, left, right, middle |
| `Q_CURSOR_W` | 21 | x, y, visible, left_held |
| `Q_PREVIEW_W` | 332 | cursor, active, stroke |
| `Q_INPUT_ACTION_W` | 380 | attempt, view, action, stage, stroke |
| `Q_CREATE_REQ_W` | 374 | attempt, request, stroke |
| `Q_CREATE_RSP_W` | 104 | attempt, request, result, reason, body, world_rev |
| `Q_CTRL_REQ_W` | 69 | attempt, request, op, stage |
| `Q_CTRL_RSP_W` | 104 | attempt, request, op, result, reason, world_rev |
| `Q_GOAL_W` | 64 | attempt, world_rev |
| `Q_WORLD_W` | 2407 | attempt, world_rev, has_world, stage, ball, stroke_count, strokes, obstacle_count, obstacles, goal_stopped, faults |
| `Q_UI_W` | 506 | attempt, required_world_rev, ui_rev, view, feedback_id, mode, stage, strokes_left, focus, feedback, cursor, preview_active, preview |
| `Q_STATUS_W` | 82 | attempt, ui_rev, mode, stage, strokes_left, feedback, faults |
| `Q_LEVEL_W` | 817 | stage, stage_valid, ball, ball_vx, ball_vy, obstacle_count, obstacles |
| `Q_FRAME_W` | 626 | frame_id, bank, world_rev, ui, ball, has_ball |
| `Q_FRAME_ACK_W` | 196 | attempt, frame_id, world_rev, ui_rev, view, feedback_id, disposition, released_valid, released_bank |
| `Q_EPOCH_W` | 32 | attempt |

The level-request payload is the two-bit stage key. LevelData retains initial ball linear velocity fields; each MVP stage supplies ball_vx=0 and ball_vy=0, with zero initial spin. Place the ball at rest on a fixed support platform, without initial penetration or goal contact; support comes from normal contact response while gravity remains active. Use the shared ball radius 12 pixels/Q6=768 and stroke radius 8 pixels/Q6=512. Fixed capsule radii must be at least 8 pixels/Q6=512, with that radius as the default in q_geometry_params.vh (geometry profile revision 3). Stage coordinates, support lengths and any thicker radii remain to be selected.

## Owners and identifiers

| Item | Sole owner | Lifecycle |
| --- | --- | --- |
| Provisional samples/gesture | Input | Clear/replace after admission result or attempt cancellation. |
| Attempt, control/create request IDs, game mode/allowance | Controller | Allocate new attempt for load/reset/discard; never charge an unmatched or already-accounted create. |
| World revision and body IDs | Physics | Increment world revision on committed load/admission/pause/resume/outer update; retain the goal's exact frozen revision. |
| UI revision, view and feedback IDs | Controller | UI revision changes on presentation updates; view changes on mode/layout, not each physics tick. Feedback ID identifies a particular visible message. |
| Frame ID and back-bank drawing | Renderer | Allocate each completed submission; reuse memory only after ownership transfer completes. |
| Presented identity/front bank | Scanout | Publish actual presentation and safe-bank-release metadata. |
| Stage ROM | Level owner | Immutable stage definitions; one lookup outstanding. |
| OLED text/LED mapping | Status adapter | Consume coherent status; never mutate controller state. |
| Physical definitions and build manifest | Integration | Every dependent module uses this revision and common declarations. |

Compare world revisions unsigned only within the same attempt. Do not wrap counters or reuse live pairs. On exhaustion, quiesce allocation and expose COUNTER_EXHAUSTED through the independent sticky fault_flags level; never silently wrap. Rebase only after all commands/results/mailboxes, retained snapshots and displayed identities are drained/invalidated under a coordinated startup/protocol reset. A stage reset alone does not authorize reuse of an old live pair.

## Same-clock channels

All channels below run on the100MHz core rising edge with active-high synchronous rst. Port macros expose valid, ready and packed data, with directions selected by role.

| Signal stem | Payload width | Source / sink macro |
| --- | --- | --- |
| `mouse_sample` | `Q_MOUSE_W` | `Q_MOUSE_SOURCE_PORTS` / `Q_MOUSE_SINK_PORTS` |
| `input_action` | `Q_INPUT_ACTION_W` | `Q_INPUT_ACTION_SOURCE_PORTS` / `Q_INPUT_ACTION_SINK_PORTS` |
| `input_preview` | `Q_PREVIEW_W` | `Q_INPUT_PREVIEW_SOURCE_PORTS` / `Q_INPUT_PREVIEW_SINK_PORTS` |
| `create_req` | `Q_CREATE_REQ_W` | `Q_CREATE_REQ_SOURCE_PORTS` / `Q_CREATE_REQ_SINK_PORTS` |
| `create_rsp` | `Q_CREATE_RSP_W` | `Q_CREATE_RSP_SOURCE_PORTS` / `Q_CREATE_RSP_SINK_PORTS` |
| `ctrl_req` | `Q_CTRL_REQ_W` | `Q_CTRL_REQ_SOURCE_PORTS` / `Q_CTRL_REQ_SINK_PORTS` |
| `ctrl_rsp` | `Q_CTRL_RSP_W` | `Q_CTRL_RSP_SOURCE_PORTS` / `Q_CTRL_RSP_SINK_PORTS` |
| `goal` | `Q_GOAL_W` | `Q_GOAL_SOURCE_PORTS` / `Q_GOAL_SINK_PORTS` |
| `world` | `Q_WORLD_W` | `Q_WORLD_SOURCE_PORTS` / `Q_WORLD_SINK_PORTS` |
| `ui` | `Q_UI_W` | `Q_UI_SOURCE_PORTS` / `Q_UI_SINK_PORTS` |
| `status` | `Q_STATUS_W` | `Q_STATUS_SOURCE_PORTS` / `Q_STATUS_SINK_PORTS` |
| `level_req` | `Q_LEVEL_REQ_W` | `Q_LEVEL_REQ_SOURCE_PORTS` / `Q_LEVEL_REQ_SINK_PORTS` |
| `level_rsp` | `Q_LEVEL_W` | `Q_LEVEL_RSP_SOURCE_PORTS` / `Q_LEVEL_RSP_SINK_PORTS` |

- Transfer exactly on an edge where rst=0, valid=1 and ready=1. Source asserts valid independently of ready, holds data/valid while stalled, and retires the transferred beat once. A receiver may assert ready before valid.
- Receipt means the receiver captured the immutable request; response means the operation finished. Match and consume the response separately. No timer-based completion or automatic retry after receipt.
- Receiver deasserts the relevant request-ready while that channel has an outstanding request/response. Create and control are separate slots: one outstanding per channel is allowed concurrently. Control-ready must not depend on create arithmetic being idle.
- A response remains stable until its ready transfer. Retain the most recent terminal response per channel for replay of that same identity without mutation. Older request IDs return STALE; do not accept a duplicate while its original response slot is occupied. Replayed results never debit allowance again.
- Source cannot replace a stalled record, including during an ordinary stage reset. Drain/discard stale transfers by identity. Startup/protocol reset may clear transports only when coordinated as specified below.
- Mouse adapter buffers button transitions and reports overflow using fault_flags rather than silently overwriting reliable actions. Input action/release is reliable; preview/world/UI visual updates may coalesce only before a record is exposed as stalled valid.
- Invalid stage lookup returns LevelData with stage_valid=0 and the requested stage echoed, with geometry cleared. It must not wait forever for an invalid key.
- The status channel is a core-domain record for LED/status processing. Crossing to OLED uses the separate mailbox below.
- Normal LEDs use bit0 for Paused and bit1 for Victory; other bits are off unless a diagnostic mapping is later adopted. Status text/objective strings are selected from mode/stage/feedback enums, not passed as pointers.

The ready/valid convention follows familiar [AMD handshake rules](https://docs.amd.com/r/en-US/pg101-axi-protocol-checker/AXI-Protocol-Checks-and-Descriptions); these are project channels, not an AXI implementation.

## Input and control arbitration

| Condition | Required outcome |
| --- | --- |
| Left held during a draw | Pause unavailable; discard requests and do not queue them. |
| Drawing release, including over pause icon | Submit the final stroke only; no automatic pause. |
| Fresh UI press/release inside the same current control | Activate once on release; consume gesture so it cannot draw. |
| Valid pause received while admission already executes | Finish that atomic admission, publish its result, then freeze before further integration. |
| Pause and not-yet-started create both transfer on the same edge | Capture pause; create receives CANCELLED without insertion/charge; freeze. Do not respond to a request that did not transfer. |
| New-attempt load/reset/discard | Supersede uncommitted old work, drain old reliable results, commit the new world/empty lobby and return completion with its revision. |
| Current goal already latched | Freeze the winning world; cancel uncommitted creation; goal takes precedence over valid pause/resume. A new-attempt load/reset/discard can subsequently replace the stopped attempt. |
| No higher-priority transition | Process create/resume and integration in a deterministic schedule, with complete snapshots only. |

LOAD_STAGE/RESET_STAGE/DISCARD carry the controller's new target attempt. LOAD/RESET require a valid stage key; RESET restores that selected stage's initial data. DISCARD uses Q_STAGE_NONE. PAUSE/RESUME require the current attempt and use Q_STAGE_NONE in their unused stage field. Non-stage-selection input actions also use Q_STAGE_NONE; non-create actions zero the stroke payload.

Create OK returns a body1..5, reasonNONE and its committed world revision. Any other create result returns BODY_INVALID and no allowance debit. Cancellation/staleness does not insert or apply impulses. For stale attempts, revision zero is ignored; do not attach a new attempt's current revision to an old result.

## World/UI consistency

WorldSnapshot carries complete transformed geometry. HAS_WORLD=0 means the empty lobby; consumers do not inspect its ball/stroke geometry. GoalEvent is a reliable separate channel and its frozen world remains available until controller acknowledgement and presentation ownership requirements are satisfied.

UIState joins only a same-attempt complete world with world_revision >= required_world_revision. UI/world sequence numbers are independent; do not require equality. After admission, do not combine a new allowance/cleared preview with a world older than the admission barrier. Paused/Victory/Lobby UI changes can reuse retained frozen world/background. Input uses the actually presented attempt/view and rejects stale menu actions; ordinary body motion does not create a new clickable view.

Feedback lifetime starts on presentation of the matching frame/feedback identity, not on data receipt. Reset/stage change clears it. Rendering follows the adopted layer priority and uses one shared hit-region/font definition when G-4 publishes it.

## Cross-clock mailboxes

q_ports.vh exposes FRAME, EPOCH and OLED_STATUS mailbox source/sink macros. These use req/data and ack/ack_data, not core ready/valid. Synchronizers, constraints and reset logic are still implementation requirements.

| Mailbox | Source → destination | Payload / acknowledgement |
| --- | --- | --- |
| Frame | 100MHz renderer →25.2MHz scanout | FramePacket / FrameAcknowledgement |
| Epoch | 100MHz controller/integration →25.2MHz scanout | EpochPacket / echoed EpochPacket |
| OLED status | 100MHz status source →6.25MHz adapter | StatusState / echoed latched StatusState |

1. Source holds data then raises req. Data remains stable until the entire handshake returns idle.
2. Destination observes synchronized req, captures held data and commits or rejects the operation at its safe point. It holds ack_data stable and raises ack.
3. Source observes synchronized ack, captures ack_data once and lowers req. It still holds data.
4. Destination observes synchronized req low and lowers ack. Source observes synchronized ack low before another send or storage reuse.

Only handshake controls are individually synchronized; coherent data/ack_data buses rely on the held-data protocol and appropriate implementation constraints. No bare pulse or independently synchronized payload bits can substitute. Capture/wait timing and synchronizer stages belong to G-2/G-5.

Frame acceptance requires a current-epoch complete bank and matched overlay metadata. FramePacket.ball and has_ball come from the exact world snapshot used to draw that bank. Set has_ball for a presented gameplay/paused/victory scene with a ball; clear it in the lobby. The white image banks contain strokes/obstacles/background; omit the moving ball from their white mask and composite its magenta circle before control/menu/feedback/cursor layers. Do not overlay a live/newer physics ball on an older bank. At a safe frame boundary, swap and retire the old read pipeline before acknowledging a valid released_bank. The presented acknowledgement echoes actual frame/UI/view/world/feedback identities. A dropped frame returns a dropped disposition and released_valid=0: the front bank is unchanged, and the submitted back bank becomes reusable only after the full handshake is idle. Merely receiving metadata never releases memory.

Apply an epoch change at a safe frame boundary, with priority over frame swap; blank old-attempt output until a matching complete frame is available. Drain stale frame requests with a dropped acknowledgement. Core publishes a new attempt's frame only after that desired epoch handshake is acknowledged and idle. Coalesce newer desired epochs in a source-owned pending slot without overwriting an in-flight mailbox.

The OLED adapter latches the complete status at a safe driver frame boundary before acknowledging; meet the supplied negedge pixel timing. Pixel timing details remain G-2 work.

## Startup and stage reset

Startup/protocol reset establishes req=ack=0 in every mailbox, no live valid beat, front bank0 invalid, and renderer ownership of bank1. Keep scanout black until its first valid completed frame. Empty boot attempt/world revision zero supports the lobby with stageNONE; initialize mouse bounds/cursor explicitly.

Stage reset is an ordinary new-attempt command; do not reset clock generators, mouse/OLED drivers or one side of an active mailbox. Quiesce/cancel by identity and complete outstanding ownership handshakes. A real protocol reset requires coordinated peer reset/transport reinitialization and frame invalidation, not unilateral dropping of valid/req.

## Using the declarations

Use Q_CORE_PORTS (or Q_PIXEL_PORTS/Q_OLED_PORTS in their domains), then compose the appropriate source/sink macros in the module's ANSI port list with commas between macros. A physics module consumes CREATE_REQ/CTRL_REQ, produces CREATE_RSP/CTRL_RSP/GOAL/WORLD and exposes the independent Q_FAULT_SOURCE_PORTS diagnostic level. Its mass/trigonometric/contact internals are not part of these ports.

## Capability mapping

| Capability | Primary owner(s) | Binding architecture |
| --- | --- | --- |
| CAP-1: launch | Controller, input, levels | AD-1/2/5/9/11 |
| CAP-2: pause/resume | Controller, input, physics | AD-1/5/8/9 |
| CAP-3: reset/lobby | Controller, physics | AD-5/9/10/12 |
| CAP-4: drawing | Input, graphics | AD-2/3/4/9 |
| CAP-5: admission | Physics, controller | AD-3/4/5/7 |
| CAP-6: allowance | Controller, status | AD-1/2/4/9 |
| CAP-7: motion | Physics | AD-3/7/8 |
| CAP-8: collisions | Physics | AD-2/3/7/8 |
| CAP-9: goal | Physics, controller | AD-5/6/9 |
| CAP-10: state/victory | Controller, graphics, status | AD-5/9 |
| CAP-11: VGA | Graphics, input, integration | AD-3/9/10/11 |
| CAP-12: OLED | Status, controller, integration | AD-9/10/11 |
| CAP-13: LEDs | Status, controller | AD-1/9/11 |

## Remaining gates

The32-bit IDs, Verilog-2001 packing, enum encodings, stage/body numbering, zero initial ball spin and LED mapping are revision 2 engineering choices. Change them through this shared contract and increment its revision before dependent builds diverge. The original 32-bit identity and packing choices carry forward from revision1; revision 2 adds snapshot-matched magenta ball geometry/visibility to FramePacket. Shared ball/stroke radius defaults and the fixed-capsule minimum/default radius are selected; gravity/contact arithmetic and response validation, thicker per-stage obstacle radii, internal mass/motion-limit arithmetic, exact simplifier/layout, third-party pins, CDC/reset circuits, consumer behavior and hardware fit remain prototype obligations.

