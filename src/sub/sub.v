module subtract(a,b,d,aBigB);
    input [3:0]a;
    input [3:0]b;
    output [3:0]d;//输出d
    output [3:0]aBigB;//输出d

    assign d = a - b;

    // Func： choose a value to z
    assign aBigB = ~d[3] ? a[3:0]:d[3:0];
endmodule

