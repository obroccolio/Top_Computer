module pc (
    input wire clk,          // 时钟信号
    input wire ld_pc,        // 装载控制信号 (Load)
    input wire in_pc,        // 自增控制信号 (Increment)
    input wire [7:0] a,      // 8位输入地址
    output reg [7:0] c       // 8位输出地址
);

    // 文档表8要求：PC初始值为 00000000
    initial begin
        c = 8'b00000000;
    end

    // 文档表8要求：clk 下降沿触发
    always @(negedge clk) begin
        // 情况1：装载模式 (ld_pc=1, in_pc=0) -> c = a
        if (ld_pc == 1'b1 && in_pc == 1'b0) begin
            c <= a;
        end
        // 情况2：自增模式 (in_pc=1, ld_pc=0) -> c = c + 1
        else if (in_pc == 1'b1 && ld_pc == 1'b0) begin
            c <= c + 1'b1;
        end
        // 其他情况：保持原值 (c <= c)
    end

endmodule