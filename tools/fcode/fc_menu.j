// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: the menu actions and the screen (a part of fcode.jk, imported in the order of the old file)

// an action of a menu: the ones that are keys (Ctrl-S ...) are done as that key
void menu_do(String act) {
    if act == "compile" { build_run(false); return; }
    if act == "run" || act == "buildrun" { build_run(true); return; }
    if act == "nexterror" { if err_line.len > 0 { err_i = (err_i + 1) % err_line.len; } show_error(); return; }
    if act == "examples" { examples_menu(); return; }
    if act == "keys" { pane_text("Keys", "F10 menu   F9 compile   F5 run   F11 compile and run   F8 next error   Esc closes the log\nCtrl-S save  Ctrl-Q quit  Ctrl-F find  Ctrl-G go to line  Ctrl-Z undo  Ctrl-Y redo\nCtrl-C copy  Ctrl-X cut  Ctrl-V paste  Ctrl-A select all  Ctrl-K delete line  Ctrl-E commands"); return; }
    if act == "about" { pane_text("About", "fcode 0.6.0: a text editor for the terminal and the Jaric app.  J2k-studio  github.com/J2k-studio/ex-pkg"); return; }
    if act == "replace" {
        String a1 = ask("replace: ");
        if a1.len == 0 { return; }
        String a2 = ask("with: ");
        begin_edit(0);
        i64 n = 0;
        for y in 0..lines.len {
            String l = lines[y];
            String nl = l.replace(a1, a2);
            if nl != l { lines[y] = nl; n += 1; dirty = true; }
        }
        msg = "replaced in " + str(n) + " lines";
        return;
    }
    String kn = binding_key_of(act);                       // "Ctrl-S"
    if kn.len == 6 && kn.starts_with("Ctrl-") { handle_key((kn[5] & 255) - 64); return; }
    msg = act + ": no key for it";
}

// the keys while a menu is open
void menu_key(i64 k) {
    if k == K_ESC || k == K_F + 10 { menu_on = 0 - 1; return; }
    if k == K_LEFT { menu_on = (menu_on + 4) % 5; menu_item = 0; return; }
    if k == K_RIGHT { menu_on = (menu_on + 1) % 5; menu_item = 0; return; }
    String[] items = menu_list(menu_on);
    if k == K_DOWN { menu_item = (menu_item + 1) % items.len; return; }
    if k == K_UP { menu_item = (menu_item + items.len - 1) % items.len; return; }
    if k == K_ENTER {
        String act = menu_action(items[menu_item]);
        menu_on = 0 - 1;
        menu_do(act);
        return;
    }
    if k == K_MOUSE { menu_click(); }
}

// a touch while a menu is open (or on the bar): choose
void menu_click() {
    if !m_press { return; }
    String[] n = menu_names();
    if m_y == 1 {
        for i in 0..5 { if m_x >= menu_x(i) - 1 && m_x <= menu_x(i) + n[i].len + 1 { if menu_on == i { menu_on = 0 - 1; } else { menu_on = i; menu_item = 0; } return; } }
        menu_on = 0 - 1;
        return;
    }
    if menu_on >= 0 {
        String[] items = menu_list(menu_on);
        i64 i = m_y - 2;
        if i >= 0 && i < items.len {
            String act = menu_action(items[i]);
            menu_on = 0 - 1;
            menu_do(act);
            return;
        }
    }
    menu_on = 0 - 1;
}

void fkey(i64 n) {
    if n == 5 { build_run(true); }
    else if n == 9 { build_run(false); }
    else if n == 11 { build_run(true); }
    else if n == 8 { if err_line.len > 0 { err_i = (err_i + 1) % err_line.len; } show_error(); }
    else if n == 10 { if menubar { menu_on = 0; menu_item = 0; } else { msg = "set menubar on  (or  set colorscheme devcpp)"; } }
    else if n == 1 { menu_do("keys"); }
}

void draw() {
    scroll_to_cursor();
    String e = esc();
    String f = e + "[?25l";
    i64 off = row_off();
    for r in 0..text_rows_count() {
        i64 y = top + r;
        f = f + e + "[" + str(r + 1 + off) + ";1H";
        if y < lines.len { f = f + draw_line(y); }
        else { f = f + bgs() + rgb(c_gut) + "~" + e + "[0m" + bgs() + e + "[K"; }
    }
    if pane_on { f = f + draw_pane(off + text_rows_count() + 1); }
    if helpbar {                                                  // the keys, in the way of nano: the key reversed, then what it does
        // only the hints that fit the width: a line longer than the screen wraps and scrolls the text away (on a phone nothing typed was seen)
        String hints = "";
        i64 used = 0;
        String acts = "save:Save quit:Quit find:Find goto:Goto undo:Undo copy:Copy cut:Cut paste:Paste command:Command";
        if menubar { acts = "F10:Menu F9:Compile F5:Run F11:Build+Run " + acts; }
        String[] as = acts.split(" ");
        for i in 0..as.len {
            String[] an = as[i].split(":");
            String keyname = an[0] + "";
            if !menubar || keyname[0] != 'F' { keyname = binding_key_of(an[0]); }
            i64 wide = keyname.len + 1 + an[1].len + 2;
            if keyname.len > 0 && used + wide <= cols {
                hints = hints + e + "[7m" + keyname + e + "[0m " + an[1] + "  ";
                used += wide;
            }
        }
        f = f + e + "[" + str(rows - 1) + ";1H" + hints + e + "[K";
    }
    String name = path;
    if dirty { name = name + " *"; }
    String right = "  " + str(cy + 1) + ":" + str(col_of(lines[cy], cx) + 1) + " ";
    String left_text = " " + name + "  " + msg;
    i64 room = cols - right.len;
    if left_text.len > room { left_text = left_text.slice(0, room); }
    String bar = left_text + " ".repeat(room - left_text.len) + right;
    f = f + e + "[" + str(rows) + ";1H" + e + "[7m" + bar + e + "[0m";
    i64 g = gutter();
    i64 sr = cy - top + 1 + off;
    i64 sc = col_of(lines[cy], cx) - left + g + 1;
    if pop_on { f = f + draw_popup(sr, sc); }
    if menubar { f = f + draw_menubar(); }
    f = f + e + "[" + str(sr) + ";" + str(sc) + "H" + e + "[?25h";
    jout << f;
}
