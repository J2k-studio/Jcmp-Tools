#include "rt.h"
static i64 fib(i64 n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }
static i64 gcd(i64 a, i64 b) { while (b) { i64 t = a % b; a = b; b = t; } return a; }
struct P { i64 x, y; u8 tag; };
static struct P mk(i64 x, i64 y) { struct P p = {x, y, (u8)(x ^ y)}; return p; }
static i64 sum(struct P p, struct P q) { return p.x * q.y - p.y * q.x + p.tag + q.tag; }
static i64 sw(i64 k) { switch (k) { case 0: return 10; case 1: return 11; case 2: return 25; case 3: return 31; case 4: return 47; case 5: return 5; case 6: return 66; case 7: return 70; default: return -1; } }
static i64 (*fp[3])(i64) = {sw, 0, 0};
static i64 apply(i64 (*f)(i64), i64 v) { return f(v) * 2; }
int main(void) {
    say("fib", fib(25));
    say("gcd", gcd(1071, 462)); say("gcd2", gcd(1000000007, 998244353));
    say("sum", sum(mk(3, 4), mk(5, -6)));
    for (i64 k = -1; k < 10; k++) say("sw", sw(k));
    say("apply", apply(fp[0], 3));
    static char buf[64]; memset(buf, 'a', 10); buf[10] = 0; memcpy(buf + 3, "xyz", 3); puts_(buf); nl();
    return 0;
}
