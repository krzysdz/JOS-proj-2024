`timescale 1ns/1ns
`default_nettype none

`include "ir_receiver.v"

module ir_receiver_tb ();
    reg clk;
    reg ir;
    wire [11:0] data;
    wire ready;

    localparam integer Base = 30000;
    localparam integer BaseT = Base * 20;
    localparam integer StartT = BaseT * 4;
    localparam integer LongT = BaseT * 2;

    ir_receiver #(.BASE_PULSE_WIDTH(Base))
        UUT(.clk(clk), .ir_in(ir), .data(data), .data_rdy(ready));

    initial begin
        // 50 MHz clock (20 ns period)
        clk = 0;
        forever #10 clk = ~clk;
    end

    localparam [11:0] Data1 = 12'hF0D;
    integer i;

    initial begin
        ir = 1;
        #100000 ir = 0;
        #StartT ir = 1;

        for (i = 0; i < 12; i = i + 1) begin
            #BaseT ir = 0;
            if (Data1[i])
                #LongT ir = 1;
            else
                #BaseT ir = 1;
        end

        #StartT $display("Sent: %x, received: %x", Data1, data);

        // Send something random to test if state resets to idle on invalid data
        // and ready bit gets cleared when data changes.
        #BaseT ir = 0;
        #StartT ir = 1;
        #BaseT ir = 0;
        #BaseT ir = 1;

        #StartT $finish;
    end

    reg [8*5:1] rdy_str = "WAIT ";
    always @(ready)
        rdy_str <= ready ? "READY" : "WAIT ";

    initial $monitor("%0t: (%d) %s %b", $time, ready, rdy_str, data);
    initial begin
        $dumpfile("out/ir_receiver_tb.vcd");
        $dumpvars(0, ir_receiver_tb);
    end
endmodule
