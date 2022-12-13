`timescale 1ns / 1ps

// Func: z = Montgomery(x,y) = x*y*R' mod m
module mod_mul (
        input [k-1:0] x,
        input [k-1:0] y,
        input clk,
        input rst_n,
        input start,
        output [k-1:0] z,
        output done
    );


    parameter k = 192;
    parameter logk = 8;
    parameter m = 192'hfffffffffffffffffffffffffffffffeffffffffffffffff;
    localparam minus_m = {1'b0, ~m+1'b1};

    localparam IDLE = 3'd0, LOAD = 3'd1, UPDATE = 3'd2, ENDING = 3'd3;

    reg load, update, done;
    reg [2:0] current_state, next_state;

    // Func: counter
    reg [logk-1:0] count;
    always @(posedge clk) begin : counter
        if (load) begin
            count <= 0;
        end
        else if (update) begin
            count <= count + 1'b1;
        end
    end

    // load: 加载x
    reg [k-1:0] reg_x;
    always @(posedge clk) begin : shift_register
        if (load) begin
            reg_x = x;
        end
    end
    wire xi;
    assign xi = reg_x[count];

    // 0 <=  p < 2m, 所以比m多一个位，k+1
    reg [k:0] p;
    // Func: a = p + y*xi
    // xi = 1 时， y*xi = y; xi = 0 时， y*xi = 0
    // p 是(k+1)位， y是k位， 所以 a最多是(k+2)位
    wire [k+1:0] a;
    assign a = xi? (p + y) : p;

    // 由于 p是由a/2或b/2得来的，而p最多是k+1位，所以b最多是k+2位
    // Func: b = a + m
    wire [k+1:0] b;
    assign b = a + m;

    // Func: if (a mod 2) = 0 then p = a/2; else p = b/2;
    wire [k:0] half_a, half_b;
    assign half_a = a[k+1:1], half_b = b[k+1:1];
    wire [k:0] next_p;
    assign next_p = (a[0] == 1'b0) ? half_a : half_b;

    // Func: load: p赋初值0， update: 更新p
    always @(posedge clk) begin : parallel_register
        if (load) begin
            p = 'b0;
        end
        else if (update) begin
            p = next_p;
        end
    end

    // Note: p_minus_m = p + 2^k - m = 2^k + (p-m)
    // Note: p-m < 0时, p_minus_m[k] = 0 ,我们要输出p
    // Note: m > p-m > 0时, p_minus_m[k] = 1 ,我们要输出p-m
    // Note: z < m, 所以只取前k位
    // Func: if p >= m, z = p-m; else z = p
    wire [k:0] p_minus_m;
    assign p_minus_m = next_p + minus_m;
    assign z = (p_minus_m[k] == 1'b0) ? next_p[k-1:0] : p_minus_m[k-1:0];

    // FSM-1
    always @(posedge clk, negedge rst_n) begin : proc_current_state
        if (~rst_n) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    // FSM-2
    always @(*) begin
        case (current_state)
            IDLE:
                next_state = start ? LOAD : IDLE;
            LOAD:
                next_state = UPDATE;
            UPDATE: // update 0~190，共191次，加上LOAD初始化为1，共192次
                next_state = count == (k-2) ? ENDING : UPDATE;
            ENDING:
                next_state = start ? ENDING : IDLE;
            default:
                next_state = IDLE;
        endcase
    end

    // FSM-3
    always @(*) begin
        case (current_state)
            IDLE: begin
                load = 1'b0;
                update = 1'b0;
                done = 1'b0;
            end

            LOAD: begin
                load = 1'b1;
                update = 1'b0;
                done = 1'b0;
            end

            UPDATE: begin
                load = 1'b0;
                update = 1'b1;
                done = 1'b0;
            end

            ENDING: begin
                load = 1'b0;
                update = 1'b0;
                done = 1'b1;
            end

            default: begin
                load = 1'b0;
                update = 1'b0;
                done = 1'b0;
            end
        endcase
    end

endmodule


