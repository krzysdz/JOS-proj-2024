`timescale 1ps/1ps
`default_nettype none

// `define DEBUG

`include "ir_receiver.v"
`include "led_mgr.v"
`include "command_display.v"

module top (
    input clk,
    input ir,
    output [6:0] display_0,
    output [6:0] display_1,
    output [6:0] display_2,
    output [6:0] display_3,
    output [9:0] leds
`ifdef DEBUG
    ,
    output [6:0] disp_st,
    output [6:0] disp_rb,
    output ir_out
`endif
);
    reg         new_cmd;
    reg  [11:0] saved_data;
    reg         saved_rdy;
    wire [11:0] out_data;
    wire        out_data_rdy;

`ifdef DEBUG
    wire [3:0] st;
    wire [3:0] rb;
    assign ir_out = ir;
`endif

    ir_receiver receiver (
        .clk(clk),
        .ir_in(ir),
        .data(out_data),
        .data_rdy(out_data_rdy)
`ifdef DEBUG
        ,
        .st(st),
        .rb(rb)
`endif
    );
    led_mgr mgr (
        .clk(clk),
        .new_cmd(new_cmd),
        .cmd_buf(saved_data),
        .leds(leds)
    );
    command_display disp (
        .cmd_buf  (saved_data),
        .display_0(display_0),
        .display_1(display_1),
        .display_2(display_2),
        .display_3(display_3)
    );

`ifdef DEBUG
    hex_disp hd1(.data(st), .seg(disp_st));
    hex_disp hd2(.data(rb), .seg(disp_rb));
`endif

    always @(posedge clk) begin
        if (out_data_rdy && !saved_rdy) begin
            saved_data <= out_data;
            new_cmd <= 1'b1;
        end else
            new_cmd <= 1'b0;

        saved_rdy <= out_data_rdy;
    end

endmodule
