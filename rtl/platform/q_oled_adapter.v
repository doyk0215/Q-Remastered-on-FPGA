`timescale 1ns / 1ps
`default_nettype none
`include "q_contract.vh"
`include "q_ports.vh"

// Pixel source is combinational and entirely in clk_oled's domain.
// Index/request change after a driver falling edge. Data is registered on the
// next rising edge, giving half a cycle of setup before the capture falling edge.
// Status rendering and the core-to-OLED status mailbox belong to Story 9.
module q_oled_adapter (
    `Q_OLED_PORTS,
    output wire pixel_request,
    output wire [12:0] pixel_index,
    input wire [15:0] pixel_data,
    output wire frame_begin,
    output wire sending_pixels,
    output wire oled_cs,
    output wire oled_mosi,
    output wire oled_sck,
    output wire oled_dc,
    output wire oled_resn,
    output wire oled_vccen,
    output wire oled_pmoden
);
    reg [15:0] capture_data;
    always @(posedge clk_oled) begin
        if (rst_oled) capture_data <= 16'h0000;
        else capture_data <= pixel_data;
    end
    Oled_Display #(.ClkFreq(`Q_OLED_HZ)) u_oled (
        .clk(clk_oled), .reset(rst_oled), .frame_begin(frame_begin),
        .sending_pixels(sending_pixels), .sample_pixel(pixel_request),
        .pixel_index(pixel_index), .pixel_data(capture_data),
        .cs(oled_cs), .sdin(oled_mosi), .sclk(oled_sck), .d_cn(oled_dc),
        .resn(oled_resn), .vccen(oled_vccen), .pmoden(oled_pmoden)
    );
endmodule
`default_nettype wire
