module Top_Computer (
    input  wire       clk,          // 系统时钟
    input  wire       rst_n,        // 复位信号
    input  wire [7:0] input_data,   // 外部输入 (拨码开关)
    output wire [7:0] output_data,  // 外部输出 (LED/数码管) - 现在经过了锁存
    
    // ============================================================
    // [新增] 2. 测试/调试接口 (用于仿真观察或连接逻辑分析仪)
    // ============================================================
    output wire [7:0] test_bus,     // 观察总线实时数据
    output wire [7:0] test_pc,      // 观察当前PC值
    output wire [7:0] test_ir,      // 观察当前指令
    output wire       test_sm       // 观察状态机状态
);

    // ============================================================
    // 1. 内部连线定义 (Wires)
    // ============================================================
    
    // 数据总线
    wire [7:0] bus;

    // 数据通路连线
    wire [7:0] pc_out;      // PC输出
    wire [7:0] mux3_out;    // MUX3输出(RAM地址)
    wire [7:0] ir_out;      // IR输出
    wire [7:0] reg_s_out;   // 寄存器S口
    wire [7:0] reg_d_out;   // 寄存器D口
    wire [7:0] mux2_out;    // MUX2输出(寄存器输入)
    wire       au_gf;       // AU产生的G标志
    wire       psw_g;       // PSW存储的G标志
    
    // 控制信号
    wire       sm;          // 状态机
    wire       sm_en;
    wire       ld_pc, in_pc;
    wire       ld_ir;
    wire [1:0] s_sel;
    wire       ram_we, ram_re;
    wire       reg_we;
    wire       s0_sel;
    wire       au_en;
    wire       g_en;
    wire       in_en, out_en;

    // ============================================================
    // 2. 模块实例化 (Modules)
    // ============================================================

    // --- 2.1 控制单元 ---
    control_unit u_cu (
        .sm(sm), .ir_opcode(ir_out[7:4]), .psw_g(psw_g),
        .sm_en(sm_en),
        .ld_pc(ld_pc), .in_pc(in_pc),
        .ld_ir(ld_ir),
        .s_sel(s_sel),
        .ram_we(ram_we), .ram_re(ram_re),
        .reg_we(reg_we),
        .s0_sel(s0_sel),
        .au_en(au_en),
        .g_en(g_en),
        .in_en(in_en), .out_en(out_en)
    );

    // --- 2.2 状态机 SM ---
    sm u_sm (
        .clk(clk), .sm_en(sm_en), .sm(sm)
    );

    // --- 2.3 程序计数器 PC ---
    pc u_pc (
        .clk(clk), .ld_pc(ld_pc), .in_pc(in_pc), 
        .a(reg_s_out), 
        .c(pc_out)
    );

    // --- 2.4 地址选择器 MUX3 ---
    mux_3_1 u_mux3 (
        .a(pc_out), .b(reg_s_out), .c(reg_d_out), 
        .s(s_sel), .y(mux3_out)
    );

    // --- 2.5 存储器 RAM ---
    lpm_ram_io #(
        .LPM_WIDTH(8),
        .LPM_WIDTHAD(8),
        .LPM_NUMWORDS(256),
        .LPM_FILE("ram_init.mif"),
        .LPM_INDATA("REGISTERED"),
        .LPM_ADDRESS_CONTROL("REGISTERED"),
        .LPM_OUTDATA("UNREGISTERED")
    ) u_ram (
        .inclock (clk),
        .we      (ram_we),
        .outenab (ram_re),
        .address (mux3_out),
        .dio     (bus)
    );

    // --- 2.6 指令寄存器 IR ---
    ir u_ir (
        .clk(clk), .ld_ir(ld_ir), .a(bus), 
        .x(ir_out)
    );

    // --- 2.7 寄存器输入选择 MUX2 ---
    mux_2_1 u_mux2 (
        .a(pc_out), .b(bus), .s(s0_sel), 
        .y(mux2_out)
    );

    // --- 2.8 通用寄存器组 ---
    wire [1:0] reg_sr_addr = (ir_out[7:4] == 4'b1010 || ir_out[7:4] == 4'b1011) ? 2'b11 : 
                             (ir_out[7:4] == 4'b0110) ? 2'b00 : ir_out[1:0];
    wire [1:0] reg_dr_addr = (ir_out[7:4] == 4'b0101) ? 2'b00 : ir_out[3:2];

    reg_group u_regs (
        .clk(clk), .we(reg_we),
        .sr(reg_sr_addr), .dr(reg_dr_addr),
        .i(mux2_out), 
        .s(reg_s_out), .d(reg_d_out)
    );

    // --- 2.9 算术单元 AU ---
    au u_au (
        .au_en(au_en), .ac(ir_out[7:4]), 
        .a(reg_s_out), .b(reg_d_out),
        .t(bus), 
        .gf(au_gf)
    );

    // --- 2.10 状态寄存器 PSW ---
    psw u_psw (
        .clk(clk), .g_en(g_en), .g(au_gf), 
        .gf(psw_g)
    );

    // ============================================================
    // 3. 外部设备接口 (输入输出控制)
    // ============================================================
    
    // --- 3.1 输入接口 (IN指令) ---
    // 三态门逻辑：只有当执行 IN 指令 (in_en=1) 时，输入数据才挂上总线
    // 否则为高阻态，避免干扰总线上的其他数据传输
    assign bus = (in_en) ? input_data : 8'bzzzzzzzz;
    
    // --- 3.2 [修改] 输出接口 (OUT指令) ---
    // 增加一个输出寄存器，实现“保持”功能
    reg [7:0] out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_reg <= 8'h00; // 复位清零
        end
        else if (out_en) begin
            // 只有当控制单元发出 out_en 信号时 (即执行 OUT 指令期间)
            // 才将总线上的数据锁存到输出寄存器中
            out_reg <= bus;
        end
        // 其他时候 out_reg 保持原值不变
    end

    // 将锁存器的值输出到外部引脚
    assign output_data = out_reg;

    // ============================================================
    // 4. [新增] 调试信号连线
    // ============================================================
    assign test_bus = bus;       // 实时监视总线
    assign test_pc  = pc_out;    // 实时监视PC
    assign test_ir  = ir_out;    // 实时监视指令
    assign test_sm  = sm;        // 实时监视状态机

endmodule