module reg_group (
    input wire clk,          // 时钟
    input wire we,           // 写使能
    input wire [1:0] sr,     // 源寄存器选择 (用于输出 s)
    input wire [1:0] dr,     // 目的寄存器选择 (用于输出 d 和 写入)
    input wire [7:0] i,      // 数据输入
    output reg [7:0] s,      // 源端口输出
    output reg [7:0] d       // 目的端口输出
);

    // 定义内部 4 个 8位寄存器
    reg [7:0] r0;
    reg [7:0] r1;
    reg [7:0] r2;
    reg [7:0] r3;

    // 初始化 (便于仿真观察)
    initial begin
        r0 = 8'h01;
        r1 = 8'h00;
        r2 = 8'h00;
        r3 = 8'h07;
    end

    // --- 1. 写操作 (时序逻辑，下降沿) ---
    always @(negedge clk) begin
        if (we == 1'b1) begin
            case (dr)
                2'b00: r0 <= i;
                2'b01: r1 <= i;
                2'b10: r2 <= i;
                2'b11: r3 <= i;
            endcase
        end
    end

    // --- 2. 读操作 (组合逻辑，电平触发) ---
    // 一旦 sr 或 dr 变化，或者寄存器内部值变化，输出立即更新
    
    // S 端口输出逻辑
    always @(*) begin
        case (sr)
            2'b00: s = r0;
            2'b01: s = r1;
            2'b10: s = r2;
            2'b11: s = r3;
            default: s = 8'h00;
        endcase
    end

    // D 端口输出逻辑
    always @(*) begin
        case (dr)
            2'b00: d = r0;
            2'b01: d = r1;
            2'b10: d = r2;
            2'b11: d = r3;
            default: d = 8'h00;
        endcase
    end

endmodule