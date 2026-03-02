#include <stdio.h>

#define MAX_N 100  // 定义要计算的项数

int main() {
    // 数组 q 用于存储数列，q[1] 对应第 1 项，q[2] 对应第 2 项，以此类推
    int q[MAX_N + 1];  // 数组大小为 MAX_N + 1，方便直接使用 1~MAX_N 作为索引

    // 初始化前两项
    q[1] = 1;
    q[2] = 1;

    // 计算从第 3 项到第 MAX_N 项
    for (int n = 3; n <= MAX_N; n++) {
        // 根据递推公式计算第 n 项
        // Q(n) = Q(n - Q(n - 1)) + Q(n - Q(n - 2))
        int index1 = n - q[n - 1];  // 第一个索引：n - Q(n-1)
        int index2 = n - q[n - 2];  // 第二个索引：n - Q(n-2)
        q[n] = q[index1] + q[index2];
    }

    // 打印前 100 项结果（每行打印 10 项，方便查看）
    printf("该数列的前 %d 项如下：\
", MAX_N);
    for (int i = 1; i <= MAX_N; i++) {
        printf("Q(%d)=%d  ",i, q[i]);  // 格式化输出，每项占 4 个字符宽度，保持对齐
        if (i % 10 == 0) {    // 每打印 10 项换行
            printf("\
");
        }
    }

    return 0;
}