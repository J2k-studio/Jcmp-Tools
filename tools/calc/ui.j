// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// ui: the calculator on the screen, typed on the keyboard: what was reckoned above, the line being typed, and its result in every form.

i64 sc_rows;
i64 sc_cols;
String ui_line;               // the line being typed
i64 ui_at;                    // the cursor in it
String ui_note;               // the message of an error ("" = none)
String[] ui_expr;             // what was reckoned ...
String[] ui_res;              // ... and what it gave
bool ui_done;                 // Enter was the last thing: an operator goes on from the answer
i64 ui_recall;                // where Up and Down are in the history
bool ui_over;
bool ui_help;                 // the help is shown

void raw_mode(bool on) {
    char t[64];
    Sys::call(29, 0, 21505, (i64)@t, 0, 0, 0);                    // TCGETS
    if on {
        t[0] = t[0] & 0xFA;
        t[1] = t[1] & 0xFA;
        t[12] = t[12] & 0xF4;                                     // no ISIG, no ICANON, no ECHO
        t[23] = 1;
        t[22] = 0;
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
    sc_rows = (w[0] & 255) | ((w[1] & 255) << 8);
    sc_cols = (w[2] & 255) | ((w[3] & 255) << 8);
    if sc_rows < 8 { sc_rows = 24; }
    if sc_cols < 20 { sc_cols = 80; }
}

String spaces(i64 n) { String s = ""; for i in 0..n { s.push(' '); } return s; }

// at most w letters, the end of the text kept
String tail_of(String s, i64 w) { if s.len <= w { return s + ""; } return "~" + s.slice(s.len - w + 1, s.len); }

String right_of(String s, i64 w) { String t = tail_of(s, w); return spaces(w - t.len) + t; }

// the value of the last parse as a text
String value_text() { if r_f { return fmt_double(r_d); } return stg(r_i); }

// ---- drawing: every row of the screen is written anew
String frame;
i64 at_row;

void put_row(String text) {
    at_row += 1;
    if at_row > sc_rows { return; }
    frame.append("\x1b[" + stg(at_row) + ";1H\x1b[0m");
    frame.append(text);
    frame.append("\x1b[0m\x1b[K");
}

String[] ui_forms;             // the rows of the result in its forms

// a form of the result, cut into rows of the width of the screen
void add_form(String name, String value, i64 w) {
    i64 room = w - 7;
    i64 from = 0;
    String head = "  " + name + " ";
    while from < value.len {
        i64 to = from + room;
        if to > value.len { to = value.len; }
        ui_forms.push(head + value.slice(from, to));
        head = "      ";
        from = to;
    }
}

// the result in every form: dec, hex, bin, oct for a whole number, and the form of science
void forms(i64 w) {
    String sci = "";
    if r_f { sci = fmt_sci(r_d); add_form("sci", sci, w); return; }
    String dec = stg(r_i);
    add_form("dec", dec, w);
    String hex = "0x" + to_base(r_i, 16, 64);
    add_form("hex", hex, w);
    String bin = group4(to_base(r_i, 2, 64));
    add_form("bin", bin, w);
    String oct = "0o" + to_base(r_i, 8, 64);
    add_form("oct", oct, w);
    sci = fmt_sci((double)r_i);
    add_form("sci", sci, w);
    if r_i >= 33 && r_i < 127 { String ch = "'"; ch.push((char)r_i); ch.push('\''); add_form("chr", ch, w); }
}

void draw_help(i64 w) {
    String[] h = help_lines();
    put_row("\x1b[1m calc: help");
    for i in 0..h.len { if at_row < sc_rows - 1 { put_row(" " + tail_of(h[i], w - 1)); } }
    while at_row < sc_rows - 1 { put_row(""); }
    put_row("\x1b[2m any key goes back");
}

void draw() {
    read_size();
    frame = "\x1b[?25l";
    at_row = 0;
    i64 w = sc_cols - 1;
    if ui_help {
        draw_help(w);
        jout << frame;
        return;
    }
    // the result of the line first: it says how many rows are left for the history
    String result = "";
    ui_forms = arr(16);
    bool have = false;
    if ui_note.len > 0 { result = "\x1b[91m" + right_of(ui_note, w); }
    else {
        if ui_line.len > 0 { have = eval_value(ui_line, false); }
        else if ui_done && ui_res.len > 0 { r_f = ans_f; r_i = ans_i; r_d = ans_d; have = true; }
        if have {
            String v = "= " + value_text();
            result = "\x1b[92;1m" + right_of(v, w);
            forms(w);
        }
    }
    i64 most = sc_rows - 5;                      // title, rule, line, result and one row of history stay
    i64 shown = ui_forms.len;
    if shown > most { shown = most; }
    i64 history = sc_rows - 4 - shown;
    String title = " calc [";
    if degrees_mode { title.append("deg]"); } else { title.append("rad]"); }
    String how = "help  Ctrl-Q ";
    if w < 28 { how = "help "; }
    put_row("\x1b[1m" + title + "\x1b[0m\x1b[2m" + right_of(how, w - title.len));
    i64 pairs = history / 2;
    i64 first = ui_expr.len - pairs;
    if first < 0 { first = 0; }
    i64 used = (ui_expr.len - first) * 2;
    for i in 0..history - used { put_row(""); }
    for i in first..ui_expr.len {
        put_row("\x1b[2m " + tail_of(ui_expr[i], w - 1));
        put_row(right_of("= " + ui_res[i], w));
    }
    String rule = "";
    for i in 0..w { rule.push('-'); }
    put_row("\x1b[2m" + rule);
    // the line: the part round the cursor
    i64 room = w - 3;
    i64 from = 0;
    if ui_at > room { from = ui_at - room; }
    i64 to = from + room;
    if to > ui_line.len { to = ui_line.len; }
    put_row("\x1b[1m> " + ui_line.slice(from, to));
    i64 line_row = at_row;
    put_row(result);
    for i in 0..shown { put_row("\x1b[36m" + ui_forms[i]); }
    while at_row < sc_rows { put_row(""); }
    frame.append("\x1b[" + stg(line_row) + ";" + stg(3 + ui_at - from) + "H\x1b[?25h");
    jout << frame;
}

// ---- what the keys do
bool is_operator(char c) { return c == '+' || c == '-' || c == '*' || c == '/' || c == '%' || c == '&' || c == '|' || c == '<' || c == '>'; }

void ui_type(char c) {
    ui_note = "";
    if ui_done && ui_line.len == 0 && is_operator(c) && ui_res.len > 0 { ui_line = "ans"; ui_at = 3; }
    ui_done = false;
    String left = ui_line.slice(0, ui_at);
    left.push(c);
    left.append(ui_line.slice(ui_at, ui_line.len));
    ui_line = left;
    ui_at += 1;
}

void ui_set(String line) { ui_line = line + ""; ui_at = ui_line.len; ui_note = ""; ui_done = false; }

void ui_clear() { ui_set(""); }

// the character before the cursor (back) or under it
void ui_delete(bool back) {
    ui_note = "";
    ui_done = false;
    i64 p = ui_at;
    if back { p -= 1; }
    if p < 0 || p >= ui_line.len { return; }
    String left = ui_line.slice(0, p);
    left.append(ui_line.slice(p + 1, ui_line.len));
    ui_line = left;
    ui_at = p;
}

void ui_enter() {
    String t = ui_line.trim();
    if t.len == 0 { return; }
    if t == "help" || t == "?" { ui_help = true; ui_clear(); return; }
    if t == "quit" || t == "exit" || t == "q" { ui_over = true; return; }
    if t == "deg" { degrees_mode = true; ui_clear(); return; }
    if t == "rad" { degrees_mode = false; ui_clear(); return; }
    if t == "clear" { ui_expr = arr(8); ui_res = arr(8); ui_recall = 0; ui_clear(); return; }
    if !eval_value(ui_line, true) { ui_note = err + ""; return; }
    ui_expr.push(ui_line + "");
    ui_res.push(value_text());
    ans_f = r_f; ans_i = r_i; ans_d = r_d;            // what is shown after Enter (also for  x = 5)
    ui_clear();
    ui_done = true;
    ui_recall = ui_expr.len;
}

void ui_go(i64 step) {
    if ui_expr.len == 0 { return; }
    i64 n = ui_recall + step;
    if n < 0 { n = 0; }
    if n >= ui_expr.len { ui_recall = ui_expr.len; ui_clear(); return; }
    ui_recall = n;
    ui_set(ui_expr[n]);
}

// the bytes that arrived together: letters, arrows and the other keys
void ui_input(char^ b, i64 n) {
    if ui_help { ui_help = false; return; }
    i64 i = 0;
    while i < n {
        i64 c = b[i] & 255;
        if c == 27 {
            if i + 1 >= n || (b[i + 1] != '[' && b[i + 1] != 'O') { ui_clear(); i += 1; continue; }
            if b[i + 1] == 'O' && i + 2 < n && b[i + 2] == 'P' { ui_help = true; i += 3; continue; }       // F1
            i64 j = i + 2;
            i64 num = 0;
            while j < n && !(b[j] >= '@' && b[j] <= '~') { if b[j] >= '0' && b[j] <= '9' { num = num * 10 + (b[j] - '0'); } j += 1; }
            if j < n {
                char k = b[j];
                if k == 'A' { ui_go(0 - 1); }
                else if k == 'B' { ui_go(1); }
                else if k == 'C' { if ui_at < ui_line.len { ui_at += 1; } }
                else if k == 'D' { if ui_at > 0 { ui_at -= 1; } }
                else if k == 'H' { ui_at = 0; }
                else if k == 'F' { ui_at = ui_line.len; }
                else if k == '~' && num == 3 { ui_delete(false); }
                else if k == '~' && (num == 1 || num == 7) { ui_at = 0; }
                else if k == '~' && (num == 4 || num == 8) { ui_at = ui_line.len; }
            }
            i = j + 1;
            continue;
        }
        if c == 17 || c == 3 || c == 4 { ui_over = true; }
        else if c == 13 || c == 10 { ui_enter(); }
        else if c == 127 || c == 8 { ui_delete(true); }
        else if c == 1 { ui_at = 0; }
        else if c == 5 { ui_at = ui_line.len; }
        else if c == 21 { ui_clear(); }
        else if c == 12 { ui_expr = arr(8); ui_res = arr(8); ui_recall = 0; ui_clear(); }
        else if c >= 32 && c < 127 { ui_type((char)c); }
        if ui_help || ui_over { return; }
        i += 1;
    }
}

i64 screen() {
    ui_line = ""; ui_at = 0; ui_note = ""; ui_expr = arr(8); ui_res = arr(8); ui_done = false; ui_recall = 0; ui_over = false; ui_help = false;
    raw_mode(true);
    jout << "\x1b[?1049h\x1b[2J";
    while !ui_over {
        draw();
        char b[128];
        i64 n = Sys::read(0, @b, 128);
        if n <= 0 { break; }
        ui_input(@b, n);
    }
    jout << "\x1b[0m\x1b[?25h\x1b[?1049l";
    raw_mode(false);
    return 0;
}
