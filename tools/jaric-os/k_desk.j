// ---- the desktop (the phone on its side): a wallpaper with the icons of the apps, a taskbar at the bottom (the start button, the apps that are pinned, the time since start), and a window
// for the app that runs: a title bar with the name and a close button, the app inside on a surface of its own (the apps are the same as on the phone: the surface is 540 dots wide).
// A part of kernel.jk: put together with #import after the phone.
int rootW;                             // the picture of the desktop
int rootH;
int win_x;
int win_y;
int win_w;
int win_h;
int win_app;                           // the app in the window, -1 when there is none
int surf_h;                            // the height of the surface of the window

void to_root() {
    sfb = 0x41000000;
    p32 = (u32^)sfb;
    scrW = rootW;
    scrH = rootH;
}

void to_win() {
    sfb = 0x41400000;
    p32 = (u32^)sfb;
    scrW = 540;
    scrH = surf_h;
}

// the place of a tap in the window (when an app runs in one); false when the tap is not for the app
bool tap_map() {
    if desk_ctx == 0 { return true; }
    int ax = tap_x;
    int ay = tap_y;
    if ay >= win_y && ay < win_y + 36 {                                  // the title bar: the close button is the back button of the app
        if ax >= win_x + win_w - 48 && ax < win_x + win_w { tap_x = 0; tap_y = 0; return true; }
        return false;
    }
    if ax >= win_x && ax < win_x + win_w && ay >= win_y + 36 && ay < win_y + win_h {
        tap_x = ax - win_x;
        tap_y = ay - win_y - 36;
        return true;
    }
    return false;
}

// the frame of the window and the surface of the app inside it are put in the picture of the desktop, and the picture is shown
void composite() {
    int^ surf = (int^)0x41400000;
    u32^ root = (u32^)0x41000000;
    u32^ s32 = (u32^)0x41400000;
    int sh = surf_h;
    for y in 0..sh {
        int ro = (win_y + 36 + y) * rootW + win_x;
        int so = y * 540;
        for x in 0..540 { root[ro + x] = s32[so + x]; }
    }
    int keep_w = scrW;
    int keep_h = scrH;
    int keep_s = sfb;
    sfb = 0x41000000;
    p32 = (u32^)sfb;
    scrW = rootW;
    scrH = rootH;
    rrect(win_x - 3, win_y - 3, win_w + 6, win_h + 6, 16, rgb(48, 62, 104));
    int^ keepme = surf;
    // the title bar
    rrect(win_x, win_y, win_w, 40, 14, rgb(30, 42, 78));
    fill(win_x, win_y + 24, win_w, 12, rgb(30, 42, 78));
    char^ nm = @anames[win_app * 16];
    int l = 0;
    while nm[l] != 0 && l < 15 { tb[l] = nm[l]; l += 1; }
    tb[l] = 0;
    text(win_x + 16, win_y + 8, @tb, 1, rgb(235, 242, 255));
    rrect(win_x + win_w - 40, win_y + 6, 28, 24, 8, rgb(200, 70, 80));
    glyph(win_x + win_w - 35, win_y + 7, 120, 1, rgb(255, 255, 255));
    // the surface again (the frame went over its edge by a few dots)
    for y in 0..sh {
        int ro = (win_y + 36 + y) * rootW + win_x;
        int so = y * 540;
        for x in 0..540 { root[ro + x] = s32[so + x]; }
    }
    taskbar();
    scrW = keep_w;
    scrH = keep_h;
    sfb = keep_s;
    p32 = (u32^)sfb;
    int^ fb = (int^)0x0B000000;
    fb[3] = 1;
}

void taskbar() {
    fill(0, rootH - 64, rootW, 64, rgb(14, 20, 40));
    rrect(14, rootH - 54, 44, 44, 14, rgb(70, 150, 255));
    glyph(14 + 17, rootH - 54 + 12, 74, 1, rgb(255, 255, 255));
    for d in 0..4 { draw_icon(76 + d * 60, rootH - 54, d, 44); }
    int up = Sys::s3_3_c14_c0_2 / 1000000;
    int mm = up / 60;
    int ss = up % 60;
    t8(rootW - 150, rootH - 44, 0x7075, 1, rgb(190, 205, 230));
    num(rootW - 120, rootH - 44, mm, 1, rgb(190, 205, 230));
    glyph(rootW - 120 + digits(mm) * 10, rootH - 44, 58, 1, rgb(190, 205, 230));
    if ss < 10 { glyph(rootW - 110 + digits(mm) * 10, rootH - 44, 48, 1, rgb(190, 205, 230)); num(rootW - 100 + digits(mm) * 10, rootH - 44, ss, 1, rgb(190, 205, 230)); }
    else { num(rootW - 110 + digits(mm) * 10, rootH - 44, ss, 1, rgb(190, 205, 230)); }
}

void desk_draw() {
    to_root();
    wallpaper();
    for a in 0..napps {
        int col = a / 4;
        int row = a % 4;
        int x = 24 + col * 110;
        int y = 20 + row * 120;
        draw_icon(x + 10, y, a, 76);
        label(x + 48, y + 84, a);
    }
    taskbar();
    if win_app >= 0 { composite(); return; }
    present();
}

// opens the app in the window and runs it until it is closed (its back button, or the close button of the window)
void open_window(int app) {
    win_app = app;
    win_w = 540;
    win_h = rootH - 64 - 24;
    surf_h = win_h - 36;
    win_x = (rootW - win_w) / 2;
    win_y = 12;
    desk_ctx = 1;
    to_win();
    maxrows = scrH / 20 - roff;
    vrows = maxrows;
    cols = 54;
    for p in 0..(cols * maxrows) { gcells[p] = (char)32; gcol[p] = (char)0; }
    cx = 0;
    cy = 0;
    shown = 0;
    int kd = akind[app];
    if kd == 0 { app_terminal(); }
    else if kd == 1 { app_files(); }
    else if kd == 2 { app_clock(); }
    else if kd == 3 { app_about(); }
    else if kd == 4 { app_launch(app); }
    else if kd == 6 { app_store(); }
    keyboard(0);
    desk_ctx = 0;
    win_app = 0 - 1;
    to_root();
    cols = 0;
    while cols * 10 < scrW { cols += 1; }
}

void desktop() {
    rootW = scrW;
    rootH = scrH;
    win_app = 0 - 1;
    while true {
        keyboard(0);
        desk_draw();
        at_home = 1;
        int r = wait_event();
        at_home = 0;
        if r != 1 {
            if ev_key == 4 { power_off(); }
            continue;
        }
        int app = 0 - 1;
        if tap_y >= rootH - 64 {                                           // the taskbar
            if tap_x < 66 { app = 3; }                                      // the start button: About
            else if tap_x >= 76 && tap_x < 76 + 4 * 60 { app = (tap_x - 76) / 60; }
        } else if tap_x >= 24 && tap_y >= 20 {                              // the icons on the desktop
            int col = (tap_x - 24) / 110;
            int row = (tap_y - 20) / 120;
            int a = col * 4 + row;
            if row < 4 && a < napps { app = a; }
        }
        if app < 0 { continue; }
        if akind[app] == 5 { if power_ask() { power_off(); } continue; }
        open_window(app);
    }
}
