module mux_2_1 (
    input  [7:0] a,  // 8位数据输入 a
    input  [7:0] b,  // 8位数据输入 b
    input        s,  // 1位选择输入 (注意这里只有1位)
    output [7:0] y   // 8位数据输出
);

    // 功能描述：当 s=1 时输出 b，否则(s=0) 输出 a
    // 对应文档表4的功能
    assign y = (s == 1'b1) ? b : a;

endmodule