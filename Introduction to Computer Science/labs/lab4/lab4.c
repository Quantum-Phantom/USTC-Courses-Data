#include <stdio.h>

int calculate_routes(int i, int j) {
    // 基准情况 (Base Case) [cite: 21]
    if (i == 0 || j == 0) {
        return 1;
    }
    return calculate_routes(i - 1, j) + calculate_routes(i, j - 1);
}

int get_recommendation(int n, int m) {
    int steps = n + m; // [cite: 16]
    int routes = calculate_routes(n, m); // [cite: 17]
    
    return (routes * 5) - steps;
}

int main() {
    for (int n = 0; n <= 5; n++) {
        for (int m = 0; m <= 5; m++) {
            int res = get_recommendation(n, m);
            printf("(%d,%d):%4d     ",n,m,res);
        }
        printf("\n");
    }
    return 0;
}