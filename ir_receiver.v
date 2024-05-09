`ifndef IR_RECEIVER_V
`define IR_RECEIVER_V

module ir_receiver #(
    parameter integer BASE_PULSE_WIDTH = 30000
) (
    input clk,
    input ir,
    output reg[11:0] data,
    output reg data_rdy
);
    localparam S_IDLE      = 2'b00;
    localparam S_RCV_PAUSE = 2'b01;
    localparam S_RCV_BIT   = 2'b10;

    reg[1:0] state;
endmodule
`endif
