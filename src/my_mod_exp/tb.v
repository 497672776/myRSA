`timescale 1ns / 1ps
module tb;
    reg clk, rst_n;
    reg [191:0] x, y;
    reg start;
    wire [191:0] z;
    wire done;

    //生成始时钟
    parameter NCLK = 10;
    initial begin
        clk = 0;
        forever
            clk = #(NCLK / 2) ~clk;
    end

    /****************** 开始 ADD module inst ******************/
    mont_exp
        inst_mont_exp (
            .x                 (x),
            .y                 (y),
            .clk               (clk),
            .rst_n             (rst_n),
            .start             (start),
            .z                 (z),
            .done             (done)
        );
    /****************** 结束 END module inst ******************/

    initial begin
        $dumpfile("wave.lxt2");
        $dumpvars(0, tb);  //dumpvars(深度, 实例化模块1, 实例化模块2, .....)
    end

    initial begin
        rst_n = 1;
        #(NCLK) rst_n = 0;
        #(NCLK) rst_n = 1;

        #(NCLK);
        start = 0;
        x = 8'd2;
        y = 8'd11;
        #(NCLK);
        start = 1;
        wait(done);

        repeat (1000) @(posedge clk) begin
        end
        $display("运行结束！");
        $dumpflush;
        $finish;
        $stop;
    end
endmodule

// z = 0x00000000000009A5FFFFFFFFFFFFF65A0000000000000000

