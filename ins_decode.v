module ins_decode (
    input        en,       // 使能信号
    input  [3:0] ir,       // 4位指令操作码 (机器码高4位)
    
    // 12个指令控制输出信号
    output reg mova,
    output reg movb,
    output reg movc,       
    output reg movd,
    output reg add,
    output reg sub,
    output reg jmp,
    output reg jg,
    output reg in1,        
    output reg out1,
    output reg movi,
    output reg halt
);

    // 组合逻辑电路
    always @(*) begin
        // 1. 初始化所有输出为0 (避免锁存器，同时处理 en=0 的情况)
        mova = 0; movb = 0; movc = 0; movd = 0;
        add  = 0; sub  = 0; jmp  = 0; jg   = 0;
        in1  = 0; out1 = 0; movi = 0; halt = 0;

        // 2. 只有当使能 en 为 1 时才进行译码
        if (en == 1'b1) begin
            case (ir)
                4'b0100: mova = 1;  // MOVA
                4'b0101: movb = 1;  // MOVB
                4'b0110: movc = 1;  // MOVC
                4'b0111: movd = 1;  // MOVD
                4'b1000: add  = 1;  // ADD
                4'b1001: sub  = 1;  // SUB
                4'b1010: jmp  = 1;  // JMP
                4'b1011: jg   = 1;  // JG
                4'b1100: in1  = 1;  // IN
                4'b1101: out1 = 1;  // OUT
                4'b1110: movi = 1;  // MOVI
                4'b1111: halt = 1;  // HALT
                default: ;          // 其它组合保持全0 (如 0000-0011)
            endcase
        end
    end

endmodule