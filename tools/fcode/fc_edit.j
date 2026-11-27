// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: selection, clipboard, undo and redo (a part of fcode.jk, imported in the order of the old file)

// ---------------------------------------------------------------- selection and clipboard
void order_sel(i64^ y1, i64^ x1, i64^ y2, i64^ x2) {
    bool swap = ay < cy || (ay == cy && ax < cx);
    if swap { y1[0] = ay; x1[0] = ax; y2[0] = cy; x2[0] = cx; }
    else { y1[0] = cy; x1[0] = cx; y2[0] = ay; x2[0] = ax; }
}
bool selected(i64 y, i64 x) {
    if !sel { return false; }
    i64 y1 = 0; i64 x1 = 0; i64 y2 = 0; i64 x2 = 0;
    order_sel(@y1, @x1, @y2, @x2);
    if y < y1 || y > y2 { return false; }
    if y == y1 && x < x1 { return false; }
    if y == y2 && x >= x2 { return false; }
    return true;
}
String selected_text() {
    i64 y1 = 0; i64 x1 = 0; i64 y2 = 0; i64 x2 = 0;
    order_sel(@y1, @x1, @y2, @x2);
    if y1 == y2 { return lines[y1].slice(x1, x2); }
    String t = lines[y1].slice(x1, lines[y1].len);
    for y in y1 + 1..y2 { t = t + "\n" + lines[y]; }
    t = t + "\n" + lines[y2].slice(0, x2);
    return t;
}
void delete_selection() {
    i64 y1 = 0; i64 x1 = 0; i64 y2 = 0; i64 x2 = 0;
    order_sel(@y1, @x1, @y2, @x2);
    String head = lines[y1].slice(0, x1);
    String tail = lines[y2].slice(x2, lines[y2].len);
    for k in 0..y2 - y1 { remove_line(y1 + 1); }
    lines[y1] = head + tail;
    cy = y1;
    cx = x1;
    sel = false;
    dirty = true;
}
// the text also goes to the clipboard of the terminal (OSC 52) when the terminal knows it
void set_clip(String t) {
    clip = t;
    jout << esc() << "]52;c;" << Base64::encode(t) << (char)7;
}
// ---------------------------------------------------------------- the extension undo / redo
String join_lines() {
    String t = "";
    for i in 0..lines.len {
        if i > 0 { t = t + "\n"; }
        t = t + lines[i];
    }
    return t;
}
void set_from_text(String t) {
    lines = arr(64);
    String[] p = t.split("\n");
    for i in 0..p.len { lines.push(p[i]); }
    if lines.len == 0 { lines.push(""); }
}
// called before a change: the state is kept so that Ctrl-Z can come back to it (typing in one go, or deleting in one go, is one step)
void begin_edit(i64 kind) {
    if !ext_undo { return; }
    i64 now = Time::now_ms();
    if kind != 0 && kind == last_kind && now - last_edit_ms < 900 { last_edit_ms = now; return; }
    undo_text.push(join_lines());
    undo_cy.push(cy);
    undo_cx.push(cx);
    if undo_text.len > 200 {                                      // only the last 200 steps
        String[] t2 = arr(256);
        i64[] y2 = arr(256);
        i64[] x2 = arr(256);
        for i in 1..undo_text.len { t2.push(undo_text[i]); y2.push(undo_cy[i]); x2.push(undo_cx[i]); }
        undo_text = t2; undo_cy = y2; undo_cx = x2;
    }
    redo_text = arr(8);
    redo_cy = arr(8);
    redo_cx = arr(8);
    last_kind = kind;
    last_edit_ms = now;
}
void undo_step(bool redo) {
    if !ext_undo { msg = "the extension undo is off (set extensions undo j2k)"; return; }
    if redo {
        if redo_text.len == 0 { msg = "nothing to redo"; return; }
        undo_text.push(join_lines()); undo_cy.push(cy); undo_cx.push(cx);
        i64 n = redo_text.len - 1;
        set_from_text(redo_text[n]);
        cy = redo_cy[n]; cx = redo_cx[n];
        redo_text.pop(); redo_cy.pop(); redo_cx.pop();
        msg = "redo";
    } else {
        if undo_text.len == 0 { msg = "nothing to undo"; return; }
        redo_text.push(join_lines()); redo_cy.push(cy); redo_cx.push(cx);
        i64 n = undo_text.len - 1;
        set_from_text(undo_text[n]);
        cy = undo_cy[n]; cx = undo_cx[n];
        undo_text.pop(); undo_cy.pop(); undo_cx.pop();
        msg = "undo";
    }
    if cy >= lines.len { cy = lines.len - 1; }
    if cx > lines[cy].len { cx = lines[cy].len; }
    sel = false;
    dirty = true;
    last_kind = 0;
}
