module psw (
    input wire clk,      // 时钟信号
    input wire g_en,     // 写使能信号
    input wire g,        // 1位数据输入
    output reg gf        // 1位数据输出 (标志位)
);

    // 文档表6要求：初始值为 0
    initial begin
        gf = 1'b0;
    end

    // 文档表6要求：clk 下降沿触发
    always @(negedge clk) begin
        // 当 g_en 为 1 时，将输入 g 写入 gf
        if (g_en == 1'b1) begin
            gf <= g;
        end
        // 否则保持原值
    end

endmodule