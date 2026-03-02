## lab1 report
#### PB24111630黄雯佩
### 算法
x3000: 0001 000 000 0 00000;ADD R0 R0 R0                        <br>
x3001: 0000 010 000000010;  BRz ELSE 如果R0为0，跳转到ELSE<br>
x3002: 0001 000 001 1 00000;ADD R0 R1 #0 <br>
x3003: 0000 111 000000001;  BRnzp HALT 无条件跳转到HALT<br>
;ELSE<br>
x3004: 0001 000 010 1 00000;ADD R0 R2 #0<br>
;HALT<br>
x3005: 1111 000000100101;   TRAP 25<br>
转换成汇编语言后<br>
.ORIG x3000    ; 指定程序从内存地址 x3000 开始<br>
ADD R0, R0, #0    ; 测试R0的值<br>
    BRz ELSE          ; 如果R0=0跳转到ELSE<br>
    ADD R0, R1, #0    ; THEN分支：R0 = R1<br>
    BRnzp DONE        ; 无条件跳转到结束<br>
ELSE ADD R0, R2, #0    ; ELSE分支：R0 = R2<br>
DONE TRAP x25          ; 停止程序<br>
.END
### 结果截图
<div align="center">
  <img src="./images/lab11.png" alt="lab11" width="80%">
</div>
<div align="center">
  <img src="./images/lab12.png" alt="lab12" width="80%">
</div>
<div align="center">
  <img src="./images/lab13.png" alt="lab13" width="80%">
</div>
<div align="center">
  <img src="./images/lab14.png" alt="lab14" width="80%">
</div>
