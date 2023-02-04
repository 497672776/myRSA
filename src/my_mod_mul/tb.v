`timescale 1ns / 1ps
module tb;
    parameter k = 192;
    parameter logk = 8;
    parameter m = 192'hfffffffffffffffffffffffffffffffeffffffffffffffff;
    reg clk, rst_n;
    reg [k-1:0] x, y;
    reg start;
    wire [k-1:0] z;
    wire done;

    //生成始时钟
    parameter CLK_PERIOD = 10;
    initial begin
        clk = 0;
        forever
            clk = #(CLK_PERIOD / 2) ~clk;
    end

    /****************** 开始 ADD module inst ******************/
    mod_mul #(
                .k   (k),
                .logk(logk),
                .m   (m)
            ) inst_mod_mul (
                .x    (x),
                .y    (y),
                .clk  (clk),
                .rst_n(rst_n),
                .start(start),
                .z    (z),
                .done (done)
            );
    /****************** 结束 END module inst ******************/

    initial begin
        $dumpfile("wave.lxt2");
        $dumpvars(0, tb);  //dumpvars(深度, 实例化模块1, 实例化模块2, .....)
    end

    initial begin
        rst_n = 1;
        #(CLK_PERIOD) rst_n = 0;
        #(CLK_PERIOD) rst_n = 1;

        #(CLK_PERIOD);
        start = 0;
        x = 8'Hf7;
        y = 8'H0a;
        #(CLK_PERIOD);
        start = 1;
        wait (done);

        #(CLK_PERIOD);
        start = 0;
        x = 192'H000000000000000100000000000000020000000000000001;
        y = 8'H0B;
        #(CLK_PERIOD);
        start = 1;
        wait (done);

        #(CLK_PERIOD);
        start = 0;
        x = 192'H0x000000000000000000000000000000010000000000000001;
        y = 192'H0x000000000000000000000000000000010000000000000001;
        #(CLK_PERIOD);
        start = 1;
        wait (done);

        #(CLK_PERIOD);
        start = 0;
        x = 192'H0x000000000000000000000000000000010000000000000001;
        y = 192'H0x0000000000000000000000000000000B000000000000000B;
        #(CLK_PERIOD);
        start = 1;
        wait (done);

        #(CLK_PERIOD);
        start = 0;
        x = 196'H0x0000000000000000000000000000000B0000000000000000B;
        y = 196'H0x0000000000000000000000000000000B0000000000000000B;
        #(CLK_PERIOD);
        start = 1;
        wait (done);

        #(CLK_PERIOD);
        start = 0;
        x = 196'H0x0000000000000000000000000000007900000000000000079;
        y = 196'd1;
        #(CLK_PERIOD);
        start = 1;
        wait (done);

        repeat (100)
            @(posedge clk) begin
         end
         $display("运行结束！");
        $dumpflush;
        $finish;
        $stop;
    end
endmodule

// z = 0x00000000000009A5FFFFFFFFFFFFF65A0000000000000000
// z = ty = 0x0000000000000000000000000000000B000000000000000B
// z = e1 = 0x000000000000000000000000000000010000000000000001
// z = e2 = 0x0000000000000000000000000000000B000000000000000B