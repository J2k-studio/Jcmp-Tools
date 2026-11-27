// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: drawing the text, the menu bar, the panes (a part of fcode.jk, imported in the order of the old file)

// ---------------------------------------------------------------- drawing
i64 gutter() {
    if !ruler { return 0; }
    String nstr = str(lines.len);
    return nstr.len + 2;
}

String[] pane;                // the log of the compiler / the output of the program, under the text (Esc closes it)
String pane_title;
bool pane_on;
i64 pane_rows() {
    if !pane_on { return 0; }
    i64 n = pane.len;
    if n > 8 { n = 8; }
    return n + 1;
}
i64 row_off() { if menubar { return 1; } return 0; }

i64 text_rows_count() {
    i64 t = rows - 1 - row_off() - pane_rows();
    if helpbar { t -= 1; }
    if t < 3 { t = 3; }
    return t;
}

void scroll_to_cursor() {
    if free_scroll { return; }
    i64 g = gutter();
    i64 text_rows = text_rows_count();
    if cy < top { top = cy; }
    if cy >= top + text_rows { top = cy - text_rows + 1; }
    i64 cc = col_of(lines[cy], cx);
    i64 text_cols = cols - g;
    if cc < left { left = cc; }
    if cc >= left + text_cols { left = cc - text_cols + 1; }
}

String draw_line(i64 y) {
    String s = lines[y];
    i64[] k = kinds_of(s);
    String e = esc();
    String out = bgs();
    i64 g = gutter();
    if ruler {
        String num = str(y + 1);
        String pad = " ".repeat(g - 1 - num.len);
        if has_err(y) { out = out + rgb(0xFF5F5F) + pad + num + "!" + e + "[0m" + bgs(); }
        else { out = out + rgb(c_gut) + pad + num + " " + e + "[0m" + bgs(); }
    }
    i64 col = 0;
    i64 i = 0;
    i64 last = 0 - 1;
    bool rev = false;
    i64 text_cols = cols - g;
    while i < s.len {
        i64 n = next_char(s, i);
        i64 c = s[i] & 255;
        i64 w = 1;
        if c == 9 { w = (col / tabsize + 1) * tabsize - col; }
        else if zero_width(s, i) { w = 0; }
        bool s_on = selected(y, i);
        if col + w > left && col < left + text_cols {
            if k[i] != last || s_on != rev {
                out = out + e + "[0m" + bgs();
                if s_on { out = out + e + "[48;2;" + str((c_sel >> 16) & 255) + ";" + str((c_sel >> 8) & 255) + ";" + str(c_sel & 255) + "m"; }
                out = out + color_of(k[i]);
                last = k[i];
                rev = s_on;
            }
            if c == 9 { out = out + " ".repeat(w); }
            else { out = out + s.slice(i, n); }
        }
        col += w;
        i = n;
    }
    out = out + e + "[0m" + bgs() + e + "[K";
    return out;
}

String ask(String prompt) {
    String e = esc();
    String text = "";
    while true {
        String line = prompt + text;
        jout << e << "[" << str(rows) << ";1H" << e << "[7m" << line << " ".repeat(cols - line.len) << e << "[0m" << e << "[" << str(rows) << ";" << str(line.len + 1) << "H";
        i64 k = read_key(0 - 1);
        if k == K_ENTER { return text; }
        if k == K_ESC { return ""; }
        if k == K_BS { if text.len > 0 { text = text.slice(0, prev_char(text, text.len)); } }
        else if k == K_TEXT { text = text + key_text; }
    }
    return text;
}

