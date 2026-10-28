// the store (jstore): the host call device, the app, the command jstore and the console commands (a part of kernel.jk: the files are put together with #import in this order, the globals come before they are used)
// ---- the store: the programs of jstore. The system asks the host (the host call device) for the list, and for a package to be put on the disk; then it reads the disk again.
char hcmd[100];
int soff[16];                          // where each line of the list starts in the answer (at 0x42200000)
int snum;

// asks the host: the command is in hcmd; the answer is at 0x42200000; returns the status (0 = ok)
int hostcall_do() {
    int^ hc = (int^)0x0D000000;
    hc[0] = (int)@hcmd;
    hc[1] = 0x42200000;
    hc[2] = 1;
    return hc[3];
}

void hc_text(int w0, int w1) {
    for k in 0..8 { hcmd[k] = (char)((w0 >> (k * 8)) & 255); }
    for k in 0..8 { hcmd[8 + k] = (char)((w1 >> (k * 8)) & 255); }
    hcmd[16] = 0;
}

// the id of the package on a line: the letters up to the first tab
int line_end(char^ p, int from) {
    int i = from;
    while p[i] != 0 && p[i] != 10 { i += 1; }
    return i;
}

bool have_pkg(char^ p, int from) {                    // is the file ID.jc on the disk
    int idl = 0;
    while p[from + idl] != 9 && p[from + idl] != 0 && p[from + idl] != 10 { idl += 1; }
    for i in 0..nfiles {
        char^ e = @sbuf[512 + i * 64];
        int k = 0;
        while k < idl && e[k] == p[from + k] { k += 1; }
        if k == idl && e[k] == '.' && e[k + 1] == 'j' && e[k + 2] == 'c' && e[k + 3] == 0 { return true; }
    }
    return false;
}

void store_draw(int msg0, int msg1) {
    wallpaper();
    draw_bar(0x65726f74736a, 0);
    char^ ans = (char^)0x42200000;
    snum = 0;
    int pos = 0;
    while ans[pos] != 0 && snum < 12 {
        soff[snum] = pos;
        snum += 1;
        pos = line_end(ans, pos);
        if ans[pos] == 10 { pos += 1; }
    }
    for i in 0..snum {
        int y = 96 + i * 78;
        rrect(16, y, 508, 70, 18, rgb(26, 36, 66));
        int p = soff[i];
        int tabs = 0;
        int ver = 0;
        int nm = 0;
        int j = p;
        while ans[j] != 0 && ans[j] != 10 {
            if ans[j] == 9 { tabs += 1; if tabs == 1 { ver = j + 1; } if tabs == 2 { nm = j + 1; } }
            j += 1;
        }
        int e = line_end(ans, p);
        int l = 0;
        while nm > 0 && nm + l < e && l < 24 { tb[l] = ans[nm + l]; l += 1; }
        tb[l] = 0;
        text(32, y + 10, @tb, 1, rgb(235, 242, 255));
        int vl = 0;
        while ver > 0 && ans[ver + vl] != 9 && vl < 10 { tb[vl] = ans[ver + vl]; vl += 1; }
        tb[vl] = 0;
        text(32, y + 38, @tb, 1, rgb(150, 175, 215));
        if have_pkg(ans, p) {
            rrect(392, y + 14, 116, 42, 21, rgb(60, 90, 80));
            t8(408 + 0, y + 25, 0x746920746f47, 1, rgb(190, 235, 210));
        } else {
            rrect(392, y + 14, 116, 42, 21, rgb(70, 150, 255));
            t8(408 + 0, y + 25, 0x6c6c6174736e49, 1, rgb(255, 255, 255));
        }
    }
    if snum == 0 { t8(28 + 0, 110, 0x20676e6968746f4e, 1, rgb(150, 175, 215)); t8(28 + 80, 110, 0x2e776f6873206f74, 1, rgb(150, 175, 215)); }
    if msg0 != 0 { t8(28, scrH - 120, msg0, 1, rgb(255, 215, 120)); t8(108, scrH - 120, msg1, 1, rgb(255, 215, 120)); }
    present();
}

void store_message(char^ ans) {                       // the answer of the host as a line of text at the bottom
    int l = 0;
    while ans[l] != 0 && ans[l] != 10 && l < 50 { tb[l] = ans[l]; l += 1; }
    tb[l] = 0;
    fill(0, scrH - 130, 540, 40, rgb(12, 18, 40));
    text(28, scrH - 120, @tb, 1, rgb(255, 215, 120));
    present();
}

