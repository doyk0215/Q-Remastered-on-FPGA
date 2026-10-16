// Q Remastered on FPGA: reusable ANSI port declarations, Verilog-2001.
// Put commas BETWEEN macros when using them in a module port list.
// Source/sink ready-valid macros are SAME-CLOCK only.
// Mailbox macros need explicit held-data CDC/reset logic; they are not synchronizers.
`ifndef Q_PORTS_VH
`define Q_PORTS_VH
`include "q_contract.vh"

`define Q_CORE_PORTS \
    input wire clk , \
    input wire rst

`define Q_PIXEL_PORTS \
    input wire clk_pix , \
    input wire rst_pix

`define Q_OLED_PORTS \
    input wire clk_oled , \
    input wire rst_oled

`define Q_MOUSE_SOURCE_PORTS \
    output wire mouse_sample_valid , \
    input wire mouse_sample_ready , \
    output wire [`Q_MOUSE_W-1:0] mouse_sample_data

`define Q_MOUSE_SINK_PORTS \
    input wire mouse_sample_valid , \
    output wire mouse_sample_ready , \
    input wire [`Q_MOUSE_W-1:0] mouse_sample_data

`define Q_INPUT_ACTION_SOURCE_PORTS \
    output wire input_action_valid , \
    input wire input_action_ready , \
    output wire [`Q_INPUT_ACTION_W-1:0] input_action_data

`define Q_INPUT_ACTION_SINK_PORTS \
    input wire input_action_valid , \
    output wire input_action_ready , \
    input wire [`Q_INPUT_ACTION_W-1:0] input_action_data

`define Q_INPUT_PREVIEW_SOURCE_PORTS \
    output wire input_preview_valid , \
    input wire input_preview_ready , \
    output wire [`Q_PREVIEW_W-1:0] input_preview_data

`define Q_INPUT_PREVIEW_SINK_PORTS \
    input wire input_preview_valid , \
    output wire input_preview_ready , \
    input wire [`Q_PREVIEW_W-1:0] input_preview_data

`define Q_CREATE_REQ_SOURCE_PORTS \
    output wire create_req_valid , \
    input wire create_req_ready , \
    output wire [`Q_CREATE_REQ_W-1:0] create_req_data

`define Q_CREATE_REQ_SINK_PORTS \
    input wire create_req_valid , \
    output wire create_req_ready , \
    input wire [`Q_CREATE_REQ_W-1:0] create_req_data

`define Q_CREATE_RSP_SOURCE_PORTS \
    output wire create_rsp_valid , \
    input wire create_rsp_ready , \
    output wire [`Q_CREATE_RSP_W-1:0] create_rsp_data

`define Q_CREATE_RSP_SINK_PORTS \
    input wire create_rsp_valid , \
    output wire create_rsp_ready , \
    input wire [`Q_CREATE_RSP_W-1:0] create_rsp_data

`define Q_CTRL_REQ_SOURCE_PORTS \
    output wire ctrl_req_valid , \
    input wire ctrl_req_ready , \
    output wire [`Q_CTRL_REQ_W-1:0] ctrl_req_data

`define Q_CTRL_REQ_SINK_PORTS \
    input wire ctrl_req_valid , \
    output wire ctrl_req_ready , \
    input wire [`Q_CTRL_REQ_W-1:0] ctrl_req_data

`define Q_CTRL_RSP_SOURCE_PORTS \
    output wire ctrl_rsp_valid , \
    input wire ctrl_rsp_ready , \
    output wire [`Q_CTRL_RSP_W-1:0] ctrl_rsp_data

`define Q_CTRL_RSP_SINK_PORTS \
    input wire ctrl_rsp_valid , \
    output wire ctrl_rsp_ready , \
    input wire [`Q_CTRL_RSP_W-1:0] ctrl_rsp_data

`define Q_GOAL_SOURCE_PORTS \
    output wire goal_valid , \
    input wire goal_ready , \
    output wire [`Q_GOAL_W-1:0] goal_data

