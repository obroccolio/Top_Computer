module ir (
    input wire clk,          // 时钟信号
    input wire ld_ir,        // 装载使能信号
    input wire [7:0] a,      // 8位数据输入 (来自总线)
    output reg [7:0] x       // 8位数据输出 (存入寄存器的值)
);

    // 文档表4要求：初始值为 00000000
    initial begin
        x = 8'b00000000;
    end

    // 文档表4要求：clk 下降沿触发
    always @(negedge clk) begin
        // 当 ld_ir 为 1 时，将输入 a 载入 x
        if (ld_ir == 1'b1) begin
            x <= a;
        end
        // ld_ir 为 0 时，保持原值 (Verilog 中未赋值即保持)
    end

endmodule