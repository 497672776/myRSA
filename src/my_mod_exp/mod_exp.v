`timescale 1ns / 1ps

module mont_exp (
        x,
        y,
        clk,
        rst_n,
        start,
        z,
        done
    );

    parameter m = 192'hfffffffffffffffffffffffffffffffeffffffffffffffff,  //2^192-2^64-1
              k = 192, logk = 8, one = {
                  {k - 1{1'b0}}, 1'b1
              }, minus_m = {
                  1'b0, 192'h000000000000000000000000000000010000000000000001
              }, exp_k = 192'h000000000000000000000000000000010000000000000001,
              exp_2k = 192'h000000000000000100000000000000020000000000000001;
    // 192 /8 = 24
    parameter IDLE = 5'd0, LOAD = 5'd1, CE_TY = 5'd2, START_TY = 5'd3, CE_E = 5'd4, START_E = 5'd5, CHOOSE = 5'd6,
              CE_ETY = 5'd7, START_ETY = 5'd8, UPDATE = 5'd9, RE_DO = 5'd10, CE_3 = 5'd11, START_3 = 5'd12;

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
    reg [logk-1:0] count;
    wire [k-1:0] result;
    reg ce_e, ce_ty, update, load, start_mul;
    wire mul_done;
    reg [1:0] control;
    wire equal_zero, xkminusi;
    reg [4:0] current_state;
    reg [4:0] next_state;
    reg start_reg, start_pedge;
    reg mul_done_reg, mul_done_pedge;

    mod_mul f (
                operand1,
                operand2,
                clk,
                rst_n,
                start_mul,
                result,
                mul_done
            );
    assign operand1 = (control == 2'b00) ? y : e;
    assign operand2 = (control==2'b00)? exp_2k:(control==2'b01)? e:(control==2'b10)? ty: one;
    assign z = result;

    // e = e
    always @(posedge (clk)) begin : register_e
        if (load == 1'b1)
            e = exp_k;
        else if (ce_e == 1'b1)
            e = result;
    end

    // ty
    always @(posedge (clk)) begin : register_ty
        if (ce_ty == 1'b1)
            ty = result;
    end

    // xi 左移
    always @(posedge (clk)) begin : shift_register
        integer i;
        if (load == 1'b1)
            reg_x = x;
        else if (update == 1'b1)
            reg_x = {reg_x[k-2:0], 1'b0};
    end
    assign xkminusi = reg_x[k-1];

    // count
    always @(posedge (clk)) begin : counter
        if (load == 1'b1)
            count <= 8'b11000000;  //192
        else if (update == 1'b1)
            count <= count - 1'b1;
    end
    assign equal_zero = (count == {logk{1'b0}}) ? 1'b1 : 1'b0;

    // 检测start上升沿
    always @(posedge clk) begin
        start_reg   <= start;
        start_pedge <= start & ~start_reg;
    end

    // 检测mul_done上升沿
    always @(posedge clk) begin
        mul_done_reg   <= mul_done;
        mul_done_pedge <= mul_done & ~mul_done_reg;
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
            IDLE://0
                // start_pedge 有可能是未知量,最好别用next_state = start_pedge ? LOAD : IDLE;
                if (start_pedge)
                    next_state = LOAD;
                else
                    next_state = IDLE;
            LOAD://1
                next_state = CE_TY;
            CE_TY://2
                next_state = START_TY;
            START_TY://3
                next_state = mul_done_pedge ? CE_E : START_TY;
            CE_E://4
                next_state = START_E;
            START_E://5
                next_state = mul_done_pedge ? CHOOSE : START_E;
            CHOOSE://6
                next_state = xkminusi ? CE_ETY : UPDATE;
            CE_ETY://7
                next_state = START_ETY;
            START_ETY://8
                next_state = mul_done_pedge ? UPDATE : START_ETY;
            UPDATE://9
                next_state = RE_DO;
            RE_DO://10
                next_state = equal_zero ? CE_3 : CE_E;
            CE_3://11
                next_state = START_3;
            START_3://12
                next_state = start_pedge ? LOAD : START_3;
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
                ce_ty = 1'b0;
                ce_e = 1'b0;
                update = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            LOAD: begin
                control = 2'd0;
                load = 1'b1;
                ce_ty = 1'b0;
                ce_e = 1'b0;
                update = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            // control:0
            CE_TY: begin
                control = 2'd0;
                load = 1'b0;
                ce_ty = 1'b1;
                ce_e = 1'b0;
                update = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            START_TY: begin
                control = 2'd0;
                load = 1'b0;
                ce_ty = 1'b1;
                ce_e = 1'b0;
                update = 1'b0;
                start_mul = 1'b1;
                done = 1'b0;
            end
            // control:1
            CE_E: begin
                control = 2'd1;
                load = 1'b0;
                ce_ty = 1'b0;
                ce_e = 1'b1;
                update = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            START_E: begin
                control = 2'd1;
                load = 1'b0;
                ce_ty = 1'b0;
                ce_e = 1'b1;
                update = 1'b0;
                start_mul = 1'b1;
                done = 1'b0;
            end
            CHOOSE: begin
                control = 2'd0;
                load = 1'b0;
                ce_ty = 1'b0;
                ce_e = 1'b0;
                update = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            CE_ETY: begin
                control = 2'd2;
                load = 1'b0;
                ce_ty = 1'b0;
                ce_e = 1'b1;
                update = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            START_ETY: begin
                control = 2'd2;
                load = 1'b0;
                ce_ty = 1'b0;
                ce_e = 1'b1;
                update = 1'b0;
                start_mul = 1'b1;
                done = 1'b0;
            end
            UPDATE: begin
                control = 2'd0;
                load = 1'b0;
                ce_ty = 1'b0;
                ce_e = 1'b0;
                update = 1'b1;
                start_mul = 1'b0;
                done = 1'b0;
            end
            RE_DO: begin
                control = 2'd0;
                load = 1'b0;
                ce_ty = 1'b0;
                ce_e = 1'b0;
                update = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            CE_3: begin
                control = 2'd3;
                load = 1'b0;
                ce_ty = 1'b0;
                ce_e = 1'b0;
                update = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
            START_3: begin
                control = 2'd3;
                load = 1'b0;
                ce_ty = 1'b0;
                ce_e = 1'b0;
                update = 1'b0;
                start_mul = 1'b0;
                done = 1'b1;
            end
            default: begin
                control = 2'd0;
                load = 1'b0;
                ce_ty = 1'b0;
                ce_e = 1'b0;
                update = 1'b0;
                start_mul = 1'b0;
                done = 1'b0;
            end
        endcase
    end




endmodule
