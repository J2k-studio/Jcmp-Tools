// the phone: the home screen, the icons, the dock and the apps (files, clock, about) (a part of kernel.jk: the files are put together with #import in this order, the globals come before they are used)
// ---- the phone: a home screen with icons, a dock, and the apps. Everything is drawn here with the smooth font; the touch device tells where a finger is.
u32^ p32;
char tb[24];
char mbuf[1100];                       // a manifest that is read from the disk
char anames[256];                      // 16 apps, 16 letters each
int akind[16];                         // 0 terminal, 1 files, 2 clock, 3 about, 4 a .jc package (aidx = its place in the directory), 5 power
int aidx[16];
int napps;
int ev;                                // what wait_event found: 0 a key, 1 down, 2 move, 3 up (4, the seen height, is taken care of inside)
int ev_x;
int ev_y;
int ev_key;
int dn_x;
int dn_y;
int tap_x;
int tap_y;

int rgb(int r, int g, int b) { return b | (g << 8) | (r << 16) | (255 << 24); }

void fill_sw(int x, int y, int w, int h, int c) {
    for yy in y..(y + h) {
        if yy >= 0 && yy < scrH {
            int base = yy * scrW;
            for xx in x..(x + w) { if xx >= 0 && xx < scrW { p32[base + xx] = (u32)c; } }
        }
    }
}

void rrect_sw(int x, int y, int w, int h, int r, int c) {
    for yy in y..(y + h) {
        if yy >= 0 && yy < scrH {
            int dy = 0;
            if yy < y + r { dy = y + r - 1 - yy; }
            if yy >= y + h - r { dy = yy - (y + h - r); }
            int base = yy * scrW;
            for xx in x..(x + w) {
                if xx >= 0 && xx < scrW {
                    int dx = 0;
                    if xx < x + r { dx = x + r - 1 - xx; }
                    if xx >= x + w - r { dx = xx - (x + w - r); }
                    if dx * dx + dy * dy <= r * r { p32[base + xx] = (u32)c; }
                }
            }
        }
    }
}

// the page behind everything: dark blue that gets lighter downwards
void wallpaper_sw() {
    for y in 0..scrH {
        int c = rgb(8 + y / 90, 10 + y / 50, 24 + y / 14);
        int base = y * scrW;
        for x in 0..scrW { p32[base + x] = (u32)c; }
    }
}


// the 2D accelerator (at 0x0E000000): one write per rectangle instead of a loop of the machine
void gpu_go(int op, int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9, int a10) {
    int^ g = (int^)0x0E000000;
    g[1] = a1; g[2] = a2; g[3] = a3; g[4] = a4; g[5] = a5; g[6] = a6; g[7] = a7; g[8] = a8; g[9] = a9; g[10] = a10;
    g[0] = op;
    g[16] = 1;
}

void fill(int x, int y, int w, int h, int c) {
    if gpu_on == 0 { fill_sw(x, y, w, h, c); return; }
    gpu_go(1, sfb, scrW, x, y, w, h, c, scrW, scrH, 0);
}

void wallpaper() {
    if gpu_on == 0 { wallpaper_sw(); return; }
    gpu_go(2, sfb, scrW, scrW, scrH, 0, 0, 0, 0, 0, 0);
}

// a rounded rectangle: the middle is one rectangle, each row of the two round ends is one rectangle (the width comes from the circle)
void rrect(int x, int y, int w, int h, int r, int c) {
    if gpu_on == 0 { rrect_sw(x, y, w, h, r, c); return; }
    int rr = r;
    if rr * 2 > h { rr = h >> 1; }
    if rr * 2 > w { rr = w >> 1; }
    fill(x, y + rr, w, h - 2 * rr, c);
    for i in 0..rr {
        int dy = rr - 1 - i;
        int m = 0;
        while (m + 1) * (m + 1) + dy * dy <= rr * rr { m += 1; }
        if m > rr - 1 { m = rr - 1; }
        int inset = rr - 1 - m;
        fill(x + inset, y + i, w - 2 * inset, 1, c);
        fill(x + inset, y + h - 1 - i, w - 2 * inset, 1, c);
    }
}

