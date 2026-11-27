// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: the terminal: raw mode, the size, reading keys (a part of fcode.jk, imported in the order of the old file)

// ---------------------------------------------------------------- the terminal
void raw_mode(bool on) {
    char t[64];
    Sys::call(29, 0, 21505, (i64)@t, 0, 0, 0);                    // TCGETS
    if on {
        t[0] = t[0] & 0xFA;                                       // iflag: no ICRNL (0x100 is in byte 1), no IXON (0x400 in byte 1)
        t[1] = t[1] & 0xFA;                                       // 0x100 and 0x400 -> bits 0 and 2 of byte 1
        t[12] = t[12] & 0xF4;                                     // lflag: no ISIG (1), no ICANON (2), no ECHO (8)
        t[23] = 1;                                                // VMIN
        t[22] = 0;                                                // VTIME
    } else {
        t[1] = t[1] | 5;
        t[12] = t[12] | 11;
    }
    Sys::call(29, 0, 21506, (i64)@t, 0, 0, 0);                    // TCSETS
}

void read_size() {
    char w[8];
    for i in 0..8 { w[i] = 0; }
    Sys::call(29, 1, 21523, (i64)@w, 0, 0, 0);                    // TIOCGWINSZ
    rows = (w[0] & 255) | ((w[1] & 255) << 8);
    cols = (w[2] & 255) | ((w[3] & 255) << 8);
    if rows < 5 { rows = 24; }
    if cols < 20 { cols = 80; }
}

i64 rd() {
    char b[4];
    i64 n = Sys::read(0, @b, 1);
    if n <= 0 { return 0 - 1; }
    return b[0] & 255;
}

// one key: a code from the list above, a control letter (1 .. 26), or K_TEXT with the characters in key_text; -2 when nothing came in ms
i64 read_key(i64 ms) {
    if !Input::ready(ms) { return 0 - 2; }
    i64 c = rd();
    if c < 0 { return 0 - 1; }
    if c == 27 {
        if !Input::ready(30) { return K_ESC; }
        i64 c2 = rd();
        if c2 == 79 {                                             // ESC O H / F
            i64 c3 = rd();
            if c3 == 72 { return K_HOME; }
            if c3 == 70 { return K_END; }
            if c3 >= 80 && c3 <= 83 { return K_F + 1 + (c3 - 80); }                // ESC O P Q R S : F1 .. F4
            return K_ESC;
        }
        if c2 != 91 { return K_ESC; }
        i64 p1 = 0;
        i64 p2 = 0;
        i64 p3 = 0;
        i64 field = 1;
        i64 last = rd();
        bool sgr = false;
        while (last >= 48 && last <= 59) || last == 63 || last == 60 {
            if last == 60 { sgr = true; }
            else if last == 59 { field += 1; }
            else if field == 1 { p1 = p1 * 10 + (last - 48); }
            else if field == 2 { p2 = p2 * 10 + (last - 48); }
            else { p3 = p3 * 10 + (last - 48); }
            last = rd();
        }
        if sgr && (last == 77 || last == 109) {                   // the mouse (SGR): ESC [ < button ; x ; y M (press) or m (release)
            m_btn = p1;
            m_x = p2;
            m_y = p3;
            m_press = last == 77;
            return K_MOUSE;
        }
        i64 mod = 0;
        if p2 == 2 { mod = K_SHIFT; }
        else if p2 == 5 { mod = K_CTRL; }
        if last == 65 { return K_UP + mod; }
        if last == 66 { return K_DOWN + mod; }
        if last == 67 { return K_RIGHT + mod; }
        if last == 68 { return K_LEFT + mod; }
        if last == 72 { return K_HOME + mod; }
        if last == 70 { return K_END + mod; }
        if last == 126 {
            if p1 == 1 || p1 == 7 { return K_HOME + mod; }
            if p1 == 4 || p1 == 8 { return K_END + mod; }
            if p1 == 3 { return K_DEL; }
            if p1 == 5 { return K_PGUP; }
            if p1 == 6 { return K_PGDN; }
            if p1 >= 15 && p1 <= 24 {                                       // ESC [ 15 ~ ... : F5 .. F12
                if p1 == 15 { return K_F + 5; }
                if p1 == 17 { return K_F + 6; }
                if p1 == 18 { return K_F + 7; }
                if p1 == 19 { return K_F + 8; }
                if p1 == 20 { return K_F + 9; }
                if p1 == 21 { return K_F + 10; }
                if p1 == 23 { return K_F + 11; }
                if p1 == 24 { return K_F + 12; }
            }
        }
        return K_ESC;
    }
    if c == 13 || c == 10 { return K_ENTER; }
    if c == 127 || c == 8 { return K_BS; }
    if c == 9 { return K_TAB; }
    if c < 32 { return c; }
    key_text = "";
    key_text.push((char)c);
    if c >= 192 {                                                 // the bytes that follow in a character of UTF-8
        i64 more = 1;
        if c >= 224 { more = 2; }
        if c >= 240 { more = 3; }
        for i in 0..more {
            i64 cb = rd();
            if cb >= 0 { key_text.push((char)cb); }
        }
    }
    return K_TEXT;
}
