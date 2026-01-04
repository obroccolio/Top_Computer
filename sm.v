module sm (
    input wire clk,      // 时钟信号 [cite: 21]
    input wire sm_en,    // 使能信号 [cite: 21]
    output reg sm        // 1位输出 [cite: 21]
);

    // 文档要求：sm 初始值为0 
    initial begin
        sm = 1'b0;
    end

    // 文档要求：clk 下降沿触发 
    always @(negedge clk) begin
        // 文档要求：当 sm_en 为 1 时，sm 取反 
        if (sm_en == 1'b1) begin
            sm <= ~sm;
        end
        // 当 sm_en 为 0 时，保持原值（隐含逻辑）
        else begin
            sm <= sm;
        end
    end

endmodule