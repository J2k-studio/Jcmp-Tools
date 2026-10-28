// programs: one program at a time runs at EL0 under the kernel (page tables of its own, the ELF of the disk, the calls of the system answered here).
// The kernel itself runs without the MMU; it is turned on while a program runs. The program writes to the console (the terminal app) and can show a picture (call 400)
// and ask for the touch (call 401). A part of kernel.jk: put together with #import after the screen.
frame Context { x19..x30; sp; }

char kstackA[16384];                   // the stack of the kernel while a program runs
int ctxK[13];                          // the kernel (the console) and the program: their registers when the other one runs
int ctxU[13];
int p_tbl;                             // the tables of the program (physical address)
int p_ntab;                            // 4 KB tables for 2 MB each that were used after the 4 first ones
int next_frame;
int p_brk;
int p_mmap;
int p_code;                            // the exit code of the program
int p_entry;
int p_running;
int p_sp;                              // the stack pointer of the program at its start: argc, argv, envp, auxv are above it

int rd32k(char^ p) {
    return (p[0] & 255) | ((p[1] & 255) << 8) | ((p[2] & 255) << 16) | ((p[3] & 255) << 24);
}

void zero_page(int pa) {
    int^ p = (int^)pa;
    for i in 0..512 { p[i] = 0; }
}

int alloc_frame() {
    int f = next_frame;
    zero_page(f);
    next_frame += 4096;
    return f;
}

// ---- the vector table: a synchronous exception from EL0 goes to svc_entry
align(2048) naked void vectors() {
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail svc_entry;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
    tail bad_vector;
    raw<u32>[0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f, 0xd503201f];
}

naked void bad_vector() {
bad:
    x3 = 0x0910_0000;
    x4 = 99;
    [x3 + 0] = x4;
    goto bad;
}

naked void svc_entry() {
    sp = sp - 272;
    [sp + 0] = x0;
    [sp + 8] = x1;
    [sp + 16] = x2;
    [sp + 24] = x3;
    [sp + 32] = x4;
    [sp + 40] = x5;
    [sp + 48] = x6;
    [sp + 56] = x7;
    [sp + 64] = x8;
    [sp + 72] = x9;
    [sp + 80] = x10;
    [sp + 88] = x11;
    [sp + 96] = x12;
    [sp + 104] = x13;
    [sp + 112] = x14;
    [sp + 120] = x15;
    [sp + 128] = x16;
    [sp + 136] = x17;
    [sp + 144] = x18;
    [sp + 152] = x19;
    [sp + 160] = x20;
    [sp + 168] = x21;
    [sp + 176] = x22;
    [sp + 184] = x23;
    [sp + 192] = x24;
    [sp + 200] = x25;
    [sp + 208] = x26;
    [sp + 216] = x27;
    [sp + 224] = x28;
    [sp + 232] = x29;
    [sp + 240] = x30;
    x1 = Sys::elr_el1;
    [sp + 248] = x1;
    x1 = Sys::spsr_el1;
    [sp + 256] = x1;
    x1 = Sys::sp_el0;
    [sp + 264] = x1;
    x28 = 0x4010_0000;                 // the globals of the kernel
    x0 = sp + 0;
    call svc_dispatch;
    tail svc_return;
}

naked void svc_return() {
    x1 = [sp + 248];
    Sys::elr_el1 = x1;
    x1 = [sp + 256];
    Sys::spsr_el1 = x1;
    x1 = [sp + 264];
    Sys::sp_el0 = x1;
    x0 = [sp + 0];
    x1 = [sp + 8];
    x2 = [sp + 16];
    x3 = [sp + 24];
    x4 = [sp + 32];
    x5 = [sp + 40];
    x6 = [sp + 48];
    x7 = [sp + 56];
    x8 = [sp + 64];
    x9 = [sp + 72];
    x10 = [sp + 80];
    x11 = [sp + 88];
    x12 = [sp + 96];
    x13 = [sp + 104];
    x14 = [sp + 112];
    x15 = [sp + 120];
    x16 = [sp + 128];
    x17 = [sp + 136];
    x18 = [sp + 144];
    x19 = [sp + 152];
    x20 = [sp + 160];
    x21 = [sp + 168];
    x22 = [sp + 176];
    x23 = [sp + 184];
    x24 = [sp + 192];
    x25 = [sp + 200];
    x26 = [sp + 208];
    x27 = [sp + 216];
    x28 = [sp + 224];
    x29 = [sp + 232];
    x30 = [sp + 240];
    sp = sp + 272;
    Cpu::eret();
}

