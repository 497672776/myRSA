`timescale 1ns / 1ps


module mont_mult_modif(x,
                           y,
                           clk,
                           reset,
                           start,
                           z,
                           done1);
    parameter m = 192'hfffffffffffffffffffffffffffffffeffffffffffffffff,
              k = 192, logk = 8, zero = { logk {1'b0}},
              minus_m = {1'b0,192'h000000000000000000000000000000010000000000000001},
              delay = 8'b01100000, COUNT = 8'b10111111; // (k-1,logk)

    parameter S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4;

    input [k-1:0] x;
    input [k-1:0] y;
    input clk, reset, start;
    output [k-1:0] z;
    output done1;
    reg [logk-1:0] count;
    reg [logk-1:0] timer_state;
    reg [k:0] pc, psa;
    reg [k-1:0] int_x;
    wire equal_zero, time_out;
    wire [k:0] y_by_xi, half_ac, half_as, half_bc, half_bs, next_pc, next_psa, p, p_minus_m;
    wire [k+1:0] ac, as, bc, bs, long_m;
    wire xi;
    reg load, ce_p, load_timer;
    reg [2:0] current_state;
    reg [2:0] next_state;
    reg done;

    // why need it???
    assign done1 = done;

    // Func: y_by_xi = xi * y
    // input: xi, y
    // output: y_by_xi
    // Note: xi : 0 or 1, so just need to use and gate
    // Note: (k) y
    // Note: (k+1) y_by_xi
    genvar i;

    generate
        for(i = 0;i<k;i = i+1) begin:and_gates
            and a(y_by_xi[i],y[i],xi);
        end

    endgenerate
    assign y_by_xi[k] = 1'b0;

    // Func: a = p + y_by_xi
    // input: pc, psa, y_by_xi
    // output: ac, as
    // Note: (k+1) pc, psa, y_by_xi
    // Note: (k+2) ac, as
generate for(i = 0;i <= k;i = i+1) begin:first_csa
            xor x(as[i],pc[i],psa[i],y_by_xi[i]);
            wire w1,w2,w3;
            and a1(w1,pc[i],psa[i]);
            and a2(w2,pc[i],y_by_xi[i]);
            and a3(w3,psa[i],y_by_xi[i]);
            or o(ac[i+1],w1,w2,w3);
        end

    endgenerate
    assign ac[0] = 1'b0, as[k+1] = 1'b0;

    // Func: b = a + m
    // input: ac, as, long_m
    // output: bs, bc
    // Note: (k+2) ac, as, long_m
    // Note: (k+2) bs, bc
    assign long_m = {{2'b00},m};
generate for(i = 0;i <= k;i = i+1) begin:second_csa
            xor x(bs[i],ac[i],as[i],long_m[i]);
            wire w1,w2,w3;
            and a1(w1,ac[i],as[i]);
            and a2(w2,ac[i],long_m[i]);
            and a3(w3,as[i],long_m[i]);
            or o(bc[i+1],w1,w2,w3);
        end

    endgenerate
    assign bc[0] = 1'b0, bs[k+1] = ac[k+1];

    // Func: if (a mod 2) = 0 then p = a/2; else p = b/2;
    // input: (k+2) as, ac, bs, bc
    // output: (k+1) next_pc, net_psa
    assign half_as = as[k+1:1], half_ac = ac[k+1:1],
           half_bs         = bs[k+1:1], half_bc         = bc[k+1:1];
    assign next_pc  = (as[0] == 1'b0)? half_ac:half_bc;
    assign next_psa = (as[0] == 1'b0)? half_as:half_bs;

    // Func: load 清零， ce_p 赋值
    // input: (k+1) next_pc, net_psa
    // output: (k+1) pc, psa
    always@(posedge clk) begin:parallel_register
        if (load == 1'b1)begin
            pc  = { k+1 {1'b0} };
            psa = { k+1 {1'b0} };
        end
        else if (ce_p == 1'b1)begin
            pc  = next_pc;
            psa = next_psa;
        end
    end

    // Func: get p using psa and pc
    assign p = psa + pc;

    // Func: if p > m, then p_minus_m = p - m
    // input: (k+1) psa, pc
    // output: (k+1) p, p_minus_m
    // Note： p和minus_m最高位是符号位
    assign p_minus_m = p + minus_m;

    // Func： choose a value to z
    assign z = (p_minus_m[k] == 1'b0)? p[k-1:0]:p_minus_m[k-1:0];

    // Func: right shift with load and ce_p
    always@(posedge(clk)) begin:shift_register
        integer i;
        if (load == 1'b1)begin
            int_x = x;
        end
        else if (ce_p == 1'b1)begin
            for(i = 0;i <= k-2;i = i+1)begin
                int_x[i]   = int_x[i+1];
            end
            int_x[k-1] = 1'b0;
        end
    end

    // Func: get xi
    assign xi = int_x[0];

    // Func:
    assign equal_zero = (count == zero)? 1'b1:1'b0;

    // Func: counter, if load then count = 191
    always@(posedge(clk)) begin:counter
        if (load == 1'b1)begin
            count <= COUNT;
        end
        else if (ce_p == 1'b1)begin
            count <= count - 1'b1;
        end
    end

    // Func: if clk change or current state change, update some variable
    always@(clk, current_state)begin
        case(current_state)
            S0:begin
                ce_p       = 1'b0;
                load       = 1'b0;
                load_timer = 1'b1;
                done       = 1'b1;
            end

            S1:begin
                ce_p       = 1'b0;
                load       = 1'b0;
                load_timer = 1'b1;
                done       = 1'b1;
            end

            S2:begin
                ce_p       = 1'b0;
                load       = 1'b1;
                load_timer = 1'b1;
                done       = 1'b0;
            end

            S3:begin
                ce_p       = 1'b1;
                load       = 1'b0;
                load_timer = 1'b1;
                done       = 1'b0;
            end

            S4:begin
                ce_p       = 1'b0;
                load       = 1'b0;
                load_timer = 1'b0;
                done       = 1'b0;
            end

            default:begin
                ce_p       = 1'b0;
                load       = 1'b0;
                load_timer = 1'b1;
                done       = 1'b1;
            end

        endcase
    end

    // Func: if reset, current_state = s0, current_state = next_state;
    always@(posedge clk)begin
        if (reset)begin
            current_state = S0;
        end
        else begin
            current_state = next_state;
        end
    end

    // Func: update next_state
    always@(*)begin
        next_state = current_state;
        if (reset == 1'b1)begin
            next_state = S0;
        end
        else if (clk == 1'b1)begin
            case(next_state)
                S0:
                    if(start == 1'b0)begin
                        next_state = S1;
                    end

                S1:

                    if(start == 1'b1)begin
                        next_state = S2;
                    end

                S2:
                    next_state = S3;
                S3:

                    if (equal_zero == 1'b1)begin
                        next_state = S4;
                    end

                S4:

                    if (time_out == 1'b1)begin
                        next_state = S0;
                    end

                default:
                    next_state = S0;

            endcase
        end
    end

    // Func: timer_state = 96
    always@(posedge clk) begin:timer
        if (clk == 1'b1)begin
            if (load_timer == 1'b1)begin
                timer_state = delay;
            end
            else begin
                timer_state = timer_state - 1'b1;
            end
        end
    end
    assign time_out = (timer_state == zero)? 1'b1:1'b0;
endmodule





`timescale 1ns / 1ps
module divide#(
        parameter WIDTH = 3,  //计数器的位数，计数的最大值为 2**WIDTH-1
        parameter N  = 3  //分频系数，请确保 N < 2**WIDTH-1，否则计数会溢出
    ) (
        input clk,
        input rst_n,
        output clkout
    );

    reg [WIDTH-1:
         0] cnt_p,cnt_n;     //cnt_p为上升沿触发时的计数器，cnt_n为下降沿触发时的计数器
    reg clk_p,clk_n;     //clk_p为上升沿触发时分频时钟，clk_n为下降沿触发时分频时钟

    //上升沿触发时计数器的控制
    always @ (posedge clk or negedge rst_n )         //posedge和negedge是verilog表示信号上升沿和下降沿
        //当clk上升沿来临或者rst_n变低的时候执行一次always里的语句
    begin
        if(!rst_n)
            cnt_p<=0;
        else if (cnt_p==(N-1))
            cnt_p<=0;
        else
            cnt_p<=cnt_p+1;             //计数器一直计数，当计数到N-1的时候清零，这是一个模N的计数器
    end

    //上升沿触发的分频时钟输出,如果N为奇数得到的时钟占空比不是50%；如果N为偶数得到的时钟占空比为50%
    always @ (posedge clk or negedge rst_n)begin
        if(!rst_n)
            clk_p<=0;
        else if (cnt_p<(N>>1))          //N>>1表示右移一位，相当于除以2去掉余数
            clk_p<=0;
        else
            clk_p<=1;               //得到的分频时钟正周期比负周期多一个clk时钟
    end

    //下降沿触发时计数器的控制
    always @ (negedge clk or negedge rst_n)begin
        if(!rst_n)
            cnt_n<=0;
        else if (cnt_n==(N-1))
            cnt_n<=0;
        else
            cnt_n<=cnt_n+1;
    end

    //下降沿触发的分频时钟输出，和clk_p相差半个时钟
    always @ (negedge clk)begin
        if(!rst_n)
            clk_n<=0;
        else if (cnt_n<(N>>1))
            clk_n<=0;
        else
            clk_n<=1;                //得到的分频时钟正周期比负周期多一个clk时钟
    end

    assign clkout = (N==1)?clk:(N[0])?(clk_p&clk_n):clk_p;      //条件判断表达式
    //当N=1时，直接输出clk
    //当N为偶数也就是N的最低位为0，N（0）=0，输出clk_p
    //当N为奇数也就是N最低位为1，N（0）=1，输出clk_p&clk_n。正周期多所以是相与
endmodule
