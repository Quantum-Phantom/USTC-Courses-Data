## Lab 2 Report
**姓名：** 黄雯佩  
**学号：** PB24111630

---

### 实验目的与内容
* 复习 Verilog 语法。
* 学习并应用寄存器堆（Register File）、ALU 及仿真技术。
* 学习如何实例化 IP 核。

---

### 逻辑设计

#### 1. REG_FILE
<div align="center">
  <img src="./images/21.png" width="50%" />
</div>

**设计要点**：寄存器 `x0` 恒保持为 0。

#### 2. ALU
<div align="center">
  <img src="./images/22.png" width="50%" />
</div>

**设计要点**：使用 `$signed` 关键字来处理有符号数的算术运算。

#### 3. 在线计算器
<div align="center">
  <img src="./images/23.png" width="50%" />
</div>

---

### 仿真结果与分析

#### 1. 仿真运行结果
以下是各模块仿真波形及分析：

**REG_FILE 仿真结果：**
<div align="center">
  <img src="./images/1.png" width="50%" />
</div>

**ALU 仿真结果：**
<div align="center">
  <img src="./images/2.png" width="50%" />
</div>

#### 2. 仿真测试文件说明（选做）
<div align="center">
  <img src="./images/32.png" width="50%" />
</div>

**测试策略**：在完成所有标准运算指令的测试后，通过自动遍历逻辑，测试了所有未定义的指令，以验证电路的健壮性。

---

### 电路设计与分析
**RTL 电路图：**
<div align="center">
  <img src="./images/4.png" width="50%" />
</div>

---

### 测试结果与分析
通过 FPGA 开发板进行上板测试，验证设计的正确性：

**案例 1：加法运算**
1 + (-2) = -1
<div align="center">
  <img src="./images/41.png" width="50%" />
</div>

**案例 2：移位运算**
10<<4
<div align="center">
  <img src="./images/42.png" width="50%" />
</div>

---

### 总结

1. **实验总结与收获**：
   * 重新巩固了 Verilog 硬件描述语言的语法细节。
   * 掌握了 FPGA 在线调试与测试的基本流程。
   * 对计算机组成原理中数据通路（Datapath）的构建有了更直观的理解。

2. **建议与反馈**：
   * 建议后续实验可以提供统一的 Markdown 报告模板，以便同学们规范文档格式。