void blend(int x, int y, int c, int a) {
    if x < 0 || x >= scrW || y < 0 || y >= scrH { return; }
    int o = (int)p32[y * scrW + x];
    int ob = o & 255;
    int og = (o >> 8) & 255;
    int orr = (o >> 16) & 255;
    int cb = c & 255;
    int cg = (c >> 8) & 255;
    int cr = (c >> 16) & 255;
    int nb = ob + ((cb - ob) * a) / 255;
    int ng = og + ((cg - og) * a) / 255;
    int nr = orr + ((cr - orr) * a) / 255;
    p32[y * scrW + x] = (u32)(nb | (ng << 8) | (nr << 16) | (255 << 24));
}

void glyph(int x, int y, int ch, int sc, int c) {
    if ch < 32 || ch > 126 { return; }
    int g = 4 + (ch - 32) * 200;
    for gy in 0..20 {
        for gx in 0..10 {
            int a = fnt[g + gy * 10 + gx] & 255;
            if a > 6 {
                if sc == 1 { blend(x + gx, y + gy, c, a); }
                else {
                    for sy in 0..sc { for sx in 0..sc { blend(x + gx * sc + sx, y + gy * sc + sy, c, a); } }
                }
            }
        }
    }
}

void text(int x, int y, char^ s, int sc, int c) {
    int i = 0;
    while s[i] != 0 { glyph(x + i * 10 * sc, y, s[i] & 255, sc, c); i += 1; }
}

// up to eight letters that are in a number (the first one in the lowest byte)
void t8(int x, int y, int w, int sc, int c) {
    for k in 0..8 {
        int ch = (w >> (k * 8)) & 255;
        if ch == 0 { return; }
        glyph(x + k * 10 * sc, y, ch, sc, c);
    }
}

void num(int x, int y, int v, int sc, int c) {
    int n = 0;
    char d[20];
    if v == 0 { d[0] = '0'; n = 1; }
    while v > 0 { d[n] = (char)(48 + v % 10); v = v / 10; n += 1; }
    for k in 0..n { glyph(x + k * 10 * sc, y, d[n - 1 - k] & 255, sc, c); }
}

int digits(int v) {
    int n = 1;
    while v >= 10 { v = v / 10; n += 1; }
    return n;
}

void present() {
    if desk_ctx == 1 { composite(); return; }         // in a window: the surface goes into the picture of the desktop first
    int^ fb = (int^)0x0B000000;
    fb[3] = 1;
}

void keyboard(int on) {
    int^ fb = (int^)0x0B000000;
    fb[4] = on;                                    // the register KEYBOARD (0x20): the app shows or hides the keyboard
}

int icon_color(int i) {
    int k = i % 6;
    if k == 0 { return rgb(70, 150, 255); }
    if k == 1 { return rgb(90, 200, 140); }
    if k == 2 { return rgb(255, 160, 80); }
    if k == 3 { return rgb(190, 120, 240); }
    if k == 4 { return rgb(240, 100, 130); }
    return rgb(80, 200, 220);
}

void setname(int i, int w0, int w1) {
    for k in 0..8 { anames[i * 16 + k] = (char)((w0 >> (k * 8)) & 255); }
    for k in 0..8 { anames[i * 16 + 8 + k] = (char)((w1 >> (k * 8)) & 255); }
    anames[i * 16 + 15] = 0;
}

void addapp(int kind, int w0, int w1, int idx) {
    if napps >= 16 { return; }
    setname(napps, w0, w1);
    akind[napps] = kind;
    aidx[napps] = idx;
    napps += 1;
}

