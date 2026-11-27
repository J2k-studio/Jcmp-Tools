// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: the list of words under the cursor (a part of fcode.jk, imported in the order of the old file)

// ---------------------------------------------------------------- the list of words under the cursor (like VS Code): Down / Up choose, Tab or Enter take, Esc closes
void update_popup() {
    pop_on = false;
    if !ext_j2k && xs_loaded.len == 0 { return; }
    String l = lines[cy];
    i64 st = cx;
    while st > 0 && is_word(l[st - 1] & 255) { st -= 1; }
    if cx - st < 2 || sel { return; }
    if cx < l.len && is_word(l[cx] & 255) { return; }
    String w = l.slice(st, cx);
    String[] all = word_cands(w);
    if all.len == 0 { return; }
    all.sort();
    pop_c = arr(8);
    for i in 0..all.len { if i < 7 { pop_c.push(all[i] + ""); } }
    pop_i = 0;
    pop_st = st;
    pop_on = true;
}
void accept_popup() {
    String l = lines[cy];
    begin_edit(0);
    lines[cy] = l.slice(0, pop_st) + pop_c[pop_i] + l.slice(cx, l.len);
    cx = pop_st + pop_c[pop_i].len;
    dirty = true;
    pop_on = false;
}
String draw_popup(i64 sr, i64 sc) {
    String e = esc();
    String f = "";
    i64 n = pop_c.len;
    i64 w = 0;
    for i in 0..n { if pop_c[i].len > w { w = pop_c[i].len; } }
    w += 2;
    i64 col = sc - (cx - pop_st);
    if col + w > cols { col = cols - w; }
    if col < 1 { col = 1; }
    i64 row = sr + 1;
    if row + n > text_rows_count() { row = sr - n; }
    if row < 1 { return ""; }
    for i in 0..n {
        String t = " " + pop_c[i] + " ".repeat(w - 1 - pop_c[i].len);
        if i == pop_i { f = f + e + "[" + str(row + i) + ";" + str(col) + "H" + e + "[48;2;60;70;102m" + e + "[38;2;255;255;255m" + t + e + "[0m"; }
        else { f = f + e + "[" + str(row + i) + ";" + str(col) + "H" + e + "[48;2;31;41;55m" + e + "[38;2;201;209;217m" + t + e + "[0m"; }
    }
    return f;
}
