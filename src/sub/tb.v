`timescale 1ns / 1ps
module tb ;
    reg clk,rst;
    reg [3:0] a;
    reg [3:0] b;
    wire[3:0] d;
    wire [3:0]aBigB;
    //生成始时钟
    parameter NCLK = 4;
    initial begin
        clk=0;
        forever
            clk=#(NCLK/2) ~clk;
    end

    /****************** 开始 ADD module inst ******************/
    subtract  inst_subtract (
                  .a                 (a),
                  .b                 (b),
                  .d                 (d),
                  .aBigB             (aBigB)
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


        #(NCLK);
        a = 4'b1000;
        b = 4'b1101;

        #(NCLK);
        a = 4'b1101;
        b = 4'b1100;

        #(NCLK);
        a = 4'b0000;
        b = 4'b1011;

        #(NCLK);
        a = 4'b1100;
        b = 4'b1001;

        #(NCLK);
        a = 4'b0011;
        b = 4'b0001;
        repeat(100) @(posedge clk)begin

        end
        $display("运行结束！");
        $dumpflush;
        $finish;
        $stop;
    end
endmodule
