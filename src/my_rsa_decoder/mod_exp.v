`timescale 1ns / 1ps

// Func: y^x % m
module mod_exp (
        x,
        y,
        clk,
        rst_n,
        start,
        z,
        done
    );
    parameter k = 192;
    parameter logk = 8;
    parameter m = 192'hfffffffffffffffffffffffffffffffeffffffffffffffff;  // 2^192-2^64-1
    parameter exp_2k = 192'h000000000000000100000000000000020000000000000001;  // exp_k * exp_k 先通过模乘模块算出结果
    
    localparam one = {{k - 1{1'b0}}, 1'b1};
    localparam minus_m = {1'b0, ~m + 1'b1};
    localparam exp_k = ~m + 1'b1;  // 2^192 % m = 2^192 - m =  m的补码

    // 192 /8 = 24
    localparam IDLE = 5'd0, LOAD = 5'd1, START_TY = 5'd2, UPDATE_TY = 5'd3, START_E = 5'd4, UPDATE_E = 5'd5, CHOOSE = 5'd6,
               START_E2 = 5'd7, UPDATE_E2 = 5'd8, UPDATE_I = 5'd9, JUDGE_I = 5'd10, START_Z = 5'd11, UPDATE_Z = 5'd12;

    input [k-1:0] x;
    input [k-1:0] y;
    input clk;
    input rst_n;
    input start;
    output [k-1:0] z;
    output done;

    reg done;
    wire [k-1:0] operand1, operand2;
    reg [k-1:0] e, ty, reg_x;
    reg [logk-1:0] i_count;
    wire [k-1:0] result;
    reg update_e, update_ty, update_i, load, start_mul;
    wire mul_done;
    reg [1:0] control;
    wire equal_zero, xi;
    reg [4:0] current_state;
    reg [4:0] next_state;
    reg start_reg, start_pedge;
    reg mul_done_reg, mul_done_pedge;


    // mod_mul
    mod_mul #(
                .k   (k),
                .logk(logk),
                .m   (m)
            ) inst_mod_mul (
                .x    (operand1),
                .y    (operand2),
                .clk  (clk),
                .rst_n(rst_n),
                .start(start_mul),
                .z    (result),
                .done (mul_done)
            );
    assign operand1 = (control == 2'b00) ? y : e;
    assign operand2 = (control==2'b00)? exp_2k:(control==2'b01)? e:(control==2'b10)? ty: one;
    assign z = result;

    // e
    always @(posedge clk) begin : register_e
        if (load == 1'b1)
            e <= exp_k;
        else if (update_e == 1'b1)
            e <= result;
    end

    // ty
    always @(posedge clk) begin : register_ty
        if (update_ty == 1'b1)
            ty <= result;
    end

    // xi 左移
    always @(posedge clk) begin : shift_register
        if (load == 1'b1)
            reg_x <= x;
    end
    assign xi = reg_x[i_count];

    // i_count
    reg [logk-1:0] i_count_reg;
    always @(posedge clk) begin : counter
        if (load == 1'b1) begin
            i_count <= k-1;  //192
            i_count_reg <= k-1; //初值不要赋0就行
        end
        else if (update_i == 1'b1) begin
            i_count <= i_count - 1'b1;
            i_count_reg <= i_count;
        end
    end

    // FSM-1
    always @(posedge clk or negedge rst_n) begin : proc_current_state
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
            IDLE:  //0
                next_state = start ? LOAD : IDLE;
            LOAD:  //1
                next_state = START_TY;
            START_TY:  //2
                next_state = mul_done ? UPDATE_TY : START_TY;
            UPDATE_TY:  //3
                next_state = START_E;
            START_E:  //4
                next_state = mul_done ? UPDATE_E : START_E;
            UPDATE_E:  //5
                next_state = CHOOSE;
            CHOOSE:  //6
                next_state = xi ? START_E2 : UPDATE_I;
            START_E2:  //7
                next_state = mul_done ? UPDATE_E2 : START_E2;
            UPDATE_E2:  //8
                next_state = UPDATE_I;
            UPDATE_I:  //9
                next_state = JUDGE_I;
            JUDGE_I:  //10 i_count不在191~0，溢出等于255
                next_state = i_count_reg == 'd0 ? START_Z : START_E;
            START_Z:  //11
                next_state = mul_done ? UPDATE_Z : START_Z;
            UPDATE_Z:  //12
                next_state = start ? UPDATE_Z : IDLE;
            default:
                next_state = IDLE;
        endcase
    end

    // FSM-3
    always @(*) begin
        case (current_state)
            IDLE: begin
                control = 2'd0;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            LOAD: begin
                control = 2'd0;
                load = 1'b1;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            START_TY: begin
                control = 2'd0;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b1;
                done = 1'b0;
            end
            UPDATE_TY: begin
                control = 2'd0;
                load = 1'b0;
                update_ty = 1'b1;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            // control:1
            START_E: begin
                control = 2'd1;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b1;
                done = 1'b0;
            end
            UPDATE_E: begin
                control = 2'd1;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b1;
                update_i = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            CHOOSE: begin
                control = 2'd0;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            // control:2
            START_E2: begin
                control = 2'd2;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b1;
                done = 1'b0;
            end
            UPDATE_E2: begin
                control = 2'd2;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b1;
                update_i = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            UPDATE_I: begin
                control = 2'd0;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b1;
                start_mul = 1'b0;
                done = 1'b0;
            end
            JUDGE_I: begin
                control = 2'd0;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            START_Z: begin
                control = 2'd3;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b1;
                done = 1'b0;
            end
            UPDATE_Z: begin
                control = 2'd3;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b1;
                done = 1'b1;
            end
            default: begin
                control = 2'd0;
                load = 1'b0;
                update_ty = 1'b0;
                update_e = 1'b0;
                update_i = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
        endcase
    end




endmodule
