module mux_3_1 (
    input  [7:0] a,   // 8位数据输入 a 
    input  [7:0] b,   // 8位数据输入 b 
    input  [7:0] c,   // 8位数据输入 c 
    input  [1:0] s,   // 2位选择输入 
    output reg [7:0] y // 8位数据输出 (在always块中赋值需定义为reg) 
);

    // 组合逻辑电路，敏感列表使用 * 表示对所有输入敏感
    always @(*) begin
        case (s)
            2'b00: y = a;      // 当 s=00 时，输出 a 
            2'b01: y = b;      // 当 s=01 时，输出 b 
            2'b10: y = c;      // 当 s=10 时，输出 c 
            default: y = a;    // 其它组合 (如 11)，输出 a 
        endcase
    end

endmodule