// the apps: the ones of the system, then the .jc packages that are on the disk
void build_apps() {
    napps = 0;
    addapp(0, 0x6c616e696d726554, 0, 0);
    addapp(1, 0x73656c6946, 0, 0);
    addapp(6, 0x65726f74736a, 0, 0);
    addapp(3, 0x74756f6241, 0, 0);
    addapp(2, 0x6b636f6c43, 0, 0);
    addapp(5, 0x7265776f50, 0, 0);
    // the apps that came in packages: for each ID.mf (the manifest) on the disk an app with the name of the manifest; ID.run is its program
    for i in 0..nfiles {
        char^ e = @sbuf[512 + i * 64];
        int l = 0;
        while e[l] != 0 { l += 1; }
        if l > 3 && l < 34 && e[l - 3] == '.' && e[l - 2] == 'm' && e[l - 1] == 'f' && napps < 16 {
            int start = rd64(@e[48]);
            int size = rd64(@e[56]);
            if size > 1000 { size = 1000; }
            disk_io(1, start, (int)@mbuf, 2);
            mbuf[size] = 0;
            int n = 0;
            int p = 0;
            while p < size && n == 0 {                              // the line  name = "..."
                int q = p;
                while q < size && mbuf[q] != 10 { q += 1; }
                if mbuf[p] == 'n' && mbuf[p + 1] == 'a' && mbuf[p + 2] == 'm' && mbuf[p + 3] == 'e' {
                    int r = p + 4;
                    while r < q && mbuf[r] != 34 { r += 1; }
                    r += 1;
                    while r < q && mbuf[r] != 34 && n < 13 { anames[napps * 16 + n] = mbuf[r]; n += 1; r += 1; }
                }
                p = q + 1;
            }
            if n == 0 { for k in 0..(l - 3) { if k < 13 { anames[napps * 16 + k] = e[k]; n += 1; } } }
            anames[napps * 16 + n] = 0;
            akind[napps] = 4;
            aidx[napps] = i;
            napps += 1;
        }
    }
}

// one icon: a rounded square in the colour of the app and its first letter; the name under it

// turning off asks first: a card with Cancel and Turn off (a tap on the icon must not end the machine)
bool power_ask() {
    int cw = 440;
    int cxp = (scrW - cw) / 2;
    int cyp = scrH / 2 - 110;
    rrect(cxp - 4, cyp - 4, cw + 8, 228, 34, rgb(60, 78, 130));
    rrect(cxp, cyp, cw, 220, 32, rgb(26, 36, 66));
    t8(cxp + 40 + 0, cyp + 34, 0x66666f206e727554, 2, rgb(255, 255, 255)); t8(cxp + 40 + 160, cyp + 34, 0x3f, 2, rgb(255, 255, 255));
    t8(cxp + 40 + 0, cyp + 90, 0x534f20636972614a, 1, rgb(150, 175, 215)); t8(cxp + 40 + 80, cyp + 90, 0x7473206c6c697720, 1, rgb(150, 175, 215)); t8(cxp + 40 + 160, cyp + 90, 0x2e706f, 1, rgb(150, 175, 215));
    rrect(cxp + 30, cyp + 140, 180, 56, 28, rgb(50, 66, 112));
    t8(cxp + 30 + 54 + 0, cyp + 158, 0x6c65636e6143, 1, rgb(235, 242, 255));
    rrect(cxp + cw - 210, cyp + 140, 180, 56, 28, rgb(220, 70, 70));
    t8(cxp + cw - 210 + 38 + 0, cyp + 158, 0x66666f206e727554, 1, rgb(255, 255, 255));
    present();
    while true {
        int r = wait_event();
        if r != 1 { continue; }
        if tap_y >= cyp + 140 && tap_y < cyp + 196 {
            if tap_x >= cxp + 30 && tap_x < cxp + 210 { return false; }
            if tap_x >= cxp + cw - 210 && tap_x < cxp + cw - 30 { return true; }
        }
        if tap_y < cyp || tap_y > cyp + 220 || tap_x < cxp || tap_x > cxp + cw { return false; }      // a tap outside the card: cancel
    }
    return false;
}

void draw_icon(int x, int y, int app, int size) {
    int c = icon_color(app);
    if akind[app] == 5 { c = rgb(220, 70, 70); }
    rrect(x, y, size, size, size / 4, c);
    int ch = anames[app * 16] & 255;
    if ch >= 97 && ch <= 122 { ch = ch - 32; }
    if size < 60 { glyph(x + (size - 10) / 2, y + (size - 20) / 2, ch, 1, rgb(255, 255, 255)); }
    else { glyph(x + (size - 30) / 2, y + (size - 60) / 2, ch, 3, rgb(255, 255, 255)); }
}

