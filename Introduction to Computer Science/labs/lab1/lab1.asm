.ORIG x3000    ; 添加这行：指定程序从内存地址 x3000 开始
ADD R0, R0, #0    ; 测试R0的值
    BRz ELSE          ; 如果R0=0跳转到ELSE
    ADD R0, R1, #0    ; THEN分支：R0 = R1
    BRnzp DONE        ; 无条件跳转到结束
ELSE ADD R0, R2, #0    ; ELSE分支：R0 = R2
DONE TRAP x25          ; 停止程序
.END