`timescale 1ns/1ns

module tb_Top_Computer;

    // 1. 信号定义
    reg clk;
    reg rst_n;           // 复位信号 (虽然您目前逻辑没用上，但保留习惯)
    reg [7:0] input_data; // 模拟外部输入开关
    wire [7:0] output_data; // 观察外部输出

    // 2. 实例化顶层模块 (Device Under Test)
    Top_Computer uut (
        .clk(clk),
        .rst_n(rst_n),
        .input_data(input_data),
        .output_data(output_data)
    );

    // 3. 时钟生成 (50MHz, 周期 20ns)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // 4. 激励逻辑
    initial begin
        // --- 初始化 ---
        rst_n = 0;
        input_data = 8'h00; 
        #20;
        rst_n = 1; // 释放复位
        
        // --- 开始仿真 ---
        $display("=== Simulation Start: 5 + 3 Calculation ===");
        $display("Time\tPC\tIR\tState\tR0\tR1\tBUS\tOUT");
        
        // 运行足够长的时间让程序跑完
        // 我们的程序大约有 6 条指令，每条指令 2 个周期，加上取立即数多出的周期
        // 运行 1000ns 足够了
        #1000;
        
        $display("=== Simulation Finished ===");
        $stop; // 停止仿真
    end

    // 5. 监控输出 (Monitoring)
    // 利用 Verilog 的层级引用功能，直接观察模块内部信号
    // 注意：这里的路径名 (uut.u_pc.c 等) 必须与您 Top_Computer 中的实例化名称一致
    always @(posedge clk) begin
        // 仅在时钟上升沿打印，减少刷屏
        // uut.u_sm.sm: 0=取指, 1=执行
        // uut.u_pc.c: PC值
        // uut.u_regs.r0: 寄存器R0值
        $strobe("T=%0t\tPC=%h\tIR=%h\tSM=%b\tR0=%h\tR1=%h\tBUS=%h\tOut=%h", 
                $time, 
                uut.u_pc.c,       // PC 当前值
                uut.u_ir.x,       // IR 当前指令
                uut.u_sm.sm,      // 当前状态 (0:取指, 1:执行)
                uut.u_regs.r0,    // R0 内部值
                uut.u_regs.r1,    // R1 内部值
                uut.bus,          // 总线值
                output_data       // 输出端口值
        );
    end

endmodule