// ---- page tables: 0 .. 1 GB (the machine) and 1 .. 2 GB (the memory) are mapped at the same addresses for the kernel; the pages of the program are added
void build_tables(int base) {
    int^ l0 = (int^)base;
    int^ l1 = (int^)(base + 0x1000);
    int^ l2a = (int^)(base + 0x2000);
    int^ l2b = (int^)(base + 0x3000);
    for i in 0..512 { l0[i] = 0; l1[i] = 0; l2a[i] = 0; l2b[i] = 0; }
    l0[0] = (base + 0x1000) | 3;
    l1[0] = (base + 0x2000) | 3;
    l1[1] = (base + 0x3000) | 3;
    for i in 0..512 {
        l2a[i] = (i * 0x200000) | 0x401;
        l2b[i] = (0x40000000 + i * 0x200000) | 0x401;
    }
    p_tbl = base;
    p_ntab = 0;
}

void map_user(int va, int pa) {
    int tb = p_tbl;
    int top = va >> 30;
    int^ l2 = (int^)(tb + 0x2000);
    if top == 1 { l2 = (int^)(tb + 0x3000); }
    int i2 = (va >> 21) & 511;
    int d = l2[i2];
    int l3a = 0;
    if (d & 3) == 3 { l3a = d & 0xFFFFFFFFF000; }
    else {
        l3a = tb + 0x4000 + p_ntab * 0x1000;
        p_ntab += 1;
        zero_page(l3a);
        l2[i2] = l3a | 3;
    }
    int^ l3 = (int^)l3a;
    l3[(va >> 12) & 511] = pa | 0x443;
}

void map_range(int va, int len) {
    int last = (va + len + 4095) & ~4095;
    int a = va & ~4095;
    while a < last {
        map_user(a, alloc_frame());
        a += 4096;
    }
}

// the segments of an ELF file that is in memory at elf; returns the entry, 0 when it is no ELF of ARM64
int elf_load(int elf) {
    char^ f = (char^)elf;
    if f[0] != 127 || f[1] != 'E' || f[2] != 'L' || f[3] != 'F' { return 0; }
    if (f[18] & 255) != 183 { return 0; }
    int entry = rd64(@f[24]);
    int phoff = rd64(@f[32]);
    int phnum = (f[56] & 255) | ((f[57] & 255) << 8);
    int phent = (f[54] & 255) | ((f[55] & 255) << 8);
    for p in 0..phnum {
        char^ ph = @f[phoff + p * phent];
        if rd32k(@ph[0]) != 1 { continue; }
        int off = rd64(@ph[8]);
        int vaddr = rd64(@ph[16]);
        int filesz = rd64(@ph[32]);
        int memsz = rd64(@ph[40]);
        int va = vaddr & ~4095;
        int last = (vaddr + memsz + 4095) & ~4095;
        while va < last {
            int fr = alloc_frame();
            char^ dst = (char^)fr;
            for b in 0..4096 {
                int rel = va + b - vaddr;
                if rel >= 0 && rel < filesz { dst[b] = f[off + rel]; }
            }
            map_user(va, fr);
            va += 4096;
        }
    }
    return entry;
}

// the file of that name: read to the memory at addr (at most 1 MB); its size, or 0
int load_prog(char^ nm, int addr) {
    for i in 0..nfiles {
        char^ e = @sbuf[512 + i * 64];
        int k = 0;
        while nm[k] != 0 && e[k] == nm[k] { k += 1; }
        if nm[k] == 0 && e[k] == 0 {
            int start = rd64(@e[48]);
            int size = rd64(@e[56]);
            if size > 1048576 || size < 64 { return 0; }
            if !disk_io(1, start, addr, (size + 511) / 512) { return 0; }
            return size;
        }
    }
    return 0;
}

naked void ctx_switch(int^ from, int^ to) {
    Context::save(x0);
    Context::restore(x1);
    ret;
}

void proc_first() {                                    // the first thing the program does in the kernel: go down to EL0 at its program
    Sys::elr_el1 = p_entry;
    Sys::spsr_el1 = 0;
    Sys::sp_el0 = p_sp;
    register { Cpu::eret(); }
}

// leaves the program: the console goes on where it was
void prog_leave(int code) {
    p_code = code;
    p_running = 0;
    Sys::ttbr0_el1 = 0x40800000;
    Sys::sctlr_el1 = 0;
    ctx_switch(@ctxU, @ctxK);
    while true { }
}

// a picture of the program (blue, green, red, any; w x h dots) goes to the screen of the system
void prog_present(char^ pix, int w, int h) {
    char^ fb = (char^)0x41000000;
    int ww = w;
    if ww > 540 { ww = 540; }
    int hh = h;
    if hh > scrH { hh = scrH; }
    for y in 0..hh {
        for x in 0..ww {
            int s = (y * w + x) * 4;
            int o = (y * 540 + x) * 4;
            fb[o] = pix[s];
            fb[o + 1] = pix[s + 1];
            fb[o + 2] = pix[s + 2];
            fb[o + 3] = (char)255;
        }
    }
    present();
}

