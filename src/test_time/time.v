module time_time(
        input clk,
        input in,
        output reg pedge,
        output reg pedge2
    );
    reg in_reg;
    // assign in_copy = in;

    reg in_copy;
    always @(*) begin
        in_copy = in;
    end

    always@(posedge clk)begin
        in_reg <= in;
        pedge <= in & ~in_reg;
    end
    always@(posedge clk)begin
        in_reg <= in_copy;
        pedge2 <= in_copy & ~in_reg;
    end
endmodule