// ---------------------------------------------------------------- the menu bar of the old programs (F10): File Edit Search Run Help
i64 menu_on;                          // the open menu, -1 none (set at the start)
i64 room(i64 n) { if n < 0 { return 0; } return n; }
i64 menu_item;
String[] menu_names() { String[] n = arr(5); n.push("File"); n.push("Edit"); n.push("Search"); n.push("Run"); n.push("Help"); return n; }
// "label|action" of the items of a menu
String[] menu_list(i64 m) {
    String[] r = arr(8);
    if m == 0 { r.push("Save|save"); r.push("Examples...|examples"); r.push("Quit|quit"); }
    else if m == 1 { r.push("Undo|undo"); r.push("Redo|redo"); r.push("Cut|cut"); r.push("Copy|copy"); r.push("Paste|paste"); r.push("Select all|selectall"); r.push("Delete line|deleteline"); }
    else if m == 2 { r.push("Find...|find"); r.push("Replace...|replace"); r.push("Go to line...|goto"); }
    else if m == 3 { r.push("Compile  F9|compile"); r.push("Run  F5|run"); r.push("Compile and run  F11|buildrun"); r.push("Next error  F8|nexterror"); }
    else { r.push("Keys  F1|keys"); r.push("About|about"); }
    return r;
}
String menu_label(String item) { i64 bar = 0 - 1; for i in 0..item.len { if item[i] == '|' { bar = i; } } return item.slice(0, bar); }
String menu_action(String item) { i64 bar = 0 - 1; for i in 0..item.len { if item[i] == '|' { bar = i; } } return item.slice(bar + 1, item.len); }
i64 menu_x(i64 m) {                    // the column (1-based) where the name of menu m starts
    String[] n = menu_names();
    i64 x = 2;
    for i in 0..m { x += n[i].len + 3; }
    return x;
}

String draw_menubar() {
    String e = esc();
    String[] n = menu_names();
    String f = e + "[1;1H" + e + "[48;2;192;192;192m" + e + "[38;2;0;0;0m";
    String line = " ";
    for i in 0..n.len { line = line + " " + n[i] + "  "; }
    f = f + line + " ".repeat(room(cols - line.len)) + e + "[0m";
    if menu_on >= 0 {
        String[] items = menu_list(menu_on);
        i64 w = 0;
        for i in 0..items.len { String lb = menu_label(items[i]); if lb.len > w { w = lb.len; } }
        w += 2;
        i64 x = menu_x(menu_on) - 1;
        if x + w > cols { x = cols - w; }
        if x < 1 { x = 1; }
        // the open name is lit
        f = f + e + "[1;" + str(menu_x(menu_on)) + "H" + e + "[48;2;0;0;128m" + e + "[38;2;255;255;255m" + " " + n[menu_on] + " " + e + "[0m";
        for i in 0..items.len {
            String lb = " " + menu_label(items[i]);
            String t = lb + " ".repeat(w - lb.len);
            if i == menu_item { f = f + e + "[" + str(i + 2) + ";" + str(x) + "H" + e + "[48;2;0;0;128m" + e + "[38;2;255;255;255m" + t + e + "[0m"; }
            else { f = f + e + "[" + str(i + 2) + ";" + str(x) + "H" + e + "[48;2;192;192;192m" + e + "[38;2;0;0;0m" + t + e + "[0m"; }
        }
    }
    return f;
}

// the log under the text: a title bar, then the last lines (a line with an error is red)
String draw_pane(i64 row) {
    String e = esc();
    i64 n = pane.len;
    i64 show = n;
    if show > 8 { show = 8; }
    i64 first = n - show;
    String t = " " + pane_title + "     Esc closes";
    String f = e + "[" + str(row) + ";1H" + e + "[48;2;0;0;128m" + e + "[38;2;255;255;255m" + t + " ".repeat(room(cols - t.len)) + e + "[0m";
    for i in 0..show {
        String l = pane[first + i];
        if l.len > cols - 2 { l = l.slice(0, cols - 2); }
        String code = e + "[48;2;192;192;192m" + e + "[38;2;0;0;0m";
        if l.contains(": error") || l.contains("error:") { code = e + "[48;2;192;192;192m" + e + "[38;2;170;0;0m"; }
        f = f + e + "[" + str(row + 1 + i) + ";1H" + code + " " + l + " ".repeat(room(cols - l.len - 1)) + e + "[0m";
    }
    return f;
}