`define Q_GOAL_SINK_PORTS \
    input wire goal_valid , \
    output wire goal_ready , \
    input wire [`Q_GOAL_W-1:0] goal_data

`define Q_WORLD_SOURCE_PORTS \
    output wire world_valid , \
    input wire world_ready , \
    output wire [`Q_WORLD_W-1:0] world_data

`define Q_WORLD_SINK_PORTS \
    input wire world_valid , \
    output wire world_ready , \
    input wire [`Q_WORLD_W-1:0] world_data

`define Q_UI_SOURCE_PORTS \
    output wire ui_valid , \
    input wire ui_ready , \
    output wire [`Q_UI_W-1:0] ui_data

`define Q_UI_SINK_PORTS \
    input wire ui_valid , \
    output wire ui_ready , \
    input wire [`Q_UI_W-1:0] ui_data

`define Q_STATUS_SOURCE_PORTS \
    output wire status_valid , \
    input wire status_ready , \
    output wire [`Q_STATUS_W-1:0] status_data

`define Q_STATUS_SINK_PORTS \
    input wire status_valid , \
    output wire status_ready , \
    input wire [`Q_STATUS_W-1:0] status_data

`define Q_LEVEL_REQ_SOURCE_PORTS \
    output wire level_req_valid , \
    input wire level_req_ready , \
    output wire [`Q_LEVEL_REQ_W-1:0] level_req_data

`define Q_LEVEL_REQ_SINK_PORTS \
    input wire level_req_valid , \
    output wire level_req_ready , \
    input wire [`Q_LEVEL_REQ_W-1:0] level_req_data

`define Q_LEVEL_RSP_SOURCE_PORTS \
    output wire level_rsp_valid , \
    input wire level_rsp_ready , \
    output wire [`Q_LEVEL_W-1:0] level_rsp_data

`define Q_LEVEL_RSP_SINK_PORTS \
    input wire level_rsp_valid , \
    output wire level_rsp_ready , \
    input wire [`Q_LEVEL_W-1:0] level_rsp_data

`define Q_FRAME_MAILBOX_SOURCE_PORTS \
    output wire frame_req , \
    output wire [`Q_FRAME_W-1:0] frame_data , \
    input wire frame_ack , \
    input wire [`Q_FRAME_ACK_W-1:0] frame_ack_data

`define Q_FRAME_MAILBOX_SINK_PORTS \
    input wire frame_req , \
    input wire [`Q_FRAME_W-1:0] frame_data , \
    output wire frame_ack , \
    output wire [`Q_FRAME_ACK_W-1:0] frame_ack_data

`define Q_EPOCH_MAILBOX_SOURCE_PORTS \
    output wire epoch_req , \
    output wire [`Q_EPOCH_W-1:0] epoch_data , \
    input wire epoch_ack , \
    input wire [`Q_EPOCH_W-1:0] epoch_ack_data

`define Q_EPOCH_MAILBOX_SINK_PORTS \
    input wire epoch_req , \
    input wire [`Q_EPOCH_W-1:0] epoch_data , \
    output wire epoch_ack , \
    output wire [`Q_EPOCH_W-1:0] epoch_ack_data

`define Q_OLED_STATUS_MAILBOX_SOURCE_PORTS \
    output wire oled_status_req , \
    output wire [`Q_STATUS_W-1:0] oled_status_data , \
    input wire oled_status_ack , \
    input wire [`Q_STATUS_W-1:0] oled_status_ack_data

`define Q_OLED_STATUS_MAILBOX_SINK_PORTS \
    input wire oled_status_req , \
    input wire [`Q_STATUS_W-1:0] oled_status_data , \
    output wire oled_status_ack , \
    output wire [`Q_STATUS_W-1:0] oled_status_ack_data

// Sticky diagnostic level is independent of versioned message counters.
`define Q_FAULT_SOURCE_PORTS \
    output wire [`Q_FAULT_W-1:0] fault_flags

`endif // Q_PORTS_VH

