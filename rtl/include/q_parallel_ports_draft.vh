// Initial parallel-build interfaces adopted by the user on 2026-10-17.
// Draft filename retained for stable links; runtime verification is pending.
// No current application source includes this header. Existing public records
// remain revision 2. These additive private/core ports use those record types.
`ifndef Q_PARALLEL_PORTS_DRAFT_VH
`define Q_PARALLEL_PORTS_DRAFT_VH
`include "q_contract.vh"
`define Q_PARALLEL_PORTS_DRAFT_REV 16'h0001

`define Q_DRAFT_PRESENTATION_EVENT_SOURCE_PORTS \
    output wire presentation_event_valid, \
    input wire presentation_event_ready, \
    output wire [`Q_FRAME_ACK_W-1:0] presentation_event_data
`define Q_DRAFT_PRESENTATION_EVENT_SINK_PORTS \
    input wire presentation_event_valid, \
    output wire presentation_event_ready, \
    input wire [`Q_FRAME_ACK_W-1:0] presentation_event_data

`define Q_DRAFT_INPUT_CONTEXT_SOURCE_PORTS \
    output wire [`Q_ID_W-1:0] ctx_attempt, \
    output wire [`Q_ID_W-1:0] ctx_view, \
    output wire [`Q_MODE_W-1:0] ctx_mode, \
    output wire [`Q_STAGE_W-1:0] ctx_stage, \
    output wire ctx_presented_valid, \
    output wire [`Q_ACCEPTED_COUNT_W-1:0] ctx_strokes_left, \
    output wire ctx_create_pending, \
    output wire ctx_draw_enabled
`define Q_DRAFT_INPUT_CONTEXT_SINK_PORTS \
    input wire [`Q_ID_W-1:0] ctx_attempt, \
    input wire [`Q_ID_W-1:0] ctx_view, \
    input wire [`Q_MODE_W-1:0] ctx_mode, \
    input wire [`Q_STAGE_W-1:0] ctx_stage, \
    input wire ctx_presented_valid, \
    input wire [`Q_ACCEPTED_COUNT_W-1:0] ctx_strokes_left, \
    input wire ctx_create_pending, \
    input wire ctx_draw_enabled

`define Q_DRAFT_DRAW_RETIRE_SOURCE_PORTS \
    output wire draw_retire_valid, \
    input wire draw_retire_ready, \
    output wire [`Q_ID_W-1:0] draw_retire_attempt, \
    output wire [`Q_RESULT_W-1:0] draw_retire_result, \
    output wire [`Q_REASON_W-1:0] draw_retire_reason
`define Q_DRAFT_DRAW_RETIRE_SINK_PORTS \
    input wire draw_retire_valid, \
    output wire draw_retire_ready, \
    input wire [`Q_ID_W-1:0] draw_retire_attempt, \
    input wire [`Q_RESULT_W-1:0] draw_retire_result, \
    input wire [`Q_REASON_W-1:0] draw_retire_reason

`define Q_DRAFT_BLOCKED_DRAW_SOURCE_PORTS \
    output wire blocked_draw_valid, \
    input wire blocked_draw_ready, \
    output wire [`Q_ID_W-1:0] blocked_draw_attempt, \
    output wire [`Q_ID_W-1:0] blocked_draw_view
`define Q_DRAFT_BLOCKED_DRAW_SINK_PORTS \
    input wire blocked_draw_valid, \
    output wire blocked_draw_ready, \
    input wire [`Q_ID_W-1:0] blocked_draw_attempt, \
    input wire [`Q_ID_W-1:0] blocked_draw_view

`define Q_DRAFT_PATH_LENGTH_REQ_SOURCE_PORTS \
    output wire length_req_valid, \
    input wire length_req_ready, \
    output wire [`Q_STROKE_W-1:0] length_req_stroke
`define Q_DRAFT_PATH_LENGTH_REQ_SINK_PORTS \
    input wire length_req_valid, \
    output wire length_req_ready, \
    input wire [`Q_STROKE_W-1:0] length_req_stroke
`define Q_DRAFT_PATH_LENGTH_RSP_SOURCE_PORTS \
    output wire length_rsp_valid, \
    input wire length_rsp_ready, \
    output wire [23:0] length_rsp_total_q6, \
    output wire length_rsp_two_distinct, \
    output wire length_rsp_bad_payload
`define Q_DRAFT_PATH_LENGTH_RSP_SINK_PORTS \
    input wire length_rsp_valid, \
    output wire length_rsp_ready, \
    input wire [23:0] length_rsp_total_q6, \
    input wire length_rsp_two_distinct, \
    input wire length_rsp_bad_payload
`endif
