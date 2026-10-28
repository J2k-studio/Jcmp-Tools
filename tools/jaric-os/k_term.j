// the terminal app, power off and the phone loop (a part of kernel.jk: the files are put together with #import in this order, the globals come before they are used)
// ---- the terminal app: the console of before, on the screen under the bar; the back button (or a tap at the bottom edge) goes home
void term_redraw() {
    wallpaper();
    draw_bar(0x6c616e696d726554, 0);
    int bgc = rgb(8, 10, 20);
    fill(0, 76, scrW, scrH - 76, bgc);
    for r in 0..vrows {
        for c in 0..cols {
            int ch = gcells[r * cols + c] & 255;
            if ch > 32 && ch < 127 { draw_cell(c, r, ch, 0, gcol[r * cols + c]); }
        }
    }
    gdirty = 1;
    shown = 0;
}

void app_terminal() {
    scr = 1;
    term_redraw();
    keyboard(1);
    gohome = 0;
    while true {
        prompt();
        bool got = read_line();
        if gohome == 1 || !got { break; }
        if !run_command() { break; }
    }
    if shown == 1 { draw_cell(cx, cy, gcells[cy * cols + cx] & 255, 0, gcol[cy * cols + cx]); shown = 0; }
    keyboard(0);
}

void power_off() {
    scr = 0;
    setcol(0);
    say(0x657962); putc(10);
    char^ stop = (char^)0x09100000;
    stop[0] = 0;
    while true { }
}

// the phone: the home screen until a tap on an icon opens an app
void phone() {
    p32 = (u32^)0x41000000;
    build_apps();
    if scrW > scrH { desktop(); }                              // a screen that is wider than high: the desktop
    while true {
        keyboard(0);
        draw_home();
        int r = wait_event();
        if r != 1 {
            if ev_key == 4 { power_off(); }                  // the end of the input (Ctrl-D): the machine is turned off
            continue;
        }
        int app = 0 - 1;
        if tap_y < 44 && tap_x > 300 { control_panel(); continue; }              // a tap on the status line: the control panel
        if tap_y >= scrH - 230 && tap_y < scrH - 70 && tap_x >= 50 {
            int d = (tap_x - 50) / 118;
            if d >= 0 && d < 4 && (tap_x - 50) % 118 < 88 { app = d; }
        } else if tap_y >= 390 && tap_y < scrH - 240 {
            int row = (tap_y - 390) / 160;
            int col = tap_x / 135;
            int a = 4 + row * 4 + col;
            if a < napps { app = a; }
        }
        if app < 0 { continue; }
        int kd = akind[app];
        if kd == 0 { app_terminal(); }
        else if kd == 1 { app_files(); }
        else if kd == 2 { app_clock(); }
        else if kd == 3 { app_about(); }
        else if kd == 4 { app_launch(app); }
        else if kd == 5 { if power_ask() { power_off(); } }
        else if kd == 6 { app_store(); }
    }
}

