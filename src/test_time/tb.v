`timescale 1ns / 1ps
module tb ;
    reg clk,rst;
    reg in;
    wire pedge;
    wire pedge2;
    //生成始时钟
    parameter NCLK = 4;
    initial begin
        clk=0;
        forever
            clk=#(NCLK/2) ~clk;
    end
    /****************** 开始 ADD module inst ******************/
    time_time  inst_time (
                   .clk               (clk),
                   .in                (in),
                   .pedge             (pedge),
                   .pedge2             (pedge2)
               );
    /****************** 结束 END module inst ******************/
    initial begin
        $dumpfile("wave.lxt2");
        $dumpvars(0, tb);   //dumpvars(深度, 实例化模块1, 实例化模块2, .....)
    end

    initial begin
        rst = 1;
        #(NCLK) rst=0;
        #(NCLK) rst=1; //复位信号

        repeat(100) @(posedge clk)begin

        end
        $display("运行结束！");
        $dumpflush;
        $finish;
        $stop;
    end

    initial begin
        #(NCLK / 2 );
        in = 0;
        #(NCLK) in =1;
        #(NCLK) in =0;
    end
endmodule
