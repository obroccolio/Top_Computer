module control_unit (
    input  wire       sm,          // 状态机状态 (0:取指, 1:执行)
    input  wire [3:0] ir_opcode,   // 指令操作码 (来自IR的高4位)
    input  wire       psw_g,       // 标志位 G (来自PSW)
    
    // 输出给各个部件的控制信号
    output wire       sm_en,       // 状态机翻转使能
    output wire       ld_pc,       // PC 装载 (跳转)
    output wire       in_pc,       // PC 自增
    output wire       ld_ir,       // IR 装载
    output wire [1:0] s_sel,       // MUX3 选择 (RAM地址源)
    output wire       ram_we,      // RAM 写使能
    output wire       ram_re,      // RAM 读使能
    output wire       reg_we,      // 通用寄存器写使能
    output wire       s0_sel,      // MUX2 选择 (寄存器输入源)
    output wire       au_en,       // AU 输出三态门使能
    output wire       g_en,        // PSW 写使能
    output wire       in_en,       // 输入设备使能
    output wire       out_en       // 输出设备使能
);

    // --- 内部信号：指令译码结果 ---
    wire is_mova, is_movb, is_movc, is_movd;
    wire is_add, is_sub;
    wire is_jmp, is_jg;
    wire is_in, is_out, is_movi, is_halt;

    // --- 1. 实例化指令译码器 (ins_decode) ---
    // 假设 ins_decode 模块已存在于您的工程中
    ins_decode u_decode (
        .en   (1'b1),         // 始终允许译码
        .ir   (ir_opcode),    // 输入操作码
        .mova (is_mova), .movb (is_movb), .movc (is_movc), .movd (is_movd),
        .add  (is_add),  .sub  (is_sub),
        .jmp  (is_jmp),  .jg   (is_jg),
        .in1  (is_in),   .out1 (is_out), .movi (is_movi), .halt (is_halt)
    );

    // --- 2. 组合逻辑生成控制信号 ---
    // (基于之前的分析逻辑)

    // SM_EN: 遇到 HALT 停机
    assign sm_en = !is_halt; 

    // PC 控制
    assign ld_pc = sm & (is_jmp | (is_jg & psw_g)); // 跳转
    assign in_pc = (~sm) | (sm & is_movi);          // 取指或跳过立即数时 +1

    // RAM 地址选择 (MUX3)
    // 10: D口(MOVB), 01: S口(MOVC), 00: PC(默认)
    assign s_sel[1] = sm & is_movb; 
    assign s_sel[0] = sm & is_movc;

    // RAM 读写
    assign ram_we = sm & is_movb;
    assign ram_re = (~sm) | (sm & (is_movc | is_movi));

    // IR 控制
    assign ld_ir = ~sm; // 仅在取指周期写入

    // 寄存器写控制 (RegFile WE)
    assign reg_we = sm & (is_mova | is_movc | is_movd | is_movi | is_add | is_sub | is_in);

    // 寄存器输入源选择 (MUX2)
    // 0: PC (MOVD), 1: BUS (其他)
    assign s0_sel = ~(sm & is_movd);

    // AU 总线驱动控制
    assign au_en = sm & (is_mova | is_movb | is_out | is_add | is_sub);

    // PSW 标志位控制
    assign g_en = sm & is_sub;

    // I/O 控制
    assign in_en  = sm & is_in;
    assign out_en = sm & is_out;

endmodule