void app_store() {
    char^ ans = (char^)0x42200000;
    ans[0] = 0;
    wallpaper();
    draw_bar(0x65726f74736a, 0);
    t8(28 + 0, 120, 0x7420676e696b7341, 1, rgb(150, 175, 215)); t8(28 + 80, 120, 0x65726f7473206568, 1, rgb(150, 175, 215)); t8(28 + 160, 120, 0x2e2e2e20, 1, rgb(150, 175, 215));
    present();
    hc_text(0x7473696c, 0);
    int st = hostcall_do();
    if st != 0 {
        wallpaper();
        draw_bar(0x65726f74736a, 0);
        store_message(ans);
        app_wait_home();
        return;
    }
    store_draw(0, 0);
    while true {
        int r = wait_event();
        if r != 1 { continue; }
        if is_home_tap() { return; }
        int i = (tap_y - 96) / 78;
        if tap_y < 96 || i >= snum || tap_x < 380 { continue; }
        int p = soff[i];
        if have_pkg(ans, p) { continue; }
        // install: "get ID"
        hc_text(0x20746567, 0);
        int idl = 0;
        while ans[p + idl] != 9 && ans[p + idl] != 0 && idl < 80 { hcmd[4 + idl] = ans[p + idl]; idl += 1; }
        hcmd[4 + idl] = 0;
        char^ keep = (char^)0x42210000;                // the list is kept: the answer of the host goes over it
        for k in 0..4000 { keep[k] = ans[k]; }
        fill(0, scrH - 130, 540, 40, rgb(12, 18, 40));
        t8(28 + 0, scrH - 120, 0x64616f6c6e776f44, 1, rgb(255, 215, 120)); t8(28 + 80, scrH - 120, 0x2e2e2e20676e69, 1, rgb(255, 215, 120));
        present();
        int gs = hostcall_do();
        if gs != 0 {
            store_message(ans);
            for k in 0..4000 { ans[k] = keep[k]; }
            continue;
        }
        disk_reload();
        for k in 0..4000 { ans[k] = keep[k]; }
        store_draw(0x64656c6c6174736e49, 0);
    }
}

// the disk has new files (the host made the image again): read it again and rebuild the apps
void disk_reload() {
    hc_text(0x746e756f6d6572, 0);
    hostcall_do();
    if fs_mount() { fsok = 1; }
    build_apps();
}

// the id after "install" / "remove" in the line: copied to hcmd after the 4 or 7 letters that are there
int js_id(int a, int at) {
    int n = 0;
    while a + n < llen && line[a + n] != 32 && n < 80 { hcmd[at + n] = line[a + n]; n += 1; }
    hcmd[at + n] = 0;
    return n;
}

// the command jstore of the console: the same store as the app and as the tool of the terminal of the phone
void js_command() {
    int a = args_at();
    char^ ans = (char^)0x42200000;
    int w = 0;
    int i = 0;
    while a + i < llen && line[a + i] != 32 && i < 8 { w = w | ((line[a + i] & 255) << (i * 8)); i += 1; }
    int b = a + i;
    while b < llen && line[b] == 32 { b += 1; }
    if w == 0x7473696c {
        ans[0] = 0;
        hc_text(0x7473696c, 0);
        int st = hostcall_do();
        if st != 0 { kputs(ans); putc(10); return; }
        int pos = 0;
        while ans[pos] != 0 {
            int e = pos;
            while ans[e] != 0 && ans[e] != 10 { e += 1; }
            if have_pkg(ans, pos) { putc(42); } else { putc(32); }
            putc(32);
            for k in pos..e { if ans[k] == 9 { putc(32); putc(32); } else { putc(ans[k] & 255); } }
            putc(10);
            pos = e;
            if ans[pos] == 10 { pos += 1; }
        }
    } else if w == 0x6c6c6174736e69 || w == 0x746567 {
        hc_text(0x20746567, 0);
        int n = js_id(b, 4);
        if n == 0 { say(0x6a203a6567617375); say(0x6e692065726f7473); say(0x4449206c6c617473); putc(10); return; }
        say(0x64616f6c6e776f64); say(0x2e2e2e20676e69); putc(10);
        int st = hostcall_do();
        if st != 0 { kputs(ans); putc(10); return; }
        disk_reload();
        say(0x656c6c6174736e69); say(0x7369207469202c64); say(0x20656874206e6f20); say(0x72637320656d6f68); say(0x6e6565); putc(10);
    } else if w == 0x65766f6d6572 {
        hc_text(0x2065766f6d6572, 0);
        int n = js_id(b, 7);
        if n == 0 { say(0x6a203a6567617375); say(0x65722065726f7473); say(0x44492065766f6d); putc(10); return; }
        int st = hostcall_do();
        if st != 0 { kputs(ans); putc(10); return; }
        disk_reload();
        say(0x6465766f6d6572); putc(10);
    } else {
        say(0x6c2065726f74736a); say(0x6e69207c20747369); say(0x4449206c6c617473); say(0x766f6d6572207c20); say(0x44492065); putc(10);
    }
}

// one line of the console; false = leave (exit)
bool run_command() {
    int w = first_word();
    if w == 0x736c { fs_ls(); }
    else if w == 0x746163 {
        int a = args_at();
        int n = 0;
        while a + n < llen && n < 47 { name[n] = line[a + n]; n += 1; }
        name[n] = 0;
        fs_cat(@name);
    }
    else if w == 0x6f686365 {
        int a2 = args_at();
        for k in a2..llen { putc(line[k]); }
        putc(10);
    }
    else if w == 0x65726f74736a { js_command(); }
    else if w == 0x6e7572 {                                           // run NAME: a program of the disk runs under the console
        int a3 = args_at();
        int n3 = 0;
        while a3 + n3 < llen && n3 < 47 { name[n3] = line[a3 + n3]; n3 += 1; }
        name[n3] = 0;
        int rc = run_program(@name);
        if scr == 1 { term_redraw(); }                                  // the program may have drawn over the screen
        if rc < 0 { say(0x7220746f6e6e6163); say(0x7469206e75); putc(10); }
        else { say(0x2074697865); putnum(rc); putc(10); }
    }
    else if w == 0x706c6568 { say(0x20746163202c736c); say(0x6365202c454d414e); say(0x2c54584554206f68); say(0x4d414e206e757220); say(0x726f74736a202c45); say(0x68202c2e2e2e2065); say(0x697865202c706c65); say(0x74); putc(10); }
    else if w == 0x74697865 { return false; }
    else if w != 0 { say(0x3f); putc(10); }
    return true;
}

