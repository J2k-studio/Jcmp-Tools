#include "rt.h"
// integer arithmetic of every size, signed and unsigned: the flags and the extension rules
volatile i64 vs[8] = {0, 1, -1, 7, -7, 0x7fffffff, -0x80000000L, 0x123456789abcdefL};
volatile u64 vu[6] = {0, 1, 0xffffffffffffffffUL, 255, 65535, 0x8000000000000000UL};
int main(void) {
    for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++) {
        i64 a = vs[i], b = vs[j];
        say("add", a + b); say("sub", a - b); say("mul", a * b);
        say("and", a & b); say("or", a | b); say("xor", a ^ b);
        say("lt", a < b); say("le", a <= b); say("eq", a == b);
        if (b != 0 && !(a == -0x7fffffffffffffffL - 1 && b == -1)) { say("div", a / b); say("mod", a % b); }
        i32 x = (i32)a, y = (i32)b;
        say("add32", (i32)((u32)x + (u32)y)); say("mul32", (i32)((u32)x * (u32)y));
        if (y != 0 && !(x == -2147483647 - 1 && y == -1)) { say("div32", x / y); say("mod32", x % y); }
        i16 p = (i16)a, q = (i16)b; say("add16", (i16)(p + q)); say("mul16", (i16)(p * q));
        i8 m = (i8)a, n = (i8)b; say("add8", (i8)(m + n)); say("sub8", (i8)(m - n));
        say("shl", a << (j & 7)); say("sar", a >> (j & 7)); say("neg", -a); say("not", ~a);
    }
    for (int i = 0; i < 6; i++) for (int j = 0; j < 6; j++) {
        u64 a = vu[i], b = vu[j];
        sayx("uadd", a + b); sayx("usub", a - b); sayx("umul", a * b);
        say("ult", a < b); say("uge", a >= b);
        if (b != 0) { sayx("udiv", a / b); sayx("umod", a % b); }
        sayx("ushr", a >> (j & 15)); sayx("rol", (a << (j + 1)) | (a >> (63 - j)));
        u32 c = (u32)a, d = (u32)b; sayx("add32", (u32)(c + d)); if (d) sayx("udiv32", c / d);
        sayx("shr32", c >> (j & 15));
    }
    return 3;
}
