// the start: the checks of the machine written one line each on the terminal (a part of kernel.jk: the files are put together with #import in this order, the globals come before they are used)
// ---- the start: the system looks at what the machine has and writes what it finds, one line for each check, on the terminal: [ seconds ] [ OK ] what: the result
void putnum(int v) {
    if v >= 10 { putnum(v / 10); }
    putc(48 + v % 10);
}

void pad3(int v) {
    if v < 100 { putc(48); }
    if v < 10 { putc(48); }
    putnum(v);
}

int tfreq;

void stamp() {
    int ms = Sys::s3_3_c14_c0_2 / 1000;                  // the counter runs at 1 MHz
    setcol(2);
    putc(91);
    int sec = ms / 1000;
    if sec < 100 { putc(32); }
    if sec < 10 { putc(32); }
    putnum(sec);
    putc(46);
    pad3(ms % 1000);
    putc(93);
    putc(32);
    setcol(0);
}

void tag(bool good) {
    if good { setcol(1); say(0x205d204b4f205b); }
    else { setcol(3); say(0x205d4c4941465b); }
    setcol(0);
}

void logline() {
    putc(10);
}

void boot_log() {
    tfreq = Sys::s3_3_c14_c0_0;
    if tfreq < 1000 { tfreq = 1000000; }
    setcol(4); say(0x534f20636972614a); say(0x332e3020); setcol(2); say(0x7265776f70202020); say(0x614a207962206465); say(0x636972); setcol(0);
    logline();
    int el = Sys::s3_0_c4_c2_2 >> 2;
    int core = Sys::s3_0_c0_c0_5 & 255;
    g_el = el;
    g_core = core;
    stamp(); tag(el == 1); say(0x2020202020555043); say(0x202c34364d524120); say(0x6f69747065637865); say(0x206c6576656c206e); putnum(el); say(0x2065726f63202c); putnum(core);
    logline();
    int c0 = Sys::s3_3_c14_c0_2;
    int spin = 0;
    while spin < 100 { spin += 1; }
    int c1 = Sys::s3_3_c14_c0_2;
    stamp(); tag(c1 > c0); say(0x207265746e756f43); say(0x20); putnum(tfreq / 1000); say(0x6f63202c7a486b20); say(0x676e69746e75);
    logline();
    Sys::s3_3_c14_c3_0 = 2000;
    Sys::s3_3_c14_c3_1 = 3;
    int waits = 0;
    while (Sys::s3_3_c14_c3_1 & 4) == 0 && waits < 100000 { waits += 1; }
    bool fired = (Sys::s3_3_c14_c3_1 & 4) != 0;
    Sys::s3_3_c14_c3_1 = 0;
    stamp(); tag(fired); say(0x20202072656d6954); say(0x206b636974206120); say(0x73656d6f63);
    logline();
    int^ m1 = (int^)0x42000000;
    int^ m2 = (int^)0x43000000;
    int^ m3 = (int^)0x43FFFFF0;
    m1[0] = 0x5a5a5a5a5a5a5a5a;
    m2[0] = 0x3c3c3c3c3c3c3c3c;
    m3[0] = 0x1234567812345678;
    bool ram_ok = m1[0] == 0x5a5a5a5a5a5a5a5a && m2[0] == 0x3c3c3c3c3c3c3c3c && m3[0] == 0x1234567812345678;
    stamp(); tag(ram_ok); say(0x202079726f6d654d); say(0x202c424d20343620); say(0x6120646574736574); say(0x2065657268742074); say(0x736563616c70);
    logline();
    stamp(); tag(true); say(0x2020202054524155); say(0x656c6f736e6f6320); say(0x796461657220);
    logline();
    int^ dev = (int^)0x0A000000;
    int dsec = dev[5];
    g_dsec = dsec;
    g_font = fontsize;
    stamp(); tag(dsec > 0); say(0x202020206b736944); say(0x20); putnum(dsec); say(0x73726f7463657320); say(0x202c); putnum(dsec / 2); say(0x424b20);
    logline();
    stamp(); tag(fsok == 1); say(0x20202073656c6946); say(0x202c53464a20); putnum(nfiles); say(0x73656c696620);
    logline();
    int^ fbr = (int^)0x0B000000;
    if fbr[1] != 0 {
        stamp(); tag(sready == 1); say(0x20202020746e6f46); say(0x2c68746f6f6d7320); say(0x20); putnum(fontsize); say(0x736574796220);
        logline();
        stamp(); tag(sready == 1); say(0x20206e6565726353); say(0x20); putnum(fbr[1]); say(0x207820); putnum(fbr[2]); say(0x202c); putnum(54); say(0x207820); putnum(maxrows); say(0x736c6c656320);
        logline();
    }
    int^ uid = (int^)0x0C000000;
    int tq = uid[0];
    stamp(); tag(tq >= 0); say(0x2020206863756f54); say(0x2065636976656420); say(0x7964616572);
    logline();
    stamp(); tag(true); say(0x2020207475706e49); say(0x72616f6279656b20); say(0x79646165722064);
    logline();
    setcol(1); say(0x534f20636972614a); say(0x6461657220736920); say(0x2e79); setcol(0);
    logline();
}


