`timescale 1ns / 1ps
`default_nettype none

// Peripheral/startup reset only: stage reset must never reach this module.
module q_clock_reset (
    input wire clk_100mhz,
    output wire clk,
    output wire clk_pix,
    output wire clk_oled,
    output wire rst,
    output wire rst_pix,
    output wire rst_oled
);
    wire clk_input;
    IBUF u_clk_input (.I(clk_100mhz), .O(clk_input));
    BUFG u_core_clock (.I(clk_input), .O(clk));

    wire pixel_locked, oled_locked;
    reg manager_reset = 1'b1;
    reg [4:0] restart_count = 5'd16;
    reg pixel_seen_locked = 1'b0;
    reg oled_seen_locked = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg [1:0] pixel_lock_sync = 2'b00;
    (* ASYNC_REG = "TRUE" *) reg [1:0] oled_lock_sync = 2'b00;

    q_clk_pixel u_pixel_clock (
        .clk_in1(clk), .reset(manager_reset),
        .clk_out1(clk_pix), .locked(pixel_locked)
    );
    q_clk_oled u_oled_clock (
        .clk_in1(clk), .reset(manager_reset),
        .clk_out1(clk_oled), .locked(oled_locked)
    );

    // Runs from the board clock even while a generated clock is stopped.
    // Remember each manager independently: loss after a partial startup must
    // also restart both managers, even if the other manager never locked.
    always @(posedge clk) begin
        pixel_lock_sync <= {pixel_lock_sync[0], pixel_locked};
        oled_lock_sync <= {oled_lock_sync[0], oled_locked};
        if (restart_count != 0) begin
            restart_count <= restart_count - 1'b1;
            manager_reset <= 1'b1;
            pixel_seen_locked <= 1'b0;
            oled_seen_locked <= 1'b0;
        end else begin
            manager_reset <= 1'b0;
            if ((pixel_seen_locked && !pixel_lock_sync[1]) ||
                (oled_seen_locked && !oled_lock_sync[1])) begin
                restart_count <= 5'd15;
                manager_reset <= 1'b1;
                pixel_seen_locked <= 1'b0;
                oled_seen_locked <= 1'b0;
            end else begin
                if (pixel_lock_sync[1]) pixel_seen_locked <= 1'b1;
                if (oled_lock_sync[1]) oled_seen_locked <= 1'b1;
            end
        end
    end

    wire reset_async = manager_reset || !pixel_locked || !oled_locked;
    q_reset_sync u_core_reset (.clk(clk), .reset_async(reset_async), .rst(rst));
    q_reset_sync u_pixel_reset (.clk(clk_pix), .reset_async(reset_async), .rst(rst_pix));
    q_reset_sync u_oled_reset (.clk(clk_oled), .reset_async(reset_async), .rst(rst_oled));
endmodule

module q_reset_sync (
    input wire clk,
    input wire reset_async,
    output wire rst
);
    (* ASYNC_REG = "TRUE" *) reg [2:0] reset_pipe = 3'b111;
    always @(posedge clk or posedge reset_async) begin
        if (reset_async)
            reset_pipe <= 3'b111;
        else
            reset_pipe <= {reset_pipe[1:0], 1'b0};
    end
    assign rst = reset_pipe[2];
endmodule
`default_nettype wire
