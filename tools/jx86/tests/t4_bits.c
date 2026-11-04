#include "rt.h"
static int popc(u64 v) { int c = 0; while (v) { c += v & 1; v >>= 1; } return c; }
static u64 rotl(u64 v, int k) { return (v << k) | (v >> (64 - k)); }
static u32 bsw(u32 v) { return __builtin_bswap32(v); }
static u64 bsw64(u64 v) { return __builtin_bswap64(v); }
static int clz(u64 v) { return v ? __builtin_clzll(v) : 64; }
static int ctz(u64 v) { return v ? __builtin_ctzll(v) : 64; }
volatile u64 vals[6] = {1, 0x80, 0xf0f0f0f0f0f0f0f0UL, 0x123456789abcdef0UL, 0xffffffffffffffffUL, 0x8000000000000000UL};
int main(void) {
    for (int i = 0; i < 6; i++) {
        u64 v = vals[i];
        say("popc", popc(v)); sayx("rotl", rotl(v, 13)); sayx("bsw32", bsw((u32)v)); sayx("bsw64", bsw64(v));
        say("clz", clz(v)); say("ctz", ctz(v));
        sayx("andn", v & ~(v >> 3)); sayx("sext8", (u64)(i64)(i8)v); sayx("sext16", (u64)(i64)(i16)v); sayx("sext32", (u64)(i64)(i32)v);
        sayx("zext8", (u64)(u8)v); sayx("zext16", (u64)(u16)v);
        u64 cmp = (v > 100) ? v - 100 : 100 - v; sayx("sel", cmp);
        i64 sv = (i64)v; say("abs", sv < 0 ? -sv : sv); say("sgn", (sv > 0) - (sv < 0));
    }
    return 0;
}
