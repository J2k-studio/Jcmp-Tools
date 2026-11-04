// a tiny runtime for freestanding x86_64 test programs: system calls and printing, no libc
typedef unsigned long u64; typedef long i64; typedef unsigned int u32; typedef int i32; typedef unsigned char u8; typedef unsigned short u16; typedef short i16; typedef signed char i8;
static inline long sys3(long n, long a, long b, long c) { long r; __asm__ volatile("syscall" : "=a"(r) : "a"(n), "D"(a), "S"(b), "d"(c) : "rcx", "r11", "memory"); return r; }
static void wr(const char *s, long n) { sys3(1, 1, (long)s, n); }
static void puts_(const char *s) { long n = 0; while (s[n]) n++; wr(s, n); }
static void putu(u64 v) { char b[24]; int i = 24; if (v == 0) b[--i] = '0'; while (v) { b[--i] = '0' + v % 10; v /= 10; } wr(b + i, 24 - i); }
static void puti(i64 v) { if (v < 0) { puts_("-"); putu(0 - (u64)v); } else putu(v); }
static void putx(u64 v) { char b[16]; for (int i = 15; i >= 0; i--) { b[i] = "0123456789abcdef"[v & 15]; v >>= 4; } wr(b, 16); }
static void nl(void) { wr("\n", 1); }
static void say(const char *s, i64 v) { puts_(s); puts_(" "); puti(v); nl(); }
static void sayx(const char *s, u64 v) { puts_(s); puts_(" "); putx(v); nl(); }
__attribute__((noreturn)) static void quit(int c) { for (;;) sys3(60, c, 0, 0); }
void *memcpy(void *d, const void *s, unsigned long n);
void *memset(void *d, int c, unsigned long n);
void *memcpy(void *d, const void *s, unsigned long n) { unsigned char *a = d; const unsigned char *b = s; while (n--) *a++ = *b++; return d; }
void *memset(void *d, int c, unsigned long n) { unsigned char *a = d; while (n--) *a++ = (unsigned char)c; return d; }
int main(void);
void _start(void) { quit(main()); }
