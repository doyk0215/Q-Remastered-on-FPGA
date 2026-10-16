`timescale 1ns / 1ps
`default_nettype none
`include "q_contract.vh"
`include "q_geometry_params.vh"

module q_top (
    input wire clk_100mhz,
    inout wire ps2_clk,
    inout wire ps2_data,
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue,
    output wire vga_hsync,
    output wire vga_vsync,
    output wire [15:0] led,
    output wire oled_cs,
    output wire oled_mosi,
    output wire oled_sck,
    output wire oled_dc,
    output wire oled_resn,
    output wire oled_vccen,
    output wire oled_pmoden
);
    wire clk, clk_pix, clk_oled, rst, rst_pix, rst_oled;
    q_clock_reset u_clocks (
        .clk_100mhz(clk_100mhz), .clk(clk), .clk_pix(clk_pix),
        .clk_oled(clk_oled), .rst(rst), .rst_pix(rst_pix), .rst_oled(rst_oled)
    );

    // The foundation consumes every sample without producing game actions.
    wire mouse_sample_valid;
    wire [`Q_MOUSE_W-1:0] mouse_sample_data;
    wire [`Q_FAULT_W-1:0] mouse_faults;
    q_mouse_adapter u_input (
        .clk(clk), .rst(rst), .ps2_clk(ps2_clk), .ps2_data(ps2_data),
        .mouse_sample_valid(mouse_sample_valid), .mouse_sample_ready(1'b1),
        .mouse_sample_data(mouse_sample_data), .fault_flags(mouse_faults)
    );

    wire signed [15:0] sx, sy;
    wire frame, display_enable;
    q_vga_timing u_video (
        .clk_pix(clk_pix), .rst_pix(rst_pix), .sx(sx), .sy(sy), .frame(frame),
        .display_enable(display_enable), .hsync(vga_hsync), .vsync(vga_vsync)
    );
    wire [11:0] rgb = (display_enable && !rst_pix) ? `Q_BACKGROUND_RGB444 : 12'h000;
    assign {vga_red, vga_green, vga_blue} = rgb;
    assign led = 16'h0000;

    wire pixel_request, oled_frame_begin, oled_sending_pixels;
    wire [12:0] pixel_index;
    q_oled_adapter u_display (
        .clk_oled(clk_oled), .rst_oled(rst_oled), .pixel_request(pixel_request),
        .pixel_index(pixel_index), .pixel_data(16'h0000),
        .frame_begin(oled_frame_begin), .sending_pixels(oled_sending_pixels),
        .oled_cs(oled_cs), .oled_mosi(oled_mosi), .oled_sck(oled_sck),
        .oled_dc(oled_dc), .oled_resn(oled_resn),
        .oled_vccen(oled_vccen), .oled_pmoden(oled_pmoden)
    );
endmodule
`default_nettype wire
