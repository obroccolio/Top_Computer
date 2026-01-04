module au (
    input        au_en,    // 使能信号
    input  [3:0] ac,       // 控制信号
    input  [7:0] a,        // 操作数 A (补码)
    input  [7:0] b,        // 操作数 B (补码)
    output reg [7:0] t,    // 运算结果 (需支持高阻态)
    output reg       gf    // 状态标志位
);

    always @(*) begin
        // 默认初始化
        t  = 8'hZZ; // 默认为高阻态，覆盖 en=0 或 无效 ac 的情况
        gf = 1'b0;  // 默认 gf 为 0

        if (au_en == 1'b1) begin
            case (ac)
                // --- 加法运算 ---
                // t = a + b, gf = 0
                4'b1000: begin
                    t  = a + b;
                    gf = 1'b0;
                end

                // --- 减法运算 ---
                // t = b - a, 如果 b > a (有符号) 则 gf=1
                4'b1001: begin
                    t = b - a;
                    // 使用 $signed 确保进行补码(有符号)比较
                    if ($signed(b) > $signed(a))
                        gf = 1'b1;
                    else
                        gf = 1'b0;
                end

                // --- 数据传送 (MOVE/OUT) ---
                // t = a, gf = 0
                // 对应指令: MOVA(0100), MOVB(0101), OUT(1101)
                4'b0100, 4'b0101, 4'b1101: begin
                    t  = a;
                    gf = 1'b0;
                end

                // --- 其它组合 ---
                // 根据图片要求，修改为输出高阻态
                default: begin
                    t  = 8'hZZ;
                    gf = 1'b0;
                end
            endcase
        end
        else begin
            // --- au_en = 0 ---
            // 根据图片要求，修改为输出高阻态
            t  = 8'hZZ;
            gf = 1'b0;
        end
    end

endmodule