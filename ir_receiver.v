`ifndef IR_RECEIVER_V
`define IR_RECEIVER_V

/////////////////////////////////////////////////////////////////////
// REMEMBER: ir is LOW on signal, pulled-up when nothing detected! //
/////////////////////////////////////////////////////////////////////

module ir_receiver #(
    parameter integer BASE_PULSE_WIDTH = 30000,
    // > In general all IR equipment is forgiving and operates with in a timing tolerance of +/- 10%.
    // Barry V. Gordon, "Learned IR Code Display Format" (Version 3/1/99)
    // https://web.archive.org/web/20220315074837/http://the-gordons.net/homepage/DownLoad.html
    parameter real ERROR_MARGIN = 0.1 // 10% by default, since apparently it's the typical value
) (
    input clk,
    input ir,
    output reg[11:0] data,
    output reg data_rdy
);
    `include "clog2_function.vh"

    localparam S_IDLE      = 2'b00;
    localparam S_START     = 2'b01;
    localparam S_RCV_PAUSE = 2'b10;
    localparam S_RCV_BIT   = 2'b11;

    localparam integer BASE_MIN = $rtoi(BASE_PULSE_WIDTH * (1.0 - ERROR_MARGIN));
    localparam integer BASE_MAX = $rtoi(BASE_PULSE_WIDTH * (1.0 + ERROR_MARGIN));
    localparam integer BASE2_MIN = BASE_MIN * 2;
    localparam integer BASE2_MAX = BASE_MAX * 2;
    localparam integer BASE4_MIN = BASE_MIN * 4;
    localparam integer BASE4_MAX = BASE_MAX * 4;
    localparam integer COUNTER_WIDTH = clog2(BASE4_MAX);

    reg[1:0] state;
    reg[COUNTER_WIDTH-1:0] pulse_time;
    reg[3:0] ready_bits;

    always @(posedge clk) begin
        case (state)
            S_IDLE:
                if (ir == 0) begin
                    // Signal detected, switch to start sequence detection
                    state <= S_START;
                    pulse_time <= 0;
                end
            S_START:
                if (ir == 0)
                    pulse_time <= pulse_time + 1;
                else if (pulse_time >= BASE4_MIN && pulse_time <= BASE4_MAX) begin
                    // Correct length of start signal, reset received bit count and check pause length
                    pulse_time <= 0;
                    ready_bits <= 0;
                    state <= S_RCV_PAUSE;
                end else
                    // Signal disappeared, but it was too short/long, switch back to idle
                    state <= S_IDLE;
            S_RCV_PAUSE:
                if (pulse_time > BASE2_MAX) begin
                    // Waiting long enough to switch to idle, set data_rdy if 12 bits were received
                    state <= S_IDLE;
                    data_rdy <= ready_bits == 4'd12;
                end else if (ir)
                    pulse_time <= pulse_time + 1;
                else if (pulse_time >= BASE_MIN && pulse_time <= BASE_MAX) begin
                    // Got signal after expected pause, start receiving the next bit
                    pulse_time <= 0;
                    state <= S_RCV_BIT;
                end else
                    // Got signal after incorrect pause period, back to idle
                    state <= S_IDLE;
            S_RCV_BIT:
                if (ir == 0)
                    pulse_time <= pulse_time + 1;
                else if (pulse_time >= BASE_MIN && pulse_time <= BASE_MAX) begin
                    // Signal length indicates bit "0", save it, reset data_rdy, and wait the pause
                    data_rdy <= 0;
                    data <= {data[10:0], 1'b0};
                    ready_bits <= ready_bits + 1;
                    pulse_time <= 0;
                    state <= S_RCV_PAUSE;
                end else if (pulse_time >= BASE2_MIN && pulse_time <= BASE2_MAX) begin
                    // Signal length indicates bit "1", save it, reset data_rdy, and wait the pause
                    data_rdy <= 0;
                    data <= {data[10:0], 1'b1};
                    ready_bits <= ready_bits + 1;
                    pulse_time <= 0;
                    state <= S_RCV_PAUSE;
                end else
                    // Signal length did not match 0 or 1, go back to idle
                    state <= S_IDLE;
            default: state <= S_IDLE;
        endcase
    end
endmodule
`endif
