; Lab2: Hofstadter Q-sequence Implementation

        .ORIG x3000

MAIN    ;主程序

        LDI R0, INPUT_N ;从x3100读取n到R0
        ST  R0, N       ; 保存n到内存N的位置

        ADD R0, R0, #0  ;显式地更新条件码!
        BRnz CASE_N ;如果N为0或负数，跳转到CASE_N
        ADD R0, R0, #-2
        BRnz BASE_CASE  ;如果n<=2，跳转到特殊情况处理

        JSR INIT_Q      ; 初始化Q[1]和Q[2]

        JSR COMP_Q      ;计算Q[3]到Q[n]

        JSR STORE_RESULT;存储结果
        BR HALT_PROGRAM

;n<=0 的情况处理
CASE_N  
        AND R0, R0, #0
        STI R0, OUTPUT  ;如果N为0或负数存入0
        BR HALT_PROGRAM
;n=1||n=2的情况处理
BASE_CASE  
        AND R0, R0, #0
        ADD R0, R0, #1
        STI R0, OUTPUT
        BR HALT_PROGRAM
; 初始化Q[1]和Q[2] 
INIT_Q     
        LEA R1, Q_ARRAY ; R1指向Q数组起始地址，直接用标签就行！
        AND R2, R2, #0
        ADD R2, R2, #1
        STR R2, R1, #0  ;Q[1] = 1 (偏移量0)
        STR R2, R1, #1  ;Q[2] = 1 (偏移量1)

        RET             ;从子程序（Subroutine）返回到调用它的主程序,无条件跳转回寄存器R7中保存的返回地址

;计算Q[3]到Q[n]
;主循环
COMP_Q  
        ST R7, SAVE_R7_MAIN
        AND R3, R3, #0  
        ADD R3, R3, #3  ; 初始化循环计数器i=3
        ST  R3, I
COMPUTE_LOOP    ;循环
        LD R0, N;       ;R0 = n,后序子程序调用时可能会更改R0，所以要重新加载

        NOT R4, R3
        ADD R4, R4, #1
        ADD R4, R0, R4  ;n - i
        BRn END_COMPUTE ;如果i > n，结束循环

        JSR GET_Q_I     ;标号、变量名不能有括号
        ADD R3, R3, #1  ;循环中R3(i)递增
        ST R3, I

        BR COMPUTE_LOOP
END_COMPUTE
        LD  R7, SAVE_R7_MAIN
        RET
;获得Q(i)
GET_Q_I
        ST R7, SAVE_R7_COMPQ

        ;获得Q(t1)
        JSR GET_PREV_Q  ;加载Q(i-1)和Q(i-2)

        LD  R0, I
        ADD R1, R5, #0  ;把Q(i-1)加载到R1
        NOT R2, R1
        ADD R2, R2, #1  ;R2 = -Q(i-1)
        ADD R2, R0, R2  ;R2 = i - Q(i-1) = t1
        ST  R2, TEMP1   ;把i - Q(i-1) = t1存入TEMP1

        JSR GET_Q_BY_VALUE     ;计算Q(t1)，结果在R0
        ST  R0, TEMP1   ;把Q(t1)存到TEMP1

        ;获得Q(t2)
        LD  R0, I 
        ADD R1, R6, #0  ;把Q(i-2)加载到R1
        NOT R2, R1
        ADD R2, R2, #1  ;R2 = -Q(i-2)
        ADD R2, R2, R0  ;R2 = i - Q(i-2) = t2
        ST  R2, TEMP2   ;把i - Q(i-2) = t2存入TEMP2

        JSR GET_Q_BY_VALUE     ;计算Q(t2)，结果在R0
        ST  R0, TEMP2   ;把Q(t2)存到TEMP1

        ;Q(t1)+Q(t2)
        LD  R1, TEMP1   ;R1=Q(t1)
        ADD R0, R1, R0  ;R0=Q(t1)+Q(t2)

        JSR STORE_Q_I   ;存储Q(i)到数组

        LD  R7, SAVE_R7_COMPQ   ;恢复R7
        RET
