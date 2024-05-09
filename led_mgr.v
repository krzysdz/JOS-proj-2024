`ifndef LED_MGR_V
`define LED_MGR_V

module led_mgr #(
    parameter DEV_ADDR = 5'h0C,
    parameter CMD_OFF = 3'b100,
    parameter CMD_ON  = 3'b101,
    parameter CMD_SHL = 3'b010,
    parameter CMD_SHR = 3'b011,
    parameter CMD_TGL = 3'b001,
    parameter CMD_RST = 3'b110,
    parameter CMD_SET = 3'b111,
    parameter CMD_NOP = 3'b000,
    parameter SHIFT_ROT = 4'b1xxx,
    parameter SHIFT_C0  = 4'b0xx0,
    parameter SHIFT_C1  = 4'b0xx1
) (
    input clk,
    input new_cmd,
    input[11:0] cmd_buf,
    output reg[9:0] leds
);
    // 5-bit address, 7 bit command (I treat it as 3-bit opcode and 4-bit data/operand)
    wire[4:0] address;
    wire[2:0] op;
    wire[3:0] d;
    reg[9:0] led_mask;

    assign {address, op, d} = cmd_buf;

    always @(posedge clk) begin
        if (new_cmd && address == DEV_ADDR) begin
            case (d)
                4'd0: led_mask <= 10'b0000000001;
                4'd1: led_mask <= 10'b0000000010;
                4'd2: led_mask <= 10'b0000000100;
                4'd3: led_mask <= 10'b0000001000;
                4'd4: led_mask <= 10'b0000010000;
                4'd5: led_mask <= 10'b0000100000;
                4'd6: led_mask <= 10'b0001000000;
                4'd7: led_mask <= 10'b0010000000;
                4'd8: led_mask <= 10'b0100000000;
                4'd9: led_mask <= 10'b1000000000;
                default: led_mask <= 0;
            endcase
            case (op)
                CMD_OFF: leds <= leds & ~led_mask;
                CMD_ON:  leds <= leds | led_mask;
                CMD_SHL: casex (d)
                    SHIFT_ROT: leds <= {leds[8:0], leds[9]};
                    SHIFT_C0: leds <= {leds[8:0], 1'b0};
                    SHIFT_C1: leds <= {leds[8:0], 1'b1};
                    default: leds <= {leds[8:0], 1'b0};
                endcase
                CMD_SHR: casex (d)
                    SHIFT_ROT: leds <= {leds[0], leds[9:1]};
                    SHIFT_C0: leds <= {1'b0, leds[9:1]};
                    SHIFT_C1: leds <= {1'b1, leds[9:1]};
                    default: leds <= {1'b0, leds[9:1]};
                endcase
                CMD_TGL: leds <= leds ^ led_mask;
                CMD_RST: leds <= 0;
                CMD_SET: leds <= 10'b1111111111;
                CMD_NOP:;
                default:;
            endcase
        end
    end
endmodule
`endif
