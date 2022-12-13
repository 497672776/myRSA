`timescale 1ns / 1ps

module rsa_decoder (
        input clk,
        input rst_n,
        input start,
        input [k-1:0] data_in,
        output [k-1:0] data_out,
        output done
    );


    parameter p = 67, q = 5, n = 3551, t = 3432, e = 5, d = 1373;
    parameter exp_2k = 2292;  // 4096-3551=545, 545*545%3551 =2292
    // 3551 2^10 = 1024 2^11 = 2048 2^12 = 4096
    parameter k = 12;
    parameter logk = 4;
    // mod_exp
    mod_exp #(
                .k     (k),
                .logk  (logk),
                .m     (n),
                .exp_2k(exp_2k)
            ) inst_mod_exp (
                .x    (d),
                .y    (data_in),
                .clk  (clk),
                .rst_n(rst_n),
                .start(start),
                .z    (data_out),
                .done (done)
            );
endmodule