;获得Q(i-1)和Q(i-2),存入Q1_VAL、Q2_VAL
GET_PREV_Q
        ST  R7, SAVE_R7_GETPQ

        ;获得Q(i-1)
        LD  R0, I
        ADD R1, R0, #-2     ;Q(i-1)的索引i-2 (因为数组从0开始，Q[1]在偏移0)
        BRn INDEX_ERROR     ;索引检查

        JSR GET_Q_BY_INDEX  ;得到的Q(i-1)在R0
        ADD R5, R0, #0      ;用R5存储Q(i-1)

        ;获得Q(i-2)
        LD  R0, I 
        ADD R1, R0, #-3     ;Q(i-2)的索引i-3(因为数组从0开始，Q[1]在偏移0)
        BRn INDEX_ERROR

        JSR GET_Q_BY_INDEX  ;得到的Q(i-2)在R0
        ADD R6, R0, #0    ;用R6存储Q(i-2)

        LD R7, SAVE_R7_GETPQ
        RET
;依据R1存储的索引得到R0=Q()
GET_Q_BY_INDEX
        LEA R2, Q_ARRAY
        ADD R2, R2, R1  ; R2指向Q数组
        LDR R0, R2, #0  ;计算元素地址
        RET
;从内存中获得Q()
GET_Q_BY_VALUE               ;ti在R2中
        ST R7, SAVE_R7_GETQI ; 保存返回地址
        
        ; 边界检查：1 <= index <= 100
        ADD R1, R2, #-1
        BRn INVALID_INDEX    ; 如果index < 1
        
        ADD R1, R1, #-15
        ADD R1, R1, #-15
        ADD R1, R1, #-15
        ADD R1, R1, #-15
        ADD R1, R1, #-15
        ADD R1, R1, #-15
        ADD R1, R1, #-10
        BRp INVALID_INDEX    ; 如果index > 100
        
        ; 转换为0-based索引
        ADD R1, R2, #-1      ;存入R1
        JSR GET_Q_BY_INDEX
        BR END_GET_Q_VALUE
INVALID_INDEX
        AND R0, R0, #0       ; 索引无效，返回0
END_GET_Q_VALUE
        LD R7, SAVE_R7_GETQI ; 恢复返回地址
        RET
;存储Q(i)到数组(Q(i)在R0)
STORE_Q_I
        LD  R1, I 
        ADD R1, R1, #-1 ;转换为0-based索引
        LEA R2, Q_ARRAY
        ADD R2, R2, R1  ;计算存储地址
        STR R0, R2, #0  ;存储Q(i)
        RET
;存储最终结果
STORE_RESULT
        LD  R0, N
        ADD R1, R0, #-1
        LEA R2, Q_ARRAY
        ADD R2, R2, R1
        LDR R0, R2, #0
        STI R0, OUTPUT
        RET

INDEX_ERROR
        HALT
HALT_PROGRAM
        HALT
;内存分配&变量定义
INPUT_N .FILL x3100     ; 输入参数地址
OUTPUT  .FILL x3101     ; 输出结果地址

Q_ARRAY .BLKW #100    ; Q[1]到Q[100]的存储空间

N        .FILL #0        ; 存储输入的n值 N的位置初始化为#0 
I        .FILL #0        ; 循环计数器i
TEMP1    .FILL #0        ; 临时变量1
TEMP2    .FILL #0        ; 临时变量2
Q1_VAL   .FILL #0        ; Q(i-1)的值
Q2_VAL   .FILL #0        ; Q(i-2)的值

;==R7保存寄存器（用于子程序调用）
SAVE_R7_MAIN   .FILL #0
SAVE_R7_COMPQ  .FILL #0
SAVE_R7_GETQI  .FILL #0
SAVE_R7_GETPQ  .FILL #0


        .END