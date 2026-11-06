// the screen: letters on a picture, the cell grid, colours, scrolling, the font, the wait for a key and a touch (a part of kernel.jk: the files are put together with #import in this order, the globals come before they are used)
// ---- the screen. When the machine has one (the register WIDTH of the screen is not 0) the system draws its letters on it: a picture of 540 x 960 dots at 0x41000000, 54 x 48 cells of 10 x 20 dots;
// the letters are a smooth font (8 bits of cover for each dot) that the system reads from the file jaric-os-font of its disk. The machine shows the picture (FLUSH) when the system waits for a key.
i64 scr;                            
i64 cx;
i64 cy;
i64 gdirty;
i64 shown;
i64 g_ram;                             // the memory of the machine in MB (the machine says)
i64 ram_top;                           // the end of the memory (an address)
i64 gpu_on;                            // 1 when the machine has the 2D accelerator (the rectangles, the wallpaper and the copies are done by the host)
i64 at_home;                           // 1 while the system waits at the home screen (the back key there puts the app in the background)
i64 sfb;                               // where the picture is that is drawn on now: the screen, or the surface of a window of the desktop
i64 desk_ctx;                          // 1 while an app runs in a window of the desktop
i64 scrW;                              // the width of the picture in dots: 540 in portrait; the shape follows the phone
i64 cols;                              // the columns of letters: the width divided by 10
i64 scrH;                              // the height of the picture in dots (the width is 540)
i64 vrows;                             // the rows that are seen (the keyboard of the phone hides some)
i64 maxrows;
i64 sready;
i64 fontsize;                            // 1 when the font is loaded and the screen can be used
i64 seen;                              // the touch events that were looked at
i64 fsok;
i64 gohome;                            // the back button was tapped in the terminal app
i64 g_el;                              // what the start found, for the About app
i64 g_core;
i64 g_dsec;
i64 g_font;
i64 roff;                              // rows at the top of the screen that the apps use for their bar (4 rows = 80 dots)
i64 fgc;                            
char gcol[3800];                          
char gcells[3800];                  
char^ fnt;                          

