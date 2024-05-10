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
    `include "clog2_function.vh"

    localparam integer COUNTER_WIDTH = clog2(BASE_PULSE_WIDTH * 101 * 4 / 100);
    localparam S_IDLE      = 2'b00;
    localparam S_START     = 2'b01;
    localparam S_RCV_PAUSE = 2'b10;
    localparam S_RCV_BIT   = 2'b11;

    // Allow for 1% deviation from the expected time
    localparam integer BASE_MIN = $rtoi(BASE_PULSE_WIDTH * 0.99);
    localparam integer BASE_MAX = $rtoi(BASE_PULSE_WIDTH * 1.01);
    localparam integer BASE2_MIN = BASE_MIN * 2;
    localparam integer BASE2_MAX = BASE_MAX * 2;
    localparam integer BASE4_MIN = BASE_MIN * 4;
    localparam integer BASE4_MAX = BASE_MAX * 4;

    reg[1:0] state;
    reg[COUNTER_WIDTH-1:0] pulse_time;
    reg[3:0] ready_bits;

    always @(posedge clk) begin
        case (state)
            S_IDLE:
                if (ir == 0) begin
                    state <= S_START;
                    pulse_time <= 0;
                end
            S_START:
                if (ir == 0)
                    pulse_time <= pulse_time + 1;
                else if (pulse_time >= BASE4_MIN && pulse_time <= BASE4_MAX) begin
                    pulse_time <= 0;
                    ready_bits <= 0;
                    data <= 0;
                    state <= S_RCV_PAUSE;
                end else
                    state <= S_IDLE;
            S_RCV_PAUSE:
                if (pulse_time > BASE2_MAX) begin
                    state <= S_IDLE;
                    data_rdy <= ready_bits == 4'd12;
                end else if (ir)
                    pulse_time <= pulse_time + 1;
                else if (pulse_time >= BASE_MIN && pulse_time <= BASE_MAX) begin
                    pulse_time <= 0;
                    state <= S_RCV_BIT;
                end else
                    state <= S_IDLE;
            S_RCV_BIT:
                if (ir == 0)
                    pulse_time <= pulse_time + 1;
                else if (pulse_time >= BASE_MIN && pulse_time <= BASE_MAX) begin
                    data_rdy <= 0;
                    data <= {data[10:0], 1'b0};
                    ready_bits <= ready_bits + 1;
                    pulse_time <= 0;
                    state <= S_RCV_PAUSE;
                end else if (pulse_time >= BASE2_MIN && pulse_time <= BASE2_MAX) begin
                    data_rdy <= 0;
                    data <= {data[10:0], 1'b1};
                    ready_bits <= ready_bits + 1;
                    pulse_time <= 0;
                    state <= S_RCV_PAUSE;
                end else
                    state <= S_IDLE;
            default: state <= S_IDLE;
        endcase
    end
endmodule
`endif
