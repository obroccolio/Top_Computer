module Top_Computer (
    input wire clk,             // 系统时钟
    input wire rst_n,           // 复位信号 (虽然您的模块多为initial初始化，但顶层建议保留复位扩展)
    input wire [7:0] input_data,// 外部输入设备数据 (IN指令)
    output wire [7:0] output_data // 外部输出设备数据 (OUT指令)
);

    // ============================================================
    // 1. 内部连线定义 (Wires)
    // ============================================================
    
    // --- 数据总线 (最重要的部分) ---
    wire [7:0] bus;             // 8位双向总线

    // --- 数据通路信号 ---
    wire [7:0] pc_out;          // PC 输出地址
    wire [7:0] mux3_out;        // 3-1 MUX 输出 (RAM地址)
    wire [7:0] ir_out;          // IR 指令寄存器输出
    wire [7:0] reg_s_out;       // 通用寄存器 S口输出
    wire [7:0] reg_d_out;       // 通用寄存器 D口输出
    wire [7:0] mux2_out;        // 2-1 MUX 输出 (写回寄存器的数据)
    wire [7:0] au_out;          // AU 运算结果 (连接到总线) - 注：AU模块内部已处理高阻态，这里仅作逻辑引用
    
    // --- 状态与标志 ---
    wire sm;                    // 状态机输出 (0:取指, 1:执行)
    wire psw_g;                 // PSW 状态标志 G
    wire au_gf;                 // AU 产生的 G 标志

    // --- 指令译码信号 (来自 ins_decode) ---
    wire is_mova, is_movb, is_movc, is_movd;
    wire is_add, is_sub;
    wire is_jmp, is_jg;
    wire is_in, is_out, is_movi, is_halt;

    // --- 控制信号 (由组合逻辑生成) ---
    wire ld_pc, in_pc;          // PC控制
    wire ld_ir;                 // IR控制
    wire sm_en;                 // 状态机控制
    wire ram_we, ram_re;        // RAM读写
    wire reg_we;                // 寄存器写
    wire [1:0] s_sel;           // MUX3 选择 (RAM地址源)
    wire s0_sel;                // MUX2 选择 (寄存器写入源)
    wire au_en;                 // AU使能
    wire g_en;                  // PSW使能
    wire in_en, out_en;         // 输入输出使能
    wire [3:0] au_ac;           // AU操作码

    // ============================================================
    // 2. 控制逻辑单元 (Control Unit Logic)
    //    这里将 "SM状态" + "指令译码" 转换为 "具体控制信号"
    // ============================================================
    
    // 2.1 实例化指令译码器
    // 注意：IR的输出 ir_out[7:4] 是操作码，送入译码器
    ins_decode u_decode (
        .en   (1'b1),           // 始终使能译码
        .ir   (ir_out[7:4]),    // 取高4位操作码
        .mova (is_mova), .movb (is_movb), .movc (is_movc), .movd (is_movd),
        .add  (is_add),  .sub  (is_sub),
        .jmp  (is_jmp),  .jg   (is_jg),
        .in1  (is_in),   .out1 (is_out), .movi (is_movi), .halt (is_halt)
    );

    // 2.2 组合逻辑生成控制信号 (核心难点，基于指导书分析)
    
    // SM_EN: 只要不是 HALT 指令，通常都允许状态翻转
    assign sm_en = !is_halt; 

    // 取指周期 (Fetch Cycle, SM=0) 的默认动作:
    // 读RAM(RE=1), 选PC作地址(S=00), 写IR(LD_IR=1), PC加1(IN_PC=1)
    
    // --- PC 控制 ---
    // LD_PC (跳转): 仅在执行周期(sm=1) 且 (是JMP指令 或 (是JG指令且G=1))
    assign ld_pc = sm & (is_jmp | (is_jg & psw_g));
    // IN_PC (PC+1): 在取指周期(sm=0) 或者 (执行周期 且 是MOVI指令-因为MOVI是双字节)
    assign in_pc = (~sm) | (sm & is_movi);

    // --- RAM 地址选择 (MUX3) ---
    // 00: PC (取指 或 MOVI取立即数), 01: S口 (MOVC), 10: D口 (MOVB写内存, 指导书说用R0即D口?)
    // 修正：根据MOVB定义 (Rs)->(R0)，地址在R0。R0通常由 D口 或 S口输出。
    // 指导书表2：MOVB M, Rs -> (Rs) -> (R0)。
    // 查看ins_decode不需要改，但这里MUX逻辑要对。
    // sm=0 -> 00 (PC)
    // sm=1 & MOVI -> 00 (PC)
    // sm=1 & MOVC -> 01 (S口, R0做源) -> 实际上 MOVC Rd, M 是 ((R0))->Rd，R0作地址。
    // sm=1 & MOVB -> 10 (D口, R0做目的地址寄存器? 这里的连线取决于 reg_group 的端口连接)
    assign s_sel[1] = sm & is_movb; 
    assign s_sel[0] = sm & is_movc;

    // --- RAM 读写 ---
    assign ram_we = sm & is_movb;       // MOVB 时写内存
    assign ram_re = (~sm) | (sm & (is_movc | is_movi)); // 取指 或 读数(MOVC) 或 读立即数(MOVI)

    // --- IR 控制 ---
    assign ld_ir = ~sm;                 // 仅在取指周期写入IR

    // --- 寄存器写控制 (WE) ---
    // 写寄存器发生在：MOVA, MOVC, MOVD, MOVI, ADD, SUB, IN
    assign reg_we = sm & (is_mova | is_movc | is_movd | is_movi | is_add | is_sub | is_in);

    // --- 寄存器输入源选择 (MUX2) ---
    // 0: PC (MOVD R3, PC), 1: BUS (其他大多数情况)
    assign s0_sel = ~(sm & is_movd);    // 只有 MOVD 时选 0(PC)，其他(包括取指默认)选1(BUS)

    // --- AU 控制 ---
    // AU输出到总线：MOVA, MOVB, OUT, ADD, SUB
    // 注意：MOVB 和 OUT 虽然不写回寄存器，但需要数据上总线
    assign au_en = sm & (is_mova | is_movb | is_out | is_add | is_sub);
    // AU操作码直接映射 IR 的高4位 (简单处理，因为AU操作码定义与指令码基本一致)
    // 或者根据 AU 模块定义：ADD=1000, SUB=1001, MOV/OUT=0100/0101/1101
    assign au_ac = ir_out[7:4]; 

    // --- PSW 控制 ---
    assign g_en = sm & is_sub;          // 只有 SUB 指令更新 G 标志

    // --- I/O 控制 ---
    assign in_en  = sm & is_in;         // IN 指令开启输入缓冲
    assign out_en = sm & is_out;        // OUT 指令开启输出锁存(通常外部设备自行锁存)

    // ============================================================
    // 3. 数据通路模块实例化 (Datapath Instantiation)
    // ============================================================

    // 3.1 程序计数器 PC
    pc u_pc (
        .clk(clk), .ld_pc(ld_pc), .in_pc(in_pc), 
        .a(reg_s_out), // JMP/JG 跳转地址来自 R3 (S口)
        .c(pc_out)
    );

    // 3.2 地址选择器 MUX3 (提供 RAM 地址)
    // 00:PC, 01:S(R0), 10:D(R0) -- 根据 MOVC/MOVB 区别
    mux_3_1 u_mux3 (
        .a(pc_out), .b(reg_s_out), .c(reg_d_out), 
        .s(s_sel), .y(mux3_out)
    );

    // ============================================================
    // 3.3 存储器 RAM (修正参数配置)
    // ============================================================
    lpm_ram_io u_ram (
        .inclock (clk),          
        .we      (ram_we),       
        .outenab (ram_re),       
        .address (mux3_out),     
        .dio     (bus)           
    );
    
    defparam u_ram.LPM_WIDTH = 8;
    defparam u_ram.LPM_WIDTHAD = 8;
    defparam u_ram.LPM_NUMWORDS = 256;
    defparam u_ram.LPM_FILE = "ram_init.mif";
    defparam u_ram.LPM_INDATA = "REGISTERED";            // 数据输入保持 REGISTERED
    defparam u_ram.LPM_ADDRESS_CONTROL = "REGISTERED";   // 【关键修改】改为 REGISTERED
    defparam u_ram.LPM_OUTDATA = "UNREGISTERED";         // 数据输出保持 UNREGISTERED
    
    
    // 3.4 指令寄存器 IR
    ir u_ir (
        .clk(clk), .ld_ir(ld_ir), .a(bus), 
        .x(ir_out)
    );

    // 3.5 状态机 SM
    sm u_sm (
        .clk(clk), .sm_en(sm_en), .sm(sm)
    );

    // 3.6 寄存器组输入选择 MUX2
    // 选择: 0 -> PC (MOVD), 1 -> BUS
    mux_2_1 u_mux2 (
        .a(pc_out), .b(bus), .s(s0_sel), 
        .y(mux2_out)
    );

    // 3.7 通用寄存器组
    // 地址连接：
    // Rs (源) 通常在 IR[1:0]
    // Rd (目的) 通常在 IR[3:2]
    // 特殊情况：MOVI/MOVC/MOVB 中 R0 的位置需要根据指令格式微调，但通常 IR 结构固定
    // 比如 MOVB M, Rs -> Rs 在 [1:0], M(R0) 隐含。
    // JMP R3 -> R3 隐含 (11)。
    // 这里为了简化，假设 ins_decode 配合 IR 逻辑足够聪明，或者我们在连线上做硬编码选择
    // 根据文档：
    // JMP/JG: R3 -> PC. R3 固定为 11.
    // MOVB/MOVC: 使用 R0.
    wire [1:0] reg_sr_addr = (is_jmp | is_jg) ? 2'b11 : 
                             (is_movc) ? 2'b00 : ir_out[1:0];
    
    wire [1:0] reg_dr_addr = (is_movb) ? 2'b00 : ir_out[3:2];

    reg_group u_regs (
        .clk(clk), .we(reg_we),
        .sr(reg_sr_addr), .dr(reg_dr_addr),
        .i(mux2_out), 
        .s(reg_s_out), .d(reg_d_out)
    );

    // 3.8 算术逻辑单元 AU
    // 输出直接挂总线，利用 au_en 控制高阻态
    au u_au (
        .au_en(au_en), .ac(au_ac), 
        .a(reg_s_out), .b(reg_d_out), // A接源, B接目的 (注意减法方向: Rd-Rs = D-S?)
        // 指导书 SUB Rd, Rs => (Rd)-(Rs). 所以 AU 输入 a应接D, b应接S? 
        // 您的AU代码: t = b - a (1001). 
        // 所以如果 AU.a 接 S, AU.b 接 D => D - S = Rd - Rs. 正确。
        .t(bus),      // 输出到总线
        .gf(au_gf)
    );

    // 3.9 状态寄存器 PSW
    psw u_psw (
        .clk(clk), .g_en(g_en), .g(au_gf), 
        .gf(psw_g)
    );

    // ============================================================
    // 4. 总线上的其他驱动 (Tri-state Logic)
    // ============================================================
    
    // 输入设备 IN 指令驱动总线
    assign bus = (in_en) ? input_data : 8'bzzzzzzzz;
    
    // 输出设备连接总线 (只是读取总线数据)
    assign output_data = bus;

endmodule


