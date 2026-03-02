#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdint.h>

#define MAX_LINES 2000
#define MAX_LINE_LEN 256
#define MAX_LABELS 500
#define MAX_LABEL_LEN 21


typedef struct {
    char name[MAX_LABEL_LEN];
    int address;
} Symbol;

char source_code[MAX_LINES][MAX_LINE_LEN];
int total_lines = 0;
Symbol symtab[MAX_LABELS];
int sym_count = 0;

typedef struct {
    uint16_t address;  // PC 地址
    uint16_t code;     // 机器指令
} CodeEntry;
CodeEntry machine_code[MAX_LINES * 10]; 
int code_count = 0;

//函数声明
void generate_symbol_table();                 // 第一遍扫描：计算地址并构建符号表
void generate_machine_code();                 // 第二遍扫描：解析指令并生成16位机器码二进制
void report_error(const char *msg, int line); // 打印错误信息并异常退出程序
void check_range(int val, int bits, int line);// 检查立即数是否符合有符号位宽限制
void check_trap_vector(int val, int line);    // 检查TRAP向量是否在0-255范围内
void to_lower(char *str);                     // 将字符串就地转换为小写
void clean_line(char *d, const char *s);      // 去除行首尾空白及分号后的注释内容
void add_symbol(const char *n, int a, int l); // 向符号表中添加标签及对应地址
int get_symbol_addr(const char *name);        // 查找标签地址，未找到返回-1
int resolve_label(const char *t, int l);      // 解析标签并返回地址，不存在则报错
int parse_reg(const char *str, int line);     // 将寄存器文本(R0-R7)转换为编号0-7
int parse_imm(const char *str, int line);     // 解析十进制(#)或十六进制(x)立即数
int is_opcode(const char *token);             // 判断字符串是否为指令或伪指令助记符
int get_stringz_len(const char *str_content); // 计算.STRINGZ字符串占用的内存字数
char* next_token(int line_idx);               // 获取下一个操作数Token，缺失则报错
void write_output_file(const char *filename); //输出文件
void print_symbol_table();              //打印符号表
void print_debug_info();//          打印地址和对应机器码

//主函数
int main(int argc, char *argv[]) {
    const char *input_filename = argv[1] ;
    const char *output_filename =argv[2];

    FILE *in_fp = fopen(input_filename, "r");
    if (!in_fp) {
        fprintf(stderr, "Error: Unable to open input file '%s'\n", input_filename);
        perror("Reason"); 
        return 1; 
    }

    total_lines = 0;
    while (total_lines < MAX_LINES && fgets(source_code[total_lines], MAX_LINE_LEN, in_fp)) {
        total_lines++;
    }
    fclose(in_fp);

    generate_symbol_table();
    generate_machine_code();

    write_output_file(output_filename);

    printf("Assembly Success! Output saved to %s\n", output_filename);
    print_symbol_table();
    print_debug_info();
    return 0;
}

