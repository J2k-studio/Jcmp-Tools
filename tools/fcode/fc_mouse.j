// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: the mouse (a part of fcode.jk, imported in the order of the old file)

// ---------------------------------------------------------------- the mouse
void mouse_pos(i64^ yy, i64^ xx) {
    i64 y = top + m_y - 1 - row_off();
    if y >= lines.len { y = lines.len - 1; }
    if y < 0 { y = 0; }
    i64 col = m_x - 1 - gutter() + left;
    if col < 0 { col = 0; }
    yy[0] = y;
    xx[0] = byte_at_col(lines[y], col);
}

void on_mouse() {
    if !mouse_on { return; }
    if m_btn >= 64 {                                              // the wheel scrolls (the cursor stays)
        if m_btn == 64 { top -= 3; } else { top += 3; }
        if top < 0 { top = 0; }
        if top > lines.len - 1 { top = lines.len - 1; }
        free_scroll = true;
        return;
    }
    if m_y > text_rows_count() + row_off() || m_y <= row_off() { return; }      // the bar, the log, the lines of keys and of status
    i64 y = 0;
    i64 x = 0;
    mouse_pos(@y, @x);
    if m_btn == 0 && m_press {
        i64 now = Time::now_ms();
        if now - click_time < 400 && y == click_y && x == click_x {   // a double click takes the word
            String l = lines[y];
            i64 a = x;
            i64 b = x;
            while a > 0 && is_word(l[a - 1] & 255) { a -= 1; }
            while b < l.len && is_word(l[b] & 255) { b += 1; }
            if b > a { sel = true; ay = y; ax = a; cy = y; cx = b; }
        } else {
            move_to(y, x, false);
        }
        click_time = now;
        click_y = y;
        click_x = x;
    } else if m_btn == 32 && m_press {                           // a drag with the button held selects from the place of the click
        if !sel { sel = true; ay = click_y; ax = click_x; }
        cy = y;
        cx = x;
    }
}

// ( ) [ ] { } " ' : typing the first one closes it; typing the closing one when it is the next character only steps over it.
// Returns true when the key was taken here.
bool type_pair(i64 c) {
    String line = lines[cy];
    i64 next = 0;
    if cx < line.len { next = line[cx] & 255; }
    i64 prev = 0;
    if cx > 0 { prev = line[cx - 1] & 255; }
    if !sel && (c == ')' || c == ']' || c == '}' || c == '"' || c == 39) && next == c {
        cx += 1;
        return true;
    }
    String closer = "";
    if c == '(' { closer = ")"; }
    else if c == '[' { closer = "]"; }
    else if c == '{' { closer = "}"; }
    else if (c == '"' || c == 39) && !is_word(prev) && !is_word(next) {
        closer = "";
        closer.push((char)c);
    }
    if closer.len == 0 { return false; }
    if sel { return false; }
    String open = "";
    open.push((char)c);
    insert_text(open + closer);
    cx -= 1;
    return true;
}
