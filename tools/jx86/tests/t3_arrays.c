#include "rt.h"
#define N 2000
static u8 sieve[N + 1];
static i32 arr[512];
static void qs(i32 *a, i64 lo, i64 hi) { if (lo >= hi) return; i32 p = a[(lo + hi) / 2]; i64 i = lo, j = hi; while (i <= j) { while (a[i] < p) i++; while (a[j] > p) j--; if (i <= j) { i32 t = a[i]; a[i] = a[j]; a[j] = t; i++; j--; } } qs(a, lo, j); qs(a, i, hi); }
static u32 hash(const u8 *s, long n) { u32 h = 2166136261u; for (long i = 0; i < n; i++) { h ^= s[i]; h *= 16777619u; } return h; }
int main(void) {
    i64 c = 0; for (i64 i = 2; i <= N; i++) sieve[i] = 1;
    for (i64 i = 2; i * i <= N; i++) if (sieve[i]) for (i64 j = i * i; j <= N; j += i) sieve[j] = 0;
    for (i64 i = 2; i <= N; i++) c += sieve[i];
    say("primes", c);
    u32 s = 12345; for (int i = 0; i < 512; i++) { s = s * 1103515245u + 12345u; arr[i] = (i32)(s >> 8) % 1000 - 500; }
    qs(arr, 0, 511); i64 ok = 1; for (int i = 1; i < 512; i++) if (arr[i - 1] > arr[i]) ok = 0;
    say("sorted", ok); say("min", arr[0]); say("max", arr[511]); say("mid", arr[256]);
    say("hash", hash((const u8 *)arr, sizeof arr));
    i64 m[8][8]; for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++) m[i][j] = i * j - 3;
    i64 t = 0; for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++) { i64 a = 0; for (int k = 0; k < 8; k++) a += m[i][k] * m[k][j]; t += a * (i + 1); }
    say("matrix", t);
    return 0;
}
