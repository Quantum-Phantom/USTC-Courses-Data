# Lab4: Sakiko's Delivery System 实验报告

## 学生信息
- **姓名**：黄雯佩
- **学号**：PB24111630

## 1. 实验目的 
本实验旨在通过 LC-3 汇编语言实现一个递归程序。通过模拟送货员 Sakiko 在网格化城市中的路径规划问题，练习以下核心概念：<br>
**递归算法实现**：根据给定的数学递推公式计算路径总数 Routes(i, j)。<br>
**堆栈管理**：利用R6寄存器维护程序栈，实现递归过程中的参数保护与环境恢复。<br>
**算术运算**：在指令受限的 LC-3 环境中实现加法（Steps计算）和乘法（Recommendation公式计算）。

## 2. 实验过程 

### 2.1 算法实现步骤
1. **输入加载**：从内存地址x3100(N) 和 x3101(M) 加载坐标值。
2. **Steps 计算**：直接执行 N+M。
3. **递归求解 Routes**：<br>
   **Base Case**：若 i=0 或 j=0，结果为 1。<br>
   **Recursive Step**：返回 Routes(i-1, j) + Routes(i, j-1)的和。
4. **公式整合**：利用多次累加实现 Routes \times 5，随后减去 Steps得到最终推荐值。

### 2.2 难点-栈的分配与管理
#### 1. 栈帧结构设计 
为了支持深层递归并防止寄存器数据被后续调用覆盖，每个 ROUTES_RECURSIVE函数实例都会在内存中分配一个固定结构的栈帧：<br>
**R6 + 2**: 存放返回地址 (R7)，确保子程序执行完毕后能准确跳回调用点。<br>
**R6 + 1**: 存放当前递归层级的参数i(即寄存器 R0 的快照)。<br>
**R6 + 0**: 存放当前递归层级的参数j(即寄存器 R1 的快照)。<br>



#### 2. 动态分配与释放流程
**入栈分配**：子程序入口处使用 ADD R6, R6, #-3 开辟空间，并利用 STR 指令将环境信息存入栈中。<br>
**中间值保护**：由于 Routes(i, j) = Routes(i-1, j) + Routes(i, j-1)，在完成第一个分支计算后，程序执行 ADD R6, R6, #-1 将第一个结果压栈保存，防止其在第二个分支递归时被 R0 的返回值覆盖。<br>
**环境恢复**：<br>
  在执行第二个递归分支前，利用 LDR R0, R6, #2 重新从栈中读取原始参数 i。<br>
  在返回前，利用 LDR R7, R6, #2 恢复返回地址，并通过 ADD R6, R6, #3 彻底释放该层级占用的栈空间。<br>

## 3. 实验结果

通过C语言验证程序对0<=N, M<=5范围内的所有解进行了测算。以下为部分典型测试用例：<br>
**C语言代码**
<div align="center">
  <img src="./images/C语言 (1).png" alt="lab11" width="80%">
</div>

**C语言结果**
<div align="center">
  <img src="./images/C语言 (2).png" alt="lab11" width="80%">
</div>

**结果截图**
(0,0):5
<div align="center">
  <img src="./images/00 (1).png" alt="lab11" width="80%">
</div>
<div align="center">
  <img src="./images/00 (2).png" alt="lab11" width="80%">
</div>
(3,0):2
<div align="center">
  <img src="./images/30 (2).png" alt="lab11" width="80%">
</div>
<div align="center">
  <img src="./images/30 (1).png" alt="lab11" width="80%">
</div>
(4,2):69
<div align="center">
  <img src="./images/42 (2).png" alt="lab11" width="80%">
</div>
<div align="center">
  <img src="./images/42 (1).png" alt="lab11" width="80%">
</div>
(5,5):1250
<div align="center">
  <img src="./images/55 (2).png" alt="lab11" width="80%">
</div>
<div align="center">
  <img src="./images/55 (1).png" alt="lab11" width="80%">
</div>

## 4. 讨论

### 4.1 为什么递归方法效率较低？
**重复计算**：该递归算法存在大量重复子问题。例如计算 (2,2) 时，会分别计算 (1,2) 和 (2,1)，而这两者都会再次独立触发对 (1,1)的计算。随着N, M增大，计算量呈指数级增长。<br>
**堆栈开销**：每次函数调用都需要执行多次压栈（Push）和出栈（Pop）操作，涉及大量的内存访问（LDR/STR），相比简单的循环指令开销巨大。

### 4.2 如何提高程序效率？
**备忘录法**：开辟一块内存区域存储已计算出的 Routes(i, j)结果。在递归开始前先查表，若已有结果则直接返回，避免重复计算。<br>
**迭代法**：使用动态规划的思想，从(0,0)开始逐行或逐列填充表格，仅需O(N*M)的时间复杂度且无需维护复杂的函数栈。