`timescale 1ns/1ns
`default_nettype none

`include "led_mgr.v"

module led_mgr_tb ();
    reg clk;
    reg new_cmd;
    reg [11:0] cmd;
    wire [9:0] leds;

    led_mgr UUT(.clk(clk), .new_cmd(new_cmd), .cmd_buf(cmd), .leds(leds));

    initial begin
        // 50 MHz clock (20 ns period)
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        new_cmd = 0;
        // All on
        #20 cmd = {UUT.DEV_ADDR, UUT.CMD_SET, 4'd0};
        $display("All on");
        #10 new_cmd = 1;
        #20 new_cmd = 0;
        // Toggle LED 3
        #10 cmd = {UUT.DEV_ADDR, UUT.CMD_TGL, 4'd3};
        $display("Toggle LED 3");
        #10 new_cmd = 1;
        #20 new_cmd = 0;
        // LED 5 off
        #10 cmd = {UUT.DEV_ADDR, UUT.CMD_OFF, 4'd5};
        $display("LED 5 off");
        #10 new_cmd = 1;
        #20 new_cmd = 0;
        // All off
        #10 cmd = {UUT.DEV_ADDR, UUT.CMD_RST, 4'd0};
        $display("All off");
        #10 new_cmd = 1; // keep 1, to always execute commands
        // LED 7 on
        #10 cmd = {UUT.DEV_ADDR, UUT.CMD_ON, 4'd7};
        $display("LED 7 on");
        // Toggle LED 1
        #20 cmd = {UUT.DEV_ADDR, UUT.CMD_TGL, 4'd1};
        $display("Toggle LED 1");
        // ROR twice
        #20 cmd = {UUT.DEV_ADDR, UUT.CMD_SHR, 4'b1000};
        $display("Rotate right");
        #20 $display("Rotate right");
        // SHR (0)
        #20 cmd = {UUT.DEV_ADDR, UUT.CMD_SHR, 4'b0000};
        $display("Shift right (fill with 0)");
        // SHR (1)
        #20 cmd = {UUT.DEV_ADDR, UUT.CMD_SHR, 4'b0001};
        $display("Shift right (fill with 1)");
        // ROL twice
        #20 cmd = {UUT.DEV_ADDR, UUT.CMD_SHL, 4'b1000};
        $display("Rotate left");
        #20 $display("Rotate left");
        // SHL (0)
        #20 cmd = {UUT.DEV_ADDR, UUT.CMD_SHL, 4'b0000};
        $display("Shift left (fill with 0)");
        // SHL (1)
        #20 cmd = {UUT.DEV_ADDR, UUT.CMD_SHL, 4'b0001};
        $display("Shift left (fill with 1)");
        // Different address
        #20 cmd = {5'h1A, UUT.CMD_SET, 4'd0};
        $display("Different address (nothing happens)");
        #25 $finish;
    end

    initial $monitor("%0t: %b", $time, leds);
    initial begin
        $dumpfile("out/led_mgr_tb.vcd");
        $dumpvars(0, led_mgr_tb);
    end
endmodule
