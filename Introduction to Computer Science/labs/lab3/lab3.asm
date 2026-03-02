; Lab3: Modulo 7

    .ORIG x3000
MAIN
    AND R2, R2, #0  ;用R2存储当前状态，初始化状态为0

INPUT_LOOP
    LDI R1, KBSR    ;读取字符到R0
    BRzp INPUT_LOOP
    LDI R0, KBDR

    LD  R3, Y_CHECK ;检查输入是否为y,用LD！
    ADD R3, R0, R3
    BRz OUTPUT_RESULT

    LD  R3, ZERO_CHECK
    ADD R3, R0, R3
    BRz PROCESS_ZERO

    LD  R3, ONE_CHECK
    ADD R3, R0, R3
    BRz PROCESS_ONE

    BRnzp INPUT_LOOP

PROCESS_ONE ;处理输入为1
    ADD R4, R2, R2
    ADD R4, R4, #1
    BRnzp STATE_TRANSITION

PROCESS_ZERO;处理输入为0
    ADD R4, R2, R2
    BRnzp STATE_TRANSITION

STATE_TRANSITION
MOD_LOOP
    ADD R4, R4, #-7
    BRzp MOD_LOOP     ; 如果≥0，继续减
    ADD R4, R4, #7    ; 加回最后一次多减的7
    ADD R2, R4, #0    ; 保存新状态
    BRnzp ECHO_CHAR

ECHO_CHAR
    LDI R1, DSR
    BRzp ECHO_CHAR  ;首位为1的时候可以显示
    STI R0, DDR

    BRnzp INPUT_LOOP

OUTPUT_RESULT
    LD  R0, ASCII_OFFSET
    ADD R0, R0, R2

OT  LDI R1, DSR
    BRzp OT         ;不能用OUT,OUT是一个TRAP指令的伪操作码
    STI R0, DDR

    HALT

KBSR    .FILL xFE00     ;键盘状态寄存器
KBDR    .FILL xFE02     ;键盘数据寄存器
DSR     .FILL xFE04     ;display status register
DDR     .FILL xFE06    

Y_CHECK     .FILL #-121     ;-'y'的ASCII值 (121)  
ZERO_CHECK  .FILL #-48
ONE_CHECK   .FILL #-49
ASCII_OFFSET    .FILL #48   ; '0'的ASCII值

    .END