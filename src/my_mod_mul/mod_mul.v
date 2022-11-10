`timescale 1ns / 1ps

module mod_mul (
        input [k-1:0] x,
        input [k-1:0] y,
        input clk,
        input rst_n,
        input start,
        output [k-1:0] z,
        output done
    );

    parameter m = 192'hfffffffffffffffffffffffffffffffeffffffffffffffff;
    parameter k = 192, logk = 8, zero = {logk{1'b0}};
    parameter minus_m = {1'b0, 192'h000000000000000000000000000000010000000000000001};
    parameter COUNT = 8'd191;

    parameter IDLE = 3'd0, LOAD = 3'd1, CE_P = 3'd2, ENDING = 3'd3;


    reg [k-1:0] reg_x;
    wire xi;
    wire [k:0] y_by_xi;
    reg [k:0] p;  // p < 2m, 所以比m多一个位，k+1
    wire [k+1:0] a;  // a比p多一位
    wire [k+1:0] b;  // b比p多一位
    wire [k:0] next_p;
    wire [k:0] p_minus_m;
    wire [k+1:0] long_m;
    wire [k:0] half_a, half_b;

    reg [logk-1:0] count;
    wire equal_zero;
    reg load, ce_p;
    reg [2:0] current_state;
    reg [2:0] next_state;
    reg start_reg, start_pedge;
    reg done;

    // Func: xi
    always @(posedge clk) begin : shift_register
        integer i;
        if (load == 1'b1) begin
            reg_x = x;
        end
        else if (ce_p == 1'b1) begin
            for (i = 0; i <= k - 2; i = i + 1) begin
                reg_x[i] = reg_x[i+1];
            end
            reg_x[k-1] = 1'b0;
        end
    end
    assign xi = reg_x[0];

    // Func: y_by_xi = xi * y
    // 无符号数乘法时，结果变量位宽应该为2个操作数位宽之和。
    assign y_by_xi = xi * y;

    // Func: a = p + y_by_xi
    assign a = p + y_by_xi;

    // Func: b = a + m
    assign long_m = {{2'b00}, m};
    assign b = a + long_m;

    // Func: if (a mod 2) = 0 then p = a/2; else p = b/2;
    assign half_a = a[k+1:1], half_b = b[k+1:1];
    assign next_p = (a[0] == 1'b0) ? half_a : half_b;

    // Func: load 清零， ce_p 赋值
    always @(posedge clk) begin : parallel_register
        if (load == 1'b1) begin
            p = {(k + 1) {1'b0}};
        end
        else if (ce_p == 1'b1) begin
            p = next_p;
        end
    end

    assign p_minus_m = p + minus_m;

    // Note: p_minus_m = p + 2^k - m = 2^k + (p-m)
    // Note: p < 2m, p-m < m < 2^k, 因为p-m < 2^k，p_minus_m < 2^(k+1),不会溢出
    assign z = (p_minus_m[k] == 1'b0) ? p[k-1:0] : p_minus_m[k-1:0];

    // Func: counter, if load then count = 191
    always @(posedge clk) begin : counter
        if (load == 1'b1) begin
            count <= COUNT;
        end
        else if (ce_p == 1'b1) begin
            count <= count - 1'b1;
        end
    end
    assign equal_zero = (count == zero) ? 1'b1 : 1'b0;

    // FSM-1
    always @(posedge clk, negedge rst_n) begin : proc_current_state
        if (~rst_n) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end
    
    // 检测start上升沿
    always@(posedge clk)begin
        start_reg <= start;
        start_pedge <= start & ~start_reg;
    end

    // FSM-2
    always @(*) begin
        case (current_state)
            IDLE:
                // start_pedge 有可能是未知量,最好别用next_state = start_pedge ? LOAD : IDLE;
                if(start_pedge)
                    next_state = LOAD;
                else
                    next_state = IDLE;
            LOAD:
                next_state = CE_P;
            CE_P:
                next_state = equal_zero ? ENDING : CE_P;
            ENDING:
                next_state = start_pedge ? LOAD : ENDING;
            default:
                next_state = IDLE;
        endcase
    end

    // FSM-3
    always @(*) begin
        case (current_state)
            IDLE: begin
                load = 1'b0;
                ce_p = 1'b0;
                done = 1'b0;
            end

            LOAD: begin
                load = 1'b1;
                ce_p = 1'b0;
                done = 1'b0;
            end

            CE_P: begin
                load = 1'b0;
                ce_p = 1'b1;
                done = 1'b0;
            end

            ENDING: begin
                load = 1'b0;
                ce_p = 1'b0;
                done = 1'b1;
            end

            default: begin
                load = 1'b0;
                ce_p = 1'b0;
                done = 1'b0;
            end

        endcase
    end

endmodule