void draw_cell(i64 col, i64 row, i64 c, i64 cur, i64 k) {
    i64 pb = 255;
    i64 pg = 228;
    i64 pr = 200;
    if k == 1 { pb = 130; pg = 225; pr = 110; }
    if k == 2 { pb = 170; pg = 150; pr = 125; }
    if k == 3 { pb = 100; pg = 100; pr = 240; }
    if k == 4 { pb = 255; pg = 190; pr = 100; }
    char^ fb = (char^)sfb;
    i64 g = 4 + (c - 32) * 200;
    if c < 32 || c > 126 { g = 4; }
    for gy in 0..20 {
        i64 o = (((row + roff) * 20 + gy) * scrW + col * 10) * 4;
        for gx in 0..10 {
            i64 a = fnt[g + gy * 10 + gx] & 255;
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
    i64 bg = 20 | (10 << 8) | (8 << 16) | (255 << 24);
    i64 top = roff * 20;                                // the first row of dots of the letters
    if gpu_on == 1 {
        i64^ g = (i64^)0x0E000000;
        g[1] = sfb; g[2] = scrW; g[3] = 0; g[4] = top; g[5] = sfb; g[6] = scrW; g[7] = 0; g[8] = top + 20; g[9] = scrW; g[10] = (vrows - 1) * 20;
        g[0] = 3;
        g[16] = 1;                                      // the rows that stay go up by one row of letters
        g[1] = sfb; g[2] = scrW; g[3] = 0; g[4] = top + (vrows - 1) * 20; g[5] = scrW; g[6] = 20; g[7] = bg; g[8] = scrW; g[9] = scrH; g[10] = 0;
        g[0] = 1;
        g[16] = 1;                                      // the last row is empty
    } else {
        i64^ fb = (i64^)sfb;
        i64 words = scrW * (vrows - 1) * 20 / 2;
        i64 from = scrW * 20 / 2;
        i64 topw = scrW * roff * 20 / 2;
        for i in 0..words { fb[topw + i] = fb[topw + i + from]; }
        i64 two = bg | (bg << 32);
        for i in words..(scrW * vrows * 20 / 2) { fb[topw + i] = two; }
    }
    for i in 0..(cols * (vrows - 1)) { gcells[i] = gcells[i + cols]; gcol[i] = gcol[i + cols]; }
    for i in (cols * (vrows - 1))..(cols * vrows) { gcells[i] = (char)32; gcol[i] = (char)0; }
}

// the part of the picture that is seen changed (the keyboard came or went): the rows follow, and the cursor is kept in sight
void view_set(i64 vh) {
    if desk_ctx == 1 { return; }                      // in a window the size of the surface is what it is
    i64 r = vh / 20 - roff;
    if r < 6 { r = 6; }
    if r > maxrows { r = maxrows; }
    if shown == 1 { draw_cell(cx, cy, gcells[cy * cols + cx] & 255, 0, gcol[cy * cols + cx]); shown = 0; }
    vrows = r;
    while cy >= vrows { scroll_up(); cy -= 1; }
    i64^ fb = (i64^)0x41000000;
    i64 bg = 20 | (10 << 8) | (8 << 16) | (255 << 24);
    i64 two = bg | (bg << 32);
    for i in (scrW * (vrows + roff) * 20 / 2)..(scrW * scrH / 2) { fb[i] = two; }
    for i in (cols * vrows)..(cols * maxrows) { gcells[i] = (char)32; gcol[i] = (char)0; }
    gdirty = 1;
}

void newline() {
    cx = 0;
    cy += 1;
    if cy >= vrows { scroll_up(); cy = vrows - 1; }
}

void setcol(i64 k) {
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

void putc(i64 c) {
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

i64 getc() {                                   // waits for a key: the flag register says when one is there; the touch device is looked at while waiting
    screen_show();
    i64^ uart = (i64^)0x09000000;
    i64^ ui = (i64^)0x0C000000;
    i64 fr = uart[3];
    while (fr & 16) != 0 {
        i64 sq = ui[0];
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

void say(i64 w) {
    for k in 0..8 {
        i64 c = (w >> (k * 8)) & 255;
        if c == 0 { return; }
        putc(c);
    }
}

void kputs(char^ s) {
    i64 i = 0;
    while s[i] != 0 { putc(s[i]); i += 1; }
}

bool disk_io(i64 cmd, i64 sector, i64 addr, i64 count) {
    i64^ dev = (i64^)0x0A000000;
    dev[1] = sector;
    dev[2] = addr;
    dev[3] = count;
    dev[0] = cmd;
    i64 st = dev[4];
    return st == 0;
}

i64 rd64(char^ p) {
    i64 v = 0;
    for k in 0..8 { v = v | ((p[k] & 255) << (k * 8)); }
    return v;
}

bool fs_mount() {
    if !disk_io(1, 0, (i64)@sbuf, 9) { return false; }
    if sbuf[0] != 'J' || sbuf[1] != '2' || sbuf[2] != 'F' || sbuf[3] != 'S' { return false; }
    nfiles = rd64(@sbuf[8]);
    return true;
}

bool same(char^ a, char^ b) {
    i64 i = 0;
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
            i64 start = rd64(@e[48]);
            i64 size = rd64(@e[56]);
            i64 sectors = (size + 511) / 512;
            if sectors > 8 { sectors = 8; }
            if !disk_io(1, start, (i64)@fbuf, sectors) { say(0x7272652064616572); say(0x726f); putc(10); return; }
            for k in 0..size { putc(fbuf[k]); }
            return;
        }
    }
    say(0x2068637573206f6e); say(0x656c6966); putc(10);
}

// the first word of the line packed into a number (up to eight letters)
i64 first_word() {
    i64 w = 0;
    i64 i = 0;
    while i < 8 && i < llen && line[i] != 32 { w = w | ((line[i] & 255) << (i * 8)); i += 1; }
    return w;
}

// where the arguments start (after the first word and the spaces)
i64 args_at() {
    i64 i = 0;
    while i < llen && line[i] != 32 { i += 1; }
    while i < llen && line[i] == 32 { i += 1; }
    return i;
}

// reads a line with an echo; false at the end of the input
bool read_line() {
    llen = 0;
    while true {
        i64 c = getc();
        if c == 4 { return false; }
        if c == 10 || c == 13 { putc(10); line[llen] = 0; return true; }
        if (c == 127 || c == 8) { if llen > 0 { llen -= 1; putc(8); putc(32); putc(8); } continue; }
        if llen < 120 { line[llen] = (char)c; llen += 1; putc(c); }
    }
    return false;
}

// the font: the file jaric-os-font of the disk, read to 0x42100000; the screen is on when it is there
void screen_start() {
    i64^ fb = (i64^)0x0B000000;
    i64 hh = fb[2];
    i64 ww = fb[1];
    if ww < 480 || ww > 1280 || hh < 480 || hh > 1400 { return; }
    scrW = ww / 10 * 10;
    cols = 0;
    while cols * 10 < scrW { cols += 1; }
    char nm[16];
    nm[0] = 'j'; nm[1] = 'a'; nm[2] = 'r'; nm[3] = 'i'; nm[4] = 'c'; nm[5] = '-'; nm[6] = 'o'; nm[7] = 's'; nm[8] = '-'; nm[9] = 'f'; nm[10] = 'o'; nm[11] = 'n'; nm[12] = 't'; nm[13] = 0;
    for i in 0..nfiles {
        char^ e = @sbuf[512 + i * 64];
        i64 k = 0;
        while nm[k] != 0 && e[k] == nm[k] { k += 1; }
        if nm[k] == 0 && e[k] == 0 {
            i64 start = rd64(@e[48]);
            i64 size = rd64(@e[56]);
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
            i64^ gg = (i64^)0x0E000000;
            if gg[0] == 1 { gpu_on = 1; }
            return;
        }
    }
}

// the screen is used from now on: cleared, the letters go to it and not to the terminal any more
void screen_on() {
    if sready == 0 { return; }
    i64^ fb = (i64^)0x0B000000;
    sfb = 0x41000000;
    i64^ px = (i64^)0x41000000;
    i64 bg = 20 | (10 << 8) | (8 << 16) | (255 << 24);
    i64 two = bg | (bg << 32);
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

