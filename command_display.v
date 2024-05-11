`ifndef COMMAND_DISPLAY_V
`define COMMAND_DISPLAY_V
`include "hex_disp.v"

module command_display (
    input[11:0] cmd_buf,
    // output[6:0] displays[3:0],
    output[6:0] display_0,
    output[6:0] display_1,
    output[6:0] display_2,
    output[6:0] display_3
);
    wire[4:0] address;
    wire[6:0] command;

    assign {address, command} = cmd_buf;

    hex_disp hex_addr_h(.data({3'b000, address[4]}), .seg(display_0));
    hex_disp hex_addr_l(.data(address[3:0]), .seg(display_1));
    hex_disp hax_cmd_h(.data({1'b0, command[6:4]}), .seg(display_2));
    hex_disp hax_cmd_l(.data(command[3:0]), .seg(display_3));
endmodule
`endif