void svc_dispatch(int^ f) {
    int esr_v = Sys::esr_el1;
    int cls = (esr_v >> 26) & 63;
    if cls != 0x15 {
        say(0x20746c756166); putnum(Sys::far_el1); putc(10);          // fault
        prog_leave(139);
        return;
    }
    int nr = f[8];
    int a0 = f[0];
    int a1 = f[1];
    int a2 = f[2];
    if nr == 64 {                                                      // write: the console
        char^ p = (char^)a1;
        if a0 == 1 || a0 == 2 { for i in 0..a2 { putc(p[i]); } }
        f[0] = a2;
    } else if nr == 63 {                                               // read: the keys of the console
        char^ p = (char^)a1;
        int n = 0;
        if a0 == 0 {
            while n < a2 {
                int c = getc();
                if c == 4 { break; }
                if c == 13 { c = 10; }
                p[n] = (char)c;
                n += 1;
                putc(c);
                if c == 10 { break; }
            }
        }
        f[0] = n;
    } else if nr == 222 {                                              // mmap
        int len = (a1 + 4095) & ~4095;
        map_range(p_mmap, len);
        f[0] = p_mmap;
        p_mmap = p_mmap + len + 4096;
    } else if nr == 215 { f[0] = 0;                                    // munmap
    } else if nr == 214 {                                              // brk
        if a0 == 0 { f[0] = p_brk; }
        else {
            if a0 > p_brk { map_range(p_brk, a0 - p_brk); }
            p_brk = a0;
            f[0] = a0;
        }
    } else if nr == 172 || nr == 173 || nr == 174 || nr == 175 || nr == 176 || nr == 177 { f[0] = 1;
    } else if nr == 113 {                                              // clock_gettime
        int^ ts = (int^)a1;
        int c = Sys::s3_3_c14_c0_2;
        ts[0] = c / 1000000;
        ts[1] = (c % 1000000) * 1000;
        f[0] = 0;
    } else if nr == 29 { f[0] = 0 - 25;                                // ioctl: not a terminal
    } else if nr == 132 || nr == 134 || nr == 135 { f[0] = 0;
    } else if nr == 124 { f[0] = 0;
    } else if nr == 93 || nr == 94 { prog_leave(a0);                   // exit
    } else if nr == 400 { prog_present((char^)a0, a1, a2); f[0] = 0;   // a picture for the screen
    } else if nr == 401 {                                              // the touch: seq, x, y, state, id of the last event
        int^ ui = (int^)0x0C000000;
        int^ o = (int^)a0;
        int polled = ui[5];                                            // the machine looks at the input first (the register 0x28)
        o[0] = ui[0];
        o[1] = ui[1];
        o[2] = ui[2];
        o[3] = ui[3];
        o[4] = ui[4];
        f[0] = 0;
    } else {
        say(0x206c6c6163737973); putnum(nr); putc(10);                 // syscall N
        f[0] = 0 - 38;
    }
}

// runs the program of that name from the disk and waits until it has ended; returns its exit code, or -1 when it cannot start
int run_program(char^ nm) {
    int size = load_prog(nm, 0x40900000);
    if size == 0 { return 0 - 1; }
    Sys::vbar_el1 = (int)vectors;
    next_frame = 0x43100000;
    build_tables(0x40800000);                                          // the tables of the kernel
    build_tables(0x40820000);                                          // the tables of the program
    p_entry = elf_load(0x40900000);
    if p_entry == 0 { return 0 - 1; }
    for k in 0..32 { map_user(0x7fffd000 - (k + 1) * 4096, alloc_frame()); }
    p_brk = 0x20000000;
    p_mmap = 0x30000000;
    Sys::ttbr0_el1 = 0x40820000;
    Sys::sctlr_el1 = 1;
    char^ st = (char^)0x7fffc800;                                     // the name of the program as argv[0]
    int nl = 0;
    while nm[nl] != 0 && nl < 60 { st[nl] = nm[nl]; nl += 1; }
    st[nl] = 0;
    int^ v = (int^)0x7fffc000;
    v[0] = 1;
    v[1] = 0x7fffc800;
    v[2] = 0;
    v[3] = 0;
    v[4] = 0;
    v[5] = 0;
    p_sp = 0x7fffc000;
    for i in 0..13 { ctxU[i] = 0; }
    ctxU[9] = 0x40100000;
    ctxU[11] = (int)proc_first;
    ctxU[12] = (int)@kstackA + 16384;
    p_running = 1;
    Sys::ttbr0_el1 = 0x40820000;
    Sys::sctlr_el1 = 1;
    ctx_switch(@ctxK, @ctxU);
    Sys::ttbr0_el1 = 0x40800000;
    Sys::sctlr_el1 = 0;
    return p_code;
}