void label(int mx, int y, int app) {
    int l = 0;
    while anames[app * 16 + l] != 0 && l < 13 { tb[l] = anames[app * 16 + l]; l += 1; }
    tb[l] = 0;
    text(mx - l * 5, y, @tb, 1, rgb(225, 235, 250));
}

int dock_app(int i) { return i; }

void draw_home() {
    wallpaper();
    // the bar at the top: the name on the left, how long it is on on the right
    t8(16 + 0, 12, 0x534f20636972614a, 1, rgb(190, 205, 230));

    int up = Sys::s3_3_c14_c0_2 / 1000000;
    int mm = up / 60;
    int ss = up % 60;
    t8(400 + 0, 12, 0x7075, 1, rgb(190, 205, 230));

    num(430, 12, mm, 1, rgb(190, 205, 230));
    glyph(430 + digits(mm) * 10, 12, 58, 1, rgb(190, 205, 230));
    if ss < 10 { glyph(440 + digits(mm) * 10, 12, 48, 1, rgb(190, 205, 230)); num(450 + digits(mm) * 10, 12, ss, 1, rgb(190, 205, 230)); }
    else { num(440 + digits(mm) * 10, 12, ss, 1, rgb(190, 205, 230)); }
    // the greeting
    t8(28 + 0, 78, 0x534f20636972614a, 3, rgb(255, 255, 255));

    t8(30 + 0, 150, 0x2064657265776f70, 1, rgb(150, 175, 215)); t8(30 + 80, 150, 0x636972614a207962, 1, rgb(150, 175, 215));

    // a card with what the machine is
    rrect(20, 200, 500, 150, 30, rgb(26, 36, 66));
    t8(44 + 0, 218, 0x616d2034364d5241, 1, rgb(150, 175, 215)); t8(44 + 80, 218, 0x656e696863, 1, rgb(150, 175, 215));
    num(44, 252, g_dsec, 1, rgb(235, 242, 255));
    t8(44 + digits(g_dsec) * 10 + 10 + 0, 252, 0x2073726f74636573, 1, rgb(235, 242, 255)); t8(44 + digits(g_dsec) * 10 + 10 + 80, 252, 0x6b73696420666f, 1, rgb(235, 242, 255));
    num(44, 286, g_ram, 1, rgb(235, 242, 255)); t8(44 + digits(g_ram) * 10 + 10, 286, 0x656d20666f20424d, 1, rgb(235, 242, 255)); t8(44 + digits(g_ram) * 10 + 90, 286, 0x79726f6d, 1, rgb(235, 242, 255));
    num(44, 320, nfiles, 1, rgb(235, 242, 255));
    t8(44 + digits(nfiles) * 10 + 10 + 0, 320, 0x6e6f2073656c6966, 1, rgb(235, 242, 255)); t8(44 + digits(nfiles) * 10 + 10 + 80, 320, 0x7369642065687420, 1, rgb(235, 242, 255)); t8(44 + digits(nfiles) * 10 + 10 + 160, 320, 0x6b, 1, rgb(235, 242, 255));
    // the power icon and the apps that are packages (.jc)
    for a in 4..napps {
        int k = a - 4;
        int col = k % 4;
        int row = k / 4;
        int cell_x = col * 135;
        draw_icon(cell_x + 23, 390 + row * 160, a, 88);
        label(cell_x + 67, 390 + row * 160 + 98, a);
    }
    // the dock
    rrect(20, scrH - 230, 500, 160, 34, rgb(26, 36, 66));
    for d in 0..4 {
        draw_icon(50 + d * 118, scrH - 214, d, 88);
        label(94 + d * 118, scrH - 214 + 98, d);
    }
    rrect(200, scrH - 34, 140, 8, 4, rgb(210, 220, 240));
    present();
}

// the bar of an app: a back button and the title
void draw_bar(int w0, int w1) {
    fill(0, 0, scrW, 76, rgb(24, 32, 58));
    t8(16 + 0, 28, 0x656d6f48203c, 1, rgb(120, 190, 255));

    t8(200, 22, w0, 2, rgb(255, 255, 255));
    t8(280, 22, w1, 2, rgb(255, 255, 255));
}

