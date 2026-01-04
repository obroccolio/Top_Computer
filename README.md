# Top_Computer - Verilog模型机设计项目

一个基于 Verilog 实现的模型机（CPU）设计项目，包含完整的硬件描述语言实现和测试文件。

## 项目概述

本项目实现了一个完整的模型机架构，包括：
- 中央处理器（CPU）核心
- 指令集架构
- 寄存器组
- 内存系统
- 控制单元

## 项目结构

### 源代码文件
- `Top_Computer.v` - 顶层模块
- `control_unit.v` - 控制单元
- `ins_decode.v` - 指令译码器
- `reg_group.v` - 寄存器组
- `pc.v` - 程序计数器
- `psw.v` - 程序状态字
- `au.v` - 算术逻辑单元
- `ir.v` - 指令寄存器
- `sm.v` - 状态机
- `mux_2_1.v`, `mux_3_1.v` - 多路选择器
- `ram_init.mif` - 内存初始化文件

### 测试文件
- `tb_Top_Computer.v` - 测试平台

### 开发环境
- Quartus 
- Verilog HDL

## 快速开始

### 编译与综合
```bash
# 使用 Quartus Prime 进行编译
# 或使用命令行工具
quartus_map --read_settings_files=on --write_settings_files=off Top_Computer -c Top_Computer
```

### 仿真测试
```bash
# 使用 ModelSim 或 QuestaSim
vsim -c -do "do Top_Computer.do"
```

## 架构说明

### 指令集架构
本模型机支持 [指令集说明待补充]

### 寄存器组
- 通用寄存器：R0-R7
- 程序计数器：PC
- 程序状态字：PSW

### 数据通路
[数据通路图描述待补充]

## 文档

详细的设计文档请参考项目中的设计文档文件（已忽略以保持仓库简洁）。

## 许可证

MIT License

## 作者

 (broccoli)

---


**注意**：本仓库仅包含源代码，编译生成的文件和详细设计文档已通过 `.gitignore` 忽略。
