// ---- the control panel: a card from the top (swipe down from the top edge, or a tap on the status line): switches that work, and what the machine is (the OS, the CPU and its bits, the memory, the screen, the disk).
// What is under it is kept and put back when the panel is closed. A part of kernel.jk: put together with #import after the desktop.
int kb_on;                             // the keyboard of the phone: asked for by the switch of the panel
int panel_open;

void panel_line(int px, int y, int w0, int w1, int v, int w2) {
    t8(px + 24, y, w0, 1, rgb(150, 175, 215));
    t8(px + 24 + 80, y, w1, 1, rgb(150, 175, 215));
    if v >= 0 { num(px + 240, y, v, 1, rgb(235, 242, 255)); t8(px + 240 + digits(v) * 10 + 10, y, w2, 1, rgb(235, 242, 255)); }
    else { t8(px + 240, y, w2, 1, rgb(235, 242, 255)); }
}

void control_panel() {
    if panel_open == 1 || sready == 0 { return; }
    panel_open = 1;
    int pw = 500;
    int px = (scrW - pw) / 2;
    int ph = 580;
    if ph > scrH - 60 { ph = scrH - 60; }
    // what is under the card is kept
    int^ pic = (int^)sfb;
    int^ keep = (int^)0x42500000;
    int words = scrW * ph / 2;
    for i in 0..words { keep[i] = pic[i]; }
    rrect(px - 3, 0 - 3, pw + 6, ph + 3, 30, rgb(60, 78, 130));
    rrect(px, 0 - 3, pw, ph, 28, rgb(22, 30, 58));
    t8(px + 24 + 0, 22, 0x6c6f72746e6f43, 2, rgb(255, 255, 255));
    // the switches
    int ky = 84;
    rrect(px + 24, ky, 140, 92, 22, rgb(40, 54, 98));
    if kb_on == 1 { rrect(px + 24, ky, 140, 92, 22, rgb(70, 150, 255)); }
    t8(px + 24 + 16 + 0, ky + 16, 0x6472616f6279654b, 1, rgb(255, 255, 255));
    if kb_on == 1 { t8(px + 24 + 16 + 0, ky + 52, 0x6e6f, 1, rgb(255, 255, 255)); } else { t8(px + 24 + 16 + 0, ky + 52, 0x66666f, 1, rgb(150, 175, 215)); }
    rrect(px + 180, ky, 140, 92, 22, rgb(40, 54, 98));
    t8(px + 180 + 16 + 0, ky + 16, 0x7265776f50, 1, rgb(255, 255, 255));
    t8(px + 180 + 16 + 0, ky + 52, 0x66666f206e727574, 1, rgb(150, 175, 215));
    rrect(px + 336, ky, 140, 92, 22, rgb(40, 54, 98));
    t8(px + 336 + 16 + 0, ky + 16, 0x65736f6c43, 1, rgb(255, 255, 255));
    t8(px + 336 + 16 + 0, ky + 52, 0x7261632073696874, 1, rgb(150, 175, 215)); t8(px + 336 + 16 + 80, ky + 52, 0x64, 1, rgb(150, 175, 215));
    // what the machine is
    rrect(px + 24, 200, pw - 48, 360, 22, rgb(32, 44, 82));
    int ly = 218;
    panel_line(px, ly, 0x534f, 0, 0 - 1, 0x534f20636972614a );
    panel_line(px, ly + 36, 0x555043, 0, 0 - 1, 0x34364d5241 );
    panel_line(px, ly + 72, 0x73746942, 0, 64, 0);
    panel_line(px, ly + 108, 0x6c6576654c, 0, g_el, 0x302065726f63 );
    int used = (scrW * scrH * 4) / 1048576;
    panel_line(px, ly + 144, 0x79726f6d654d, 0, g_ram, 0x6c61746f7420424d );
    panel_line(px, ly + 180, 0x65727574636950, 0, used, 0x424d );
    panel_line(px, ly + 216, 0x6874646957, 0, scrW, 0x73746f64 );
    panel_line(px, ly + 252, 0x746867696548, 0, scrH, 0x73746f64 );
    panel_line(px, ly + 288, 0x6b736944, 0, g_dsec / 2, 0x424b );
    present();
    bool again = true;
    while again {
        int r = wait_event();
        if r != 1 { continue; }
        again = false;
        if tap_y < ph && tap_x >= px && tap_x < px + pw {
            if tap_y >= ky && tap_y < ky + 92 {
                if tap_x >= px + 24 && tap_x < px + 164 {                            // the keyboard switch
                    if kb_on == 1 { kb_on = 0; } else { kb_on = 1; }
                    keyboard(kb_on);
                    again = true;
                    rrect(px + 24, ky, 140, 92, 22, rgb(40, 54, 98));
                    if kb_on == 1 { rrect(px + 24, ky, 140, 92, 22, rgb(70, 150, 255)); }
                    t8(px + 24 + 16 + 0, ky + 16, 0x6472616f6279654b, 1, rgb(255, 255, 255));
                    if kb_on == 1 { t8(px + 24 + 16 + 0, ky + 52, 0x6e6f, 1, rgb(255, 255, 255)); } else { t8(px + 24 + 16 + 0, ky + 52, 0x66666f, 1, rgb(150, 175, 215)); }
                    present();
                } else if tap_x >= px + 180 && tap_x < px + 320 {                    // power: asks
                    for i in 0..words { pic[i] = keep[i]; }
                    panel_open = 0;
                    if power_ask() { power_off(); }
                    return;
                } else if tap_x >= px + 336 && tap_x < px + 476 { again = false; }
            } else { again = true; }                                                 // a tap on the card: nothing
        }
    }
    for i in 0..words { pic[i] = keep[i]; }                                         // the card goes, what was under it comes back
    present();
    panel_open = 0;
}