// waits for something: a key, or a touch (a tap is a down and an up near each other: tap_x and tap_y); the seen height of the picture is taken care of here
// returns 0 a key (ev_key), 1 a tap (tap_x, tap_y)
int wait_event() {
    int^ uart = (int^)0x09000000;
    int^ ui = (int^)0x0C000000;
    while true {
        int fr = uart[3];
        if (fr & 16) == 0 { ev_key = uart[0] & 255; return 0; }
        int sq = ui[0];
        if sq != seen {
            seen = sq;
            int st = ui[3];
            if st == 4 { view_set(ui[2]); gdirty = 1; }
            else if st == 6 {                                              // the back key of the phone
                int^ ui2 = (int^)ui;
                if at_home == 1 { int^ scrr = (int^)0x0B000000; scrr[5] = 1; }        // at the home screen: the app goes to the background
                else { tap_x = 0; tap_y = 0; return 1; }                  // in an app, a card ...: the same as its back button
            }
            else if st == 1 { dn_x = ui[1]; dn_y = ui[2]; }
            else if st == 3 {
                int dx = ui[1] - dn_x;
                int dy = ui[2] - dn_y;
                if dx < 0 { dx = 0 - dx; }
                if dy < 0 { dy = 0 - dy; }
                if dn_y < 50 && ui[2] - dn_y > 100 && desk_ctx == 0 && dx < 120 { control_panel(); gdirty = 1; continue; }          // the swipe down from the top edge: the control panel
                if dx < 40 && dy < 40 {
                    tap_x = ui[1];
                    tap_y = ui[2];
                    if tap_map() { return 1; }                      // in a window the place is the place in the window
                }
            }
        }
    }
    return 0;
}

bool is_home_tap() { return tap_y < 76 && tap_x < 170 || tap_y > scrH - 70; }

void app_wait_home() {
    while true {
        int r = wait_event();
        if r == 1 && is_home_tap() { return; }
    }
}

void app_files() {
    wallpaper();
    draw_bar(0x73656c6946, 0);
    int row = 0;
    for i in 0..nfiles {
        char^ e = @sbuf[512 + i * 64];
        if e[0] == 'j' && e[1] == 'a' && e[2] == 'r' && e[3] == 'i' && e[4] == 'c' && e[5] == '-' { continue; }
        int fl = 0;
        while e[fl] != 0 { fl += 1; }
        if fl > 3 && e[fl - 3] == '.' && e[fl - 2] == 'm' && e[fl - 1] == 'f' { continue; }              // the files of the apps are the business of the system
        if fl > 4 && e[fl - 4] == '.' && e[fl - 3] == 'r' && e[fl - 2] == 'u' && e[fl - 1] == 'n' { continue; }
        int y = 96 + row * 58;
        rrect(16, y, 508, 50, 14, rgb(26, 36, 66));
        text(32, y + 15, e, 1, rgb(235, 242, 255));
        int size = rd64(@e[56]);
        num(430 - (digits(size) - 1) * 10, y + 15, size, 1, rgb(150, 175, 215));
        t8(470 + 0, y + 15, 0x7365747962, 1, rgb(150, 175, 215));

        row += 1;
    }
    if row == 0 { t8(28 + 0, 110, 0x6b73696420656854, 1, rgb(150, 175, 215)); t8(28 + 80, 110, 0x206f6e2073616820, 1, rgb(150, 175, 215)); t8(28 + 160, 110, 0x2e73656c6966, 1, rgb(150, 175, 215));
 }
    present();
    app_wait_home();
}

void app_clock() {
    while true {
        wallpaper();
        draw_bar(0x6b636f6c43, 0);
        int up = Sys::s3_3_c14_c0_2 / 1000000;
        int mm = up / 60;
        int ss = up % 60;
        int x = 270 - ((digits(mm) + 3) * 60) / 2;
        num(x, 300, mm, 6, rgb(255, 255, 255));
        glyph(x + digits(mm) * 60, 300, 58, 6, rgb(120, 190, 255));
        glyph(x + digits(mm) * 60 + 60, 300, 48 + ss / 10, 6, rgb(255, 255, 255));
        glyph(x + digits(mm) * 60 + 120, 300, 48 + ss % 10, 6, rgb(255, 255, 255));
        t8(150 + 0, 470, 0x6e697320656d6974, 1, rgb(150, 175, 215)); t8(150 + 80, 470, 0x6d20656874206563, 1, rgb(150, 175, 215)); t8(150 + 160, 470, 0x7320656e69686361, 1, rgb(150, 175, 215)); t8(150 + 240, 470, 0x646574726174, 1, rgb(150, 175, 215));

        t8(150 + 0, 500, 0x77796e6120706174, 1, rgb(150, 175, 215)); t8(150 + 80, 500, 0x206f742065726568, 1, rgb(150, 175, 215)); t8(150 + 160, 500, 0x616761206b6f6f6c, 1, rgb(150, 175, 215)); t8(150 + 240, 500, 0x6e69, 1, rgb(150, 175, 215));

        present();
        int r = wait_event();
        if r == 1 && is_home_tap() { return; }
    }
}

void line_kv(int y, int w0, int w1, int v, int w2) {
    rrect(16, y, 508, 50, 14, rgb(26, 36, 66));
    t8(32, y + 15, w0, 1, rgb(150, 175, 215));
    t8(112, y + 15, w1, 1, rgb(150, 175, 215));
    num(250, y + 15, v, 1, rgb(235, 242, 255));
    t8(250 + digits(v) * 10 + 10, y + 15, w2, 1, rgb(235, 242, 255));
}

void app_about() {
    wallpaper();
    draw_bar(0x74756f6241, 0);
    t8(28 + 0, 100, 0x534f20636972614a, 2, rgb(255, 255, 255)); t8(28 + 160, 100, 0x332e3020, 2, rgb(255, 255, 255));

    t8(30 + 0, 150, 0x2064657265776f70, 1, rgb(150, 175, 215)); t8(30 + 80, 150, 0x636972614a207962, 1, rgb(150, 175, 215));

    line_kv(190, 0x555043, 0x6c6576656c, g_el, 0);
    line_kv(250, 0x555043, 0x65726f63, g_core, 0);
    line_kv(310, 0x79726f6d654d, 0, g_ram, 0x424d);
    line_kv(370, 0x6b736944, 0, g_dsec, 0x73726f74636573);
    line_kv(430, 0x73656c6946, 0, nfiles, 0);
    line_kv(490, 0x6e6565726353, 0, scrW, 0x656469772073746f64);
    line_kv(550, 0x6e6565726353, 0, scrH, 0x686769682073746f64);
    line_kv(610, 0x746e6f46, 0, g_font, 0x7365747962);
    present();
    app_wait_home();
}

// an app of a package: the splash (its icon and name), then its program runs; the swipe up from the bottom edge closes it
void app_launch(int app) {
    wallpaper();
    draw_icon(180, 400, app, 180);
    int l = 0;
    while anames[app * 16 + l] != 0 && l < 13 { tb[l] = anames[app * 16 + l]; l += 1; }
    tb[l] = 0;
    text(270 - l * 10, 620, @tb, 2, rgb(255, 255, 255));
    present();
    fill(0, 0, scrW, scrH, rgb(0, 0, 0));                              // the app has the whole screen (the splash stays on the picture that the host has until the first picture of the app)
    char^ e = @sbuf[512 + aidx[app] * 64];
    int el = 0;
    while e[el] != 0 { el += 1; }
    for k in 0..(el - 2) { name[k] = e[k]; }                          // ID.mf -> ID.run
    name[el - 2] = 'r';
    name[el - 1] = 'u';
    name[el] = 'n';
    name[el + 1] = 0;
    int rc = run_program(@name);
    if rc < 0 {
        wallpaper();
        draw_icon(180, 400, app, 180);
        t8(150, 640, 0x6f20746f6e6e6143, 1, rgb(255, 215, 120)); t8(230, 640, 0x73696874206e6570, 1, rgb(255, 215, 120)); t8(310, 640, 0x2e70706120, 1, rgb(255, 215, 120));
        present();
        app_wait_home();
    }
}


