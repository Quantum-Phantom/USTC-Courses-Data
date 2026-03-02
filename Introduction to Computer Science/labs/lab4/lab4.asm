; Lab4: Sakiko's Delivery System

    .ORIG x3000

    LDI R0, INPUT_N
    LDI R1, INPUT_M
    LD  R6, STACK

    ADD R2, R0, R1      ;R2=Steps(N,M)
    ST  R2, TEMP_STEPS

    JSR ROUTES_RECURSIVE

    ADD R1, R0, #0     ; R1 = Routes
    ADD R0, R1, R1     ; R0 = 2 * Routes
    ADD R0, R0, R0     ; R0 = 4 * Routes
    ADD R0, R0, R1     ; R0 = 5 * Routes
    LD  R2, TEMP_STEPS ; 取回 Steps
    NOT R2, R2
    ADD R2, R2, #1     ; R2 = -Steps
    ADD R0, R0, R2     ; R0 = 5 * Routes - Steps

    STI R0, RESULT  
    TRAP x25


; 递归子程序: 输入R0=i, R1=j  输出: R0=result
ROUTES_RECURSIVE
    ADD R6, R6, #-3     ;堆栈是向下增长的,每次递归向下三个位置
    STR R7, R6, #2
    STR R0, R6, #1      ;R6+1:(N)
    STR R1, R6, #0      ;R6+0:(M)

    ADD R0, R0, #0      ;基准情况：i == 0 or j == 0 -> return 1
    BRz BASE_CASE
    ADD R1, R1, #0
    BRz BASE_CASE

    ;计算 Routes(i-1, j)
    LDR R0, R6, #1      
    ADD R0, R0, #-1     ;R0:i=i-1
    LDR R1, R6, #0      ;R1:j
    JSR ROUTES_RECURSIVE
    ADD R6, R6, #-1     ;栈增大一位的空间
    STR R0, R6, #0      ;将第一个递归结果压栈

    ;计算 Routes(i, j-1)
    LDR R0, R6, #2      ;恢复原始 i
    LDR R1, R6, #1      ;恢复原始 j
    ADD R1, R1, #-1     ; R1:j = j - 1
    JSR ROUTES_RECURSIVE

    LDR R1, R6, #0     ; 取出第一个结果
    ADD R0, R0, R1     ; R0 = result1 + result2
    ADD R6, R6, #1     ; 释放临时存储结果的栈空间
    BR  RETURN_PROC


BASE_CASE
    AND R0, R0, #0
    ADD R0, R0, #1      ;返回 1

RETURN_PROC             
    LDR R7, R6, #2
    ADD R6, R6, #3
    RET


; --- 数据区 ---
TEMP_STEPS .FILL x0000
STACK      .FILL x6000    ; 堆栈起始地址 [cite: 56]
INPUT_N    .FILL x3100    ; 输入 N 的地址 [cite: 60]
INPUT_M    .FILL x3101    ; 输入 M 的地址 [cite: 64]
RESULT     .FILL x3200    ; 结果存储地址 [cite: 68]
.END