//创建符号表
void generate_symbol_table() {
    int pc = 0;
    for (int i = 0; i < total_lines; i++) {
        char line[MAX_LINE_LEN], clean[MAX_LINE_LEN];
        clean_line(clean, source_code[i]);
        if (strlen(clean) == 0) 
            continue;

        strcpy(line, clean);//strtok 会修改原字符串，所以先拷贝一份到 line
        char *token = strtok(line, " \t,");     //分割函数，第二个参数中的每一个字符都会被独立当做分隔符
        if (!token) 
            continue;

        // 如果不是指令（包括.ORIG...），则是标签
        if (!is_opcode(token)) {
            add_symbol(token, pc, i);
            token = strtok(NULL, " \t,"); // 移动到标签后的指令（第一次调用传入指针时，strtok 会在内部记下这个位置。当你后续传入 NULL 时，它会从上次记下的位置之后继续寻找下一个分隔符）
        }

        if (!token) 
            continue;

        char opcode[20];
        strcpy(opcode, token);
        to_lower(opcode);//操作码转换成小写

        // 处理改变 PC 增量的伪指令
        if (strcmp(opcode, ".orig") == 0) {
            token = strtok(NULL, " \t,");//获取.ORIG后的地址参数
            if(token) 
                pc = parse_imm(token, i);
        } 
        else if (strcmp(opcode, ".stringz") == 0) {
            char *start = strchr(clean, '"');   //strchr 查找特定字符在字符串中第一次出现的位置
            char *end = strrchr(clean, '"');
            if (start && end && end > start) {
                pc += get_stringz_len(start + 1);
            }
        } 
        else if (strcmp(opcode, ".blkw") == 0) {    //.BLKW “从当前位置开始，空出n个内存单元，不要在这里放其他指令”
            token = strtok(NULL, " \t,");
            if(token) pc += parse_imm(token, i);
        } 
        else if (strcmp(opcode, ".end") == 0) {
            // 结束处理,pc不再自增
        } 
        else {
            pc++; // 普通机器指令或 .fill
        }
    }
}
//生成机器码
void generate_machine_code() {
    int pc = 0; 
    code_count = 0; // 重置全局计数器

    for (int i = 0; i < total_lines; i++) {
        char line[MAX_LINE_LEN];
        char clean[MAX_LINE_LEN];
        clean_line(clean, source_code[i]);
        if (strlen(clean) == 0) 
            continue;

        strcpy(line, clean);
        char *token = strtok(line, " \t,");
        
        if (!is_opcode(token)) {//跳过标签
            token = strtok(NULL, " \t,");
        }
        if (!token) 
            continue; // 只有标签的行

        char opcode[20];
        strcpy(opcode, token);
        to_lower(opcode);

        uint16_t instr = 0;

        //处理伪指令
        if (strcmp(opcode, ".orig") == 0) {
            pc = parse_imm(next_token(i), i);   //i表示.asm代码中的行数，报错用的
            // 保存起始地址记录
            machine_code[code_count].address = pc;
            machine_code[code_count].code = (uint16_t)pc;
            code_count++;
            continue;
        } 
        else if (strcmp(opcode, ".end") == 0) {
            break; // 遇到 .END 停止解析
        } 
        else if (strcmp(opcode, ".fill") == 0) {
            token = next_token(i);
            int val = (token[0] == '#' || token[0] == 'x' || isdigit(token[0]) || token[0] == '-') 
                      ? parse_imm(token, i) : resolve_label(token, i);  //判断.FILL后面是数字还是标签
            machine_code[code_count].address = pc;
            machine_code[code_count].code = (uint16_t)val;
            code_count++;
            pc++; 
            continue;
        }
        else if (strcmp(opcode, ".blkw") == 0) {
            int count = parse_imm(next_token(i), i);
            for(int k = 0; k < count; k++) { 
                machine_code[code_count].address = pc + k;
                machine_code[code_count].code = 0; // .BLKW 默认填充 0
                code_count++;
            }
            pc += count; 
            continue;
        } 
        else if (strcmp(opcode, ".stringz") == 0) {
            char *start = strchr(clean, '"');
            char *end = strrchr(clean, '"');    //strrchr 从右开始找
            if (!start || !end || start == end) 
                report_error("Invalid string format", i);

            char *s = start + 1;
            while (s < end) {
                char val = *s;
                if (*s == '\\' && *(s+1) == 'n') {//处理转义字符
                    val = '\n'; 
                    s++; 
                }
                machine_code[code_count].address = pc;
                machine_code[code_count].code = (uint16_t)val;
                code_count++;
                s++; 
                pc++;
            }
            machine_code[code_count].address = pc;
            machine_code[code_count].code = 0; // 字符串结束符
            code_count++;
            pc++; 
            continue;
        }

        //机器指令处理
        int current_pc = pc; // 记录当前指令地址
        pc++; // 先增加 PC，用于后续计算 Offset (PC' = PC + 1)

        if (strcmp(opcode, "add") == 0 || strcmp(opcode, "and") == 0) {
            instr = (opcode[0] == 'a' && opcode[1] == 'd') ? 0x1000 : 0x5000;   //判断是add还是and
            instr |= (parse_reg(next_token(i), i) << 9);  // DR
            instr |= (parse_reg(next_token(i), i) << 6);  // SR1
            token = next_token(i);
            if (token[0] == 'r' || token[0] == 'R') {
                instr |= parse_reg(token, i);             // SR2
            } 
            else {      //立即数
                int imm = parse_imm(token, i);
                check_range(imm, 5, i);
                instr |= (1 << 5);          //第五位置1
                instr |= (imm & 0x1F);         // Imm5
            }
        } 
        else if (strcmp(opcode, "not") == 0) {
            instr = 0x903F;
            instr |= (parse_reg(next_token(i), i) << 9);    //DR
            instr |= (parse_reg(next_token(i), i) << 6);    //SR
        } 
        else if (strncmp(opcode, "br", 2) == 0) {   //br和nzp紧挨着
            instr = 0x0000; 
            if (strcmp(opcode, "br") == 0) 
                instr |= 0x0E00; // br 等价于 brnzp
            else {
                if (strchr(opcode, 'n')) 
                    instr |= 0x0800;    //查找失败时返回NULL
                if (strchr(opcode, 'z')) 
                    instr |= 0x0400;
                if (strchr(opcode, 'p')) 
                    instr |= 0x0200;
            }
            int offset = resolve_label(next_token(i), i) - pc;
            check_range(offset, 9, i);
            instr |= (offset & 0x1FF);  //0000 0001 1111 1111
        } 
        else if (strcmp(opcode, "ld") == 0 || strcmp(opcode, "ldi") == 0 
                || strcmp(opcode, "lea") == 0 
                || strcmp(opcode, "st") == 0 || strcmp(opcode, "sti") == 0) {
            if (strcmp(opcode, "ld") == 0)      
                instr = 0x2000; //0010
            else if (strcmp(opcode, "ldi") == 0) 
                instr = 0xA000; //1010
            else if (strcmp(opcode, "lea") == 0) 
                instr = 0xE000; //1110
            else if (strcmp(opcode, "st") == 0)  
                instr = 0x3000; //0011
            else                                 
                instr = 0xB000; //1011
            
            instr |= (parse_reg(next_token(i), i) << 9);    // DR/SR
            int offset = resolve_label(next_token(i), i) - pc;
            check_range(offset, 9, i);
            instr |= (offset & 0x1FF);
        } 
        else if (strcmp(opcode, "ldr") == 0 || strcmp(opcode, "str") == 0) {
            instr = (opcode[0] == 'l') ? 0x6000 : 0x7000;
            instr |= (parse_reg(next_token(i), i) << 9); // DR/SR
            instr |= (parse_reg(next_token(i), i) << 6); // BaseR
            int offset = parse_imm(next_token(i), i);
            check_range(offset, 6, i);
            instr |= (offset & 0x3F);
        }
        else if (strcmp(opcode, "jmp") == 0 || strcmp(opcode, "ret") == 0) {
            instr = 0xC000; //1100
            if (strcmp(opcode, "ret") == 0) 
                instr |= (7 << 6); // RET 等价于 JMP R7
            else 
                instr |= (parse_reg(next_token(i), i) << 6);
        } 
        else if (strcmp(opcode, "trap") == 0) {
            int vec = parse_imm(next_token(i), i);
            check_trap_vector(vec, i);
            instr = 0xF000;
            instr |= (vec & 0xFF);
        } 
        else if (strcmp(opcode, "halt") == 0) {
            instr = 0xF025; // TRAP x25
        }
        else if (strcmp(opcode, "puts") == 0){ 
            instr = 0xF022; // TRAP x22: 打印 R0 指向的字符串
        }
        else if (strcmp(opcode, "jsr") == 0 || strcmp(opcode, "jsrr") == 0) {
            instr = 0x4000; // 操作码 0100
            token = next_token(i);
            if (token[0] == 'r' || token[0] == 'R') {   //JSRR
                instr |= (parse_reg(token, i) << 6);
            } 
            else {
                instr |= (1 << 11);
                int offset = resolve_label(token, i) - pc; 
                check_range(offset, 11, i);
                instr |= (offset & 0x7FF); //11位
            }
        }
        else if (strcmp(opcode, "rti") == 0) {
            instr = 0x8000; // 1000，其余位通常为 0
        }
        else {
            report_error("Opcode logic not implemented yet", i);
        }

        //存储到数组
        machine_code[code_count].address = current_pc;
        machine_code[code_count].code = instr;
        code_count++;
    }
}

