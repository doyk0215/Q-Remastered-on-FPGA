`timescale 1ns / 1ps
`default_nettype none
`include "q_contract.vh"
`include "q_ports.vh"

module q_vga_timing (
    `Q_PIXEL_PORTS,
    output wire signed [15:0] sx,
    output wire signed [15:0] sy,
    output wire frame,
    output wire display_enable,
    output wire hsync,
    output wire vsync
);
    display_timings #(
        .H_RES(`Q_SCREEN_W), .V_RES(`Q_SCREEN_H),
        .H_FP(16), .H_SYNC(96), .H_BP(48),
        .V_FP(10), .V_SYNC(2), .V_BP(33), .H_POL(0), .V_POL(0)
    ) u_timing (
        .i_pix_clk(clk_pix), .i_rst(rst_pix), .o_hs(hsync), .o_vs(vsync),
        .o_de(display_enable), .o_frame(frame), .o_sx(sx), .o_sy(sy)
    );
endmodule
`default_nettype wire
