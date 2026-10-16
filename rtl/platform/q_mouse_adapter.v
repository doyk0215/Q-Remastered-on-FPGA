`timescale 1ns / 1ps
`default_nettype none
`include "q_contract.vh"
`include "q_ports.vh"

module q_mouse_adapter (
    `Q_CORE_PORTS,
    `Q_MOUSE_SOURCE_PORTS,
    `Q_FAULT_SOURCE_PORTS,
    inout wire ps2_clk,
    inout wire ps2_data
);
    localparam [11:0] MAX_X = `Q_SCREEN_W - 1;
    localparam [11:0] MAX_Y = `Q_SCREEN_H - 1;
    localparam [11:0] START_X = `Q_SCREEN_W / 2;
    localparam [11:0] START_Y = `Q_SCREEN_H / 2;
    reg [2:0] init_step;
    reg [11:0] init_value;
    reg setx, sety, setmax_x, setmax_y;
    wire initialized = (init_step == 3'd5);
    always @* begin
        init_value = 12'd0;
        setx = 1'b0;
        sety = 1'b0;
        setmax_x = 1'b0;
        setmax_y = 1'b0;
        if (!rst) begin
            case (init_step)
                3'd0: begin init_value = MAX_X; setmax_x = 1'b1; end
                3'd1: begin init_value = MAX_Y; setmax_y = 1'b1; end
                3'd2: begin init_value = START_X; setx = 1'b1; end
                3'd3: begin init_value = START_Y; sety = 1'b1; end
                default: begin end
            endcase
        end
    end
    // One additional cycle allows the supplied registered xpos/ypos to settle.
    always @(posedge clk) begin
        if (rst) init_step <= 3'd0;
        else if (!initialized) init_step <= init_step + 1'b1;
    end

    wire [11:0] driver_x, driver_y;
    wire driver_left, driver_right, driver_middle, driver_event;
    reg report_due;
    wire [3:0] unused_z;
    MouseCtl #(.SYSCLK_FREQUENCY_HZ(`Q_CORE_HZ)) u_mouse (
        .clk(clk), .rst(rst), .xpos(driver_x), .ypos(driver_y),
        .zpos(unused_z), .left(driver_left), .right(driver_right),
        .middle(driver_middle), .new_event(driver_event),
        .value(init_value), .setx(setx), .sety(sety),
        .setmax_x(setmax_x), .setmax_y(setmax_y),
        .ps2_clk(ps2_clk), .ps2_data(ps2_data)
    );

    // A non-wheel report can assert new_event while the supplied ypos output
    // register is still receiving the final Y update. Delay capture one cycle
    // after observing new_event so coordinates and buttons belong to one report.
    always @(posedge clk) begin
        if (rst) report_due <= 1'b0;
        else report_due <= initialized && driver_event;
    end

    // Clamp at the full 12-bit driver width before narrowing the record.
    wire [11:0] clamped_x = (driver_x > MAX_X) ? MAX_X : driver_x;
    wire [11:0] clamped_y = (driver_y > MAX_Y) ? MAX_Y : driver_y;
    reg [`Q_MOUSE_W-1:0] report_data;
    always @* begin
        report_data = {`Q_MOUSE_W{1'b0}};
        report_data[`Q_MOUSE_X_LSB +: `Q_MOUSE_X_W] = clamped_x[`Q_MOUSE_X_W-1:0];
        report_data[`Q_MOUSE_Y_LSB +: `Q_MOUSE_Y_W] = clamped_y[`Q_MOUSE_Y_W-1:0];
        report_data[`Q_MOUSE_LEFT_LSB] = driver_left;
        report_data[`Q_MOUSE_RIGHT_LSB] = driver_right;
        report_data[`Q_MOUSE_MIDDLE_LSB] = driver_middle;
    end

    // All reports are queued in order; no motion coalescing or button overwrite.
    reg [`Q_MOUSE_W-1:0] fifo [0:7];
    reg [2:0] read_ptr, write_ptr;
    reg [3:0] count;
    reg [`Q_FAULT_W-1:0] faults;
    wire pop = mouse_sample_valid && mouse_sample_ready;
    wire incoming = report_due;
    wire push = incoming && ((count < 4'd8) || pop);
    assign mouse_sample_valid = !rst && (count != 0);
    assign mouse_sample_data = fifo[read_ptr];
    assign fault_flags = faults;
    always @(posedge clk) begin
        if (rst) begin
            read_ptr <= 3'd0;
            write_ptr <= 3'd0;
            count <= 4'd0;
            faults <= {`Q_FAULT_W{1'b0}};
        end else begin
            if (push) begin
                fifo[write_ptr] <= report_data;
                write_ptr <= write_ptr + 1'b1;
            end
            if (pop) read_ptr <= read_ptr + 1'b1;
            case ({push, pop})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: begin end
            endcase
            if (incoming && !push)
                faults[`Q_FAULT_INPUT_OVERFLOW_BIT] <= 1'b1;
        end
    end
endmodule
`default_nettype wire