//辅助函数
//报错
void report_error(const char *msg, int line_idx) {
    fprintf(stderr, "Error at line %d: %s\n", line_idx + 1, msg);   //stderr标准错误
    exit(1);
}
//检查offset范围
void check_range(int val, int bits, int line_idx) {
    int min = -(1 << (bits - 1));
    int max = (1 << (bits - 1)) - 1;
    if (val < min || val > max) 
        report_error("Value out of range", line_idx);
}
//检查TRAP指令范围
void check_trap_vector(int val, int line_idx) {
    if (val < 0 || val > 255) 
        report_error("Trap vector out of range", line_idx);
}
//整数转换为为二进制后输出
void print_bin(FILE *out, int val, int bits) {
    for (int i = bits - 1; i >= 0; i--) {
        fputc((val & (1 << i)) ? '1' : '0', out);
    }
}
//将一段字符串的所有字符转换成小写
void to_lower(char *str) {
    for (; *str; ++str) 
        *str = tolower(*str);   //把大写字母变成小写，其他字符不变
}
//去除多余空格、换行和注释
void clean_line(char *dest, const char *src) {
    const char *p = src; 
    char *d = dest;
    while (*p && isspace(*p))   //isspace：检查一个字符是否属于空白字符，包括'\n','\r','\t',' '---
        p++;    //去掉开头多余的
    while (*p && *p != '\n' && *p != '\r' && *p != ';') 
        *d++ = *p++;
    *d = '\0';
    while (d > dest && isspace(*(d - 1)))   //去除字符串末尾的尾随空格
        *--d = '\0';
}
//添加标签到符号表
void add_symbol(const char *name, int addr, int line_idx) {
    if (get_symbol_addr(name) != -1)    //标签重名
        report_error("Duplicate label", line_idx);
    if (sym_count >= MAX_LABELS) 
        report_error("Too many labels", line_idx);
    strcpy(symtab[sym_count].name, name);
    symtab[sym_count].address = addr;
    sym_count++;
}
//依据标签名找到地址
int get_symbol_addr(const char *name) {
    for (int i = 0; i < sym_count; i++) 
        if (strcmp(symtab[i].name, name) == 0) 
            return symtab[i].address;
    return -1;
}
//获得标签表示的地址
int resolve_label(const char *token, int line_idx) {
    int addr = get_symbol_addr(token);
    if (addr == -1) 
        report_error("Undefined label", line_idx);
    return addr;
}
//寄存器转换
int parse_reg(const char *str, int line_idx) {
    if (str && (str[0] == 'r' || str[0] == 'R') && isdigit(str[1])) {   //isdigit <ctype.h> 中 专门用来检查一个字符是否是十进制数字
        int r = atoi(str + 1);  //atoi <stdlib.h>将一个数字字符串转换为整数
        if (r >= 0 && r <= 7) 
            return r;
    }
    report_error("Invalid register", line_idx); 
        return 0;
}
//将字符串格式的数字（立即数）解析为整数
int parse_imm(const char *str, int line_idx) {  //Parse Immediate
    char *endptr; // 指向strtol转换停止后字符串中第一个非数字字符的地址
    long val;
    if (str[0] == '#') //以#开头的十进制
        val = strtol(str + 1, &endptr, 10);
    else if (str[0] == 'x' || str[0] == 'X') //十六进制
        val = strtol(str + 1, &endptr, 16);
    else //十进制
        val = strtol(str, &endptr, 10);

    if (endptr == str || 
        ( (str[0] == '#' || str[0] == 'x' || str[0] == 'X') && endptr == str + 1)) {
        report_error("Invalid number format (no digits found)", line_idx);
    } 
    else if (*endptr != '\0') {
        report_error("Invalid character in number", line_idx);
    }
    return (int)val;    //没找到数字时val是0
}
//判断是否是指令/伪操作
int is_opcode(const char *token) {
    if (!token) return 0;
    const char *ops[] = {"add", "and", "not", "ld", "ldr", "ldi", "lea", "st", "str", "sti", 
                    "br", "brn", "brz", "brp", "brnz", "brnp", "brzp", "brnzp", 
                    "jmp", "jsr", "jsrr", "ret", "rti", "trap", "halt","puts" ,
                    ".orig", ".end", ".fill", ".blkw", ".stringz"};
    char temp[20]; strncpy(temp, token, 19); temp[19] = 0; to_lower(temp);
    for (size_t i = 0; i < 30; i++) if (strcmp(temp, ops[i]) == 0) return 1;
    return 0;
}
//计算 .STRINGZ 伪指令在内存中所占用的字（Word）数
int get_stringz_len(const char *str_content) {
    int len = 0;
    for (int i = 0; str_content[i] != '\0' && str_content[i] != '"'; i++) {
        if (str_content[i] == '\\' && str_content[i+1] == 'n')  //遇到换行符(.STRINGZ 的字符串若包含转义符，则只有 \n 一种)
            i++;    //'\n'在原码中占用两个字符，但是在实际内存中只占一个字符
        len++;
    }
    return len + 1; //增加'\0'
}
//得到下一个操作数
char* next_token(int line_idx) {    //i表示.asm代码中的行数
    char *t = strtok(NULL, " \t,");
    if (!t) 
        report_error("Missing operand", line_idx);
    return t;
}
//输出txt文件
void write_output_file(const char *filename) {
    FILE *out = fopen(filename, "w");
    if (!out) {
        perror("Unable to create output file");
        exit(1);
    }

    for (int i = 0; i < code_count; i++) {
        uint16_t val = machine_code[i].code;
        for (int bit = 15; bit >= 0; bit--) {
            fputc((val & (1 << bit)) ? '1' : '0', out); //  &按位与运算
        }
        fputc('\n', out);
    }

    fclose(out);
    printf("Assembly Success! Output saved to %s\n", filename);
}
//打印符号表
void print_symbol_table() {
    printf("\n--- SYMBOL TABLE ---\n");
    printf("%-20s | %-10s\n", "Label Name", "Address");// %-20s 左对齐，占用 20 个字符宽度
    printf("------------------------------------\n");
    
    if (sym_count == 0) 
        printf("(No labels found)\n");
    else 
        for (int i = 0; i < sym_count; i++) 
            printf("%-20s | x%04X\n", symtab[i].name, symtab[i].address);// x%04X 表示打印为 4 位大写的十六进制，前缀加 x
    printf("------------------------------------\n\n");
}
// 打印每一条指令的地址和二进制代码（调试用）
void print_debug_info() {
    printf("\n--- DEBUG INFO (Address : Binary Code) ---\n");
    for (int i = 0; i < code_count; i++) {
        printf("x%04X : ", machine_code[i].address);
        
        uint16_t val = machine_code[i].code;
        for (int bit = 15; bit >= 0; bit--) {
            printf("%c", (val & (1 << bit)) ? '1' : '0');
        }
        
        printf("\n");
    }
    printf("------------------------------------------\n");
}

//cd E:\CoursesData\ICS\labs\labA
//gcc -O2 assembler.c -o assembler
//.\assembler.exe test_case/asm/fibonacci.asm output/fibonacci.bin
//.\assembler.exe test_case/asm/multiplication.asm output/multiplication.bin
//.\assembler.exe test_case/asm/recursion.asm output/recursion.bin
//.\assembler.exe test_case/asm/stack_operations.asm output/stack_operations.bin
//.\assembler.exe test_case/asm/string_length.asm output/string_length.bin
//.\assembler.exe test_case/asm/test_add.asm output/test_add.bin
//.\assembler.exe test_case/asm/test_and_not.asm output/test_and_not.bin
//.\assembler.exe test_case/asm/test_branch.asm output/test_branch.bin
//.\assembler.exe test_case/asm/test_jump.asm output/test_jump.bin
//.\assembler.exe test_case/asm/test_load_store.asm output/test_load_store.bin
//.\assembler.exe test_case/asm/test_subroutine.asm output/test_subroutine.bin