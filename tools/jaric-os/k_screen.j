// the screen: letters on a picture, the cell grid, colours, scrolling, the font, the wait for a key and a touch (a part of kernel.jk: the files are put together with #import in this order, the globals come before they are used)
// ---- the screen. When the machine has one (the register WIDTH of the screen is not 0) the system draws its letters on it: a picture of 540 x 960 dots at 0x41000000, 54 x 48 cells of 10 x 20 dots;
// the letters are a smooth font (8 bits of cover for each dot) that the system reads from the file jaric-os-font of its disk. The machine shows the picture (FLUSH) when the system waits for a key.
int scr;                            
int cx;
int cy;
int gdirty;
int shown;
int g_ram;                             // the memory of the machine in MB (the machine says)
int ram_top;                           // the end of the memory (an address)
int at_home;                           // 1 while the system waits at the home screen (the back key there puts the app in the background)
int sfb;                               // where the picture is that is drawn on now: the screen, or the surface of a window of the desktop
int desk_ctx;                          // 1 while an app runs in a window of the desktop
int scrW;                              // the width of the picture in dots: 540 in portrait; the shape follows the phone
int cols;                              // the columns of letters: the width divided by 10
int scrH;                              // the height of the picture in dots (the width is 540)
int vrows;                             // the rows that are seen (the keyboard of the phone hides some)
int maxrows;
int sready;
int fontsize;                            // 1 when the font is loaded and the screen can be used
int seen;                              // the touch events that were looked at
int fsok;
int gohome;                            // the back button was tapped in the terminal app
int g_el;                              // what the start found, for the About app
int g_core;
int g_dsec;
int g_font;
int roff;                              // rows at the top of the screen that the apps use for their bar (4 rows = 80 dots)
int fgc;                            
char gcol[3800];                          
char gcells[3800];                  
char^ fnt;                          

void draw_cell(int col, int row, int c, int cur, int k) {
    int pb = 255;
    int pg = 228;
    int pr = 200;
    if k == 1 { pb = 130; pg = 225; pr = 110; }
    if k == 2 { pb = 170; pg = 150; pr = 125; }
    if k == 3 { pb = 100; pg = 100; pr = 240; }
    if k == 4 { pb = 255; pg = 190; pr = 100; }
    char^ fb = (char^)sfb;
    int g = 4 + (c - 32) * 200;
    if c < 32 || c > 126 { g = 4; }
    for gy in 0..20 {
        int o = (((row + roff) * 20 + gy) * scrW + col * 10) * 4;
        for gx in 0..10 {
            int a = fnt[g + gy * 10 + gx] & 255;
            if cur == 1 { a = 255 - a; if a < 90 { a = 90; } }
            fb[o] = (char)(20 + ((pb - 20) * a) / 255);
            fb[o + 1] = (char)(10 + ((pg - 10) * a) / 255);
            fb[o + 2] = (char)(8 + ((pr - 8) * a) / 255);
            fb[o + 3] = (char)255;
            o += 4;
        }
    }
}

void scroll_up() {
    int^ fb = (int^)sfb;
    int words = scrW * (vrows - 1) * 20 / 2;          // the rows that stay, two dots in a word
    int from = scrW * 20 / 2;
    int top = scrW * roff * 20 / 2;
    for i in 0..words { fb[top + i] = fb[top + i + from]; }
    int bg = 20 | (10 << 8) | (8 << 16) | (255 << 24);
    int two = bg | (bg << 32);
    for i in words..(scrW * vrows * 20 / 2) { fb[top + i] = two; }
    for i in 0..(cols * (vrows - 1)) { gcells[i] = gcells[i + cols]; gcol[i] = gcol[i + cols]; }
    for i in (cols * (vrows - 1))..(cols * vrows) { gcells[i] = (char)32; gcol[i] = (char)0; }
}

// the part of the picture that is seen changed (the keyboard came or went): the rows follow, and the cursor is kept in sight
void view_set(int vh) {
    if desk_ctx == 1 { return; }                      // in a window the size of the surface is what it is
    int r = vh / 20 - roff;
    if r < 6 { r = 6; }
    if r > maxrows { r = maxrows; }
    if shown == 1 { draw_cell(cx, cy, gcells[cy * cols + cx] & 255, 0, gcol[cy * cols + cx]); shown = 0; }
    vrows = r;
    while cy >= vrows { scroll_up(); cy -= 1; }
    int^ fb = (int^)0x41000000;
    int bg = 20 | (10 << 8) | (8 << 16) | (255 << 24);
    int two = bg | (bg << 32);
    for i in (scrW * (vrows + roff) * 20 / 2)..(scrW * scrH / 2) { fb[i] = two; }
    for i in (cols * vrows)..(cols * maxrows) { gcells[i] = (char)32; gcol[i] = (char)0; }
    gdirty = 1;
}

void newline() {
    cx = 0;
    cy += 1;
    if cy >= vrows { scroll_up(); cy = vrows - 1; }
}

void setcol(int k) {
    fgc = k;
    if scr == 0 {                                    // on the terminal: the colour is an escape code
        uputc(27); uputc(91);
        if k == 0 { uputc(48); }
        if k == 1 { uputc(51); uputc(50); }
        if k == 2 { uputc(57); uputc(48); }
        if k == 3 { uputc(51); uputc(49); }
        if k == 4 { uputc(51); uputc(54); }
        uputc(109);
    }
}

void putc(int c) {
    if scr == 0 { uputc(c); return; }
    if shown == 1 { draw_cell(cx, cy, gcells[cy * cols + cx] & 255, 0, gcol[cy * cols + cx]); shown = 0; }
    gdirty = 1;
    if c == 10 { newline(); return; }
    if c == 13 { cx = 0; return; }
    if c == 8 { if cx > 0 { cx -= 1; } return; }
    if c < 32 || c > 126 { return; }
    if cx >= cols { newline(); }
    gcells[cy * cols + cx] = (char)c;
    gcol[cy * cols + cx] = (char)fgc;
    draw_cell(cx, cy, c, 0, fgc);
    cx += 1;
}

// the picture is shown (with the cursor) before the system waits for a key
void screen_show() {
    if scr == 0 || gdirty == 0 { return; }
    if cx >= cols { newline(); }
    draw_cell(cx, cy, gcells[cy * cols + cx] & 255, 1, 0);
    shown = 1;
    present();                                       // the picture is shown (in a window of the desktop it is put in the desktop first)
    gdirty = 0;
}

int getc() {                                   // waits for a key: the flag register says when one is there; the touch device is looked at while waiting
    screen_show();
    int^ uart = (int^)0x09000000;
    int^ ui = (int^)0x0C000000;
    int fr = uart[3];
    while (fr & 16) != 0 {
        int sq = ui[0];
        if sq != seen {
            seen = sq;
            if ui[3] == 4 && scr == 1 { view_set(ui[2]); screen_show(); }
            if ui[3] == 6 && scr == 1 { gohome = 1; return 4; }                                    // the back key in the terminal app: go home
            if ui[3] == 1 && scr == 1 && ((ui[2] < 76 && ui[1] < 170) || ui[2] > scrH - 70) { gohome = 1; return 4; }
        }
        fr = uart[3];
    }
    return uart[0] & 255;
}

void say(int w) {
    for k in 0..8 {
        int c = (w >> (k * 8)) & 255;
        if c == 0 { return; }
        putc(c);
    }
}

void kputs(char^ s) {
    int i = 0;
    while s[i] != 0 { putc(s[i]); i += 1; }
}

bool disk_io(int cmd, int sector, int addr, int count) {
    int^ dev = (int^)0x0A000000;
    dev[1] = sector;
    dev[2] = addr;
    dev[3] = count;
    dev[0] = cmd;
    int st = dev[4];
    return st == 0;
}

int rd64(char^ p) {
    int v = 0;
    for k in 0..8 { v = v | ((p[k] & 255) << (k * 8)); }
    return v;
}

bool fs_mount() {
    if !disk_io(1, 0, (int)@sbuf, 9) { return false; }
    if sbuf[0] != 'J' || sbuf[1] != '2' || sbuf[2] != 'F' || sbuf[3] != 'S' { return false; }
    nfiles = rd64(@sbuf[8]);
    return true;
}

bool same(char^ a, char^ b) {
    int i = 0;
    while a[i] != 0 && b[i] != 0 { if a[i] != b[i] { return false; } i += 1; }
    return a[i] == b[i];
}

void fs_ls() {
    for i in 0..nfiles {
        char^ e = @sbuf[512 + i * 64];
        if e[0] == 'j' && e[1] == 'a' && e[2] == 'r' && e[3] == 'i' && e[4] == 'c' && e[5] == '-' { continue; }   
        kputs(e);
        putc(10);
    }
}

void fs_cat(char^ nm) {
    for i in 0..nfiles {
        char^ e = @sbuf[512 + i * 64];
        if same(e, nm) {
            int start = rd64(@e[48]);
            int size = rd64(@e[56]);
            int sectors = (size + 511) / 512;
            if sectors > 8 { sectors = 8; }
            if !disk_io(1, start, (int)@fbuf, sectors) { say(0x7272652064616572); say(0x726f); putc(10); return; }
            for k in 0..size { putc(fbuf[k]); }
            return;
        }
    }
    say(0x2068637573206f6e); say(0x656c6966); putc(10);
}

// the first word of the line packed into a number (up to eight letters)
int first_word() {
    int w = 0;
    int i = 0;
    while i < 8 && i < llen && line[i] != 32 { w = w | ((line[i] & 255) << (i * 8)); i += 1; }
    return w;
}

// where the arguments start (after the first word and the spaces)
int args_at() {
    int i = 0;
    while i < llen && line[i] != 32 { i += 1; }
    while i < llen && line[i] == 32 { i += 1; }
    return i;
}

// reads a line with an echo; false at the end of the input
bool read_line() {
    llen = 0;
    while true {
        int c = getc();
        if c == 4 { return false; }
        if c == 10 || c == 13 { putc(10); line[llen] = 0; return true; }
        if (c == 127 || c == 8) { if llen > 0 { llen -= 1; putc(8); putc(32); putc(8); } continue; }
        if llen < 120 { line[llen] = (char)c; llen += 1; putc(c); }
    }
    return false;
}

// the font: the file jaric-os-font of the disk, read to 0x42100000; the screen is on when it is there
void screen_start() {
    int^ fb = (int^)0x0B000000;
    int hh = fb[2];
    int ww = fb[1];
    if ww < 480 || ww > 1280 || hh < 480 || hh > 1400 { return; }
    scrW = ww / 10 * 10;
    cols = 0;
    while cols * 10 < scrW { cols += 1; }
    char nm[16];
    nm[0] = 'j'; nm[1] = 'a'; nm[2] = 'r'; nm[3] = 'i'; nm[4] = 'c'; nm[5] = '-'; nm[6] = 'o'; nm[7] = 's'; nm[8] = '-'; nm[9] = 'f'; nm[10] = 'o'; nm[11] = 'n'; nm[12] = 't'; nm[13] = 0;
    for i in 0..nfiles {
        char^ e = @sbuf[512 + i * 64];
        int k = 0;
        while nm[k] != 0 && e[k] == nm[k] { k += 1; }
        if nm[k] == 0 && e[k] == 0 {
            int start = rd64(@e[48]);
            int size = rd64(@e[56]);
            if size < 4 || size > 60000 { return; }
            if !disk_io(1, start, 0x42100000, (size + 511) / 512) { return; }
            fnt = (char^)0x42100000;
            if (fnt[0] & 255) != 10 || (fnt[1] & 255) != 20 { return; }
            scrH = hh / 20 * 20;
            roff = 4;
            maxrows = scrH / 20 - roff;
            vrows = maxrows;
            fontsize = size;
            sready = 1;
            return;
        }
    }
}

// the screen is used from now on: cleared, the letters go to it and not to the terminal any more
void screen_on() {
    if sready == 0 { return; }
    int^ fb = (int^)0x0B000000;
    sfb = 0x41000000;
    int^ px = (int^)0x41000000;
    int bg = 20 | (10 << 8) | (8 << 16) | (255 << 24);
    int two = bg | (bg << 32);
    for p in 0..(scrW * scrH / 2) { px[p] = two; }
    for p in 0..(cols * maxrows) { gcells[p] = (char)32; gcol[p] = (char)0; }
    fb[0] = 0x41000000;
    fb[1] = scrW;
    fb[2] = scrH;                                    // the picture is whole rows of letters
    cx = 0;
    cy = 0;
    shown = 0;
    scr = 1;
}

