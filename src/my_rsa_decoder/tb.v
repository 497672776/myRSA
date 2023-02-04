`timescale 1ns / 1ps
module tb;

    // 定义信号
    reg clk, rst_n;
    reg start;

    parameter n = 12'd3551;
    parameter exp_2k = 12'd2292;
    parameter d = 12'd1373;
    parameter k = 12;
    parameter logk = 4;
    reg  [k-1:0] data_in;
    wire [k-1:0] data_out;
    wire done;
    // 生成始时钟
    parameter NCLK = 40;  //40ns 25Mhz
    initial begin
        clk = 0;
        forever
            clk = #(NCLK / 2) ~clk;
    end

    /****************** 开始 ADD module inst ******************/
    rsa_decoder #(
                    .n   (n),
                    .d   (d),
                    .k   (k),
                    .logk(logk),
                    .exp_2k(exp_2k)
                ) inst_rsa_encoder (
                    .clk     (clk),
                    .rst_n   (rst_n),
                    .start   (start),
                    .data_in (data_in),
                    .data_out(data_out),
                    .done    (done)
                );
    /****************** 结束 END module inst ******************/

    initial begin
        $dumpfile("wave.lxt2");
        $dumpvars(0, tb);  //dumpvars(深度, 实例化模块1, 实例化模块2, .....)
    end

    initial begin
        rst_n = 1;
        #(NCLK) rst_n = 0;
        #(NCLK) rst_n = 1;  //复位信号

        #(NCLK);
        start   = 0;
        data_in = 12'd2959;
        #(NCLK);
        start = 1;
        wait (done);

        #(NCLK);
        start   = 0;
        data_in = 12'd59;
        #(NCLK);
        start = 1;
        wait (done);


        repeat (1000) begin
            @(posedge clk);
        end
        $display("运行结束！");
        $dumpflush;
        $finish;
        $stop;
    end
endmodule
