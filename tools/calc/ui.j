// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// ui: the calculator on the screen: what was reckoned above, the line being typed with its result, and keys that are typed or tapped.

i64 sc_rows;
i64 sc_cols;
String ui_line;               // the line being typed
String ui_note;               // the message of an error ("" = none)
String[] ui_expr;             // what was reckoned ...
String[] ui_res;              // ... and what it gave
bool ui_done;                 // = was the last key: an operator goes on from the answer
i64 ui_recall;                // where Up and Down are in the history
bool ui_over;
i64[] key_top;                // the tapped keys of the screen: first and last row, first and last column, the number of the key
i64[] key_bot;
i64[] key_from;
i64[] key_to;
i64[] key_no;
String[] key_label;

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

String key_colour(String k) {
    if k == "=" { return "\x1b[30;48;5;114m"; }
    if k == "C" || k == "DEL" || k == "off" { return "\x1b[97;48;5;124m"; }
    if k.len == 1 && ((k[0] >= '0' && k[0] <= '9') || k == ".") { return "\x1b[97;48;5;240m"; }
    return "\x1b[97;48;5;24m";
}

void draw() {
    read_size();
    frame = "\x1b[?25l";
    at_row = 0;
    key_top = arr(32); key_bot = arr(32); key_from = arr(32); key_to = arr(32); key_no = arr(32);
    i64 w = sc_cols - 1;
    i64 key_rows = 7;
    if sc_rows < 15 { key_rows = 5; }
    i64 tall = 1;
    if sc_rows >= 9 + key_rows * 2 { tall = 2; }
    i64 history = sc_rows - 6 - key_rows * tall;          // the rows above the line
    if history < 1 { history = 1; }
    String title = " calc";
    String how = "Ctrl-Q leaves ";
    put_row("\x1b[1m" + title + "\x1b[0m\x1b[2m" + right_of(how, w - title.len));
    // the history, the newest at the bottom: two rows for each
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
    put_row("\x1b[1m> " + tail_of(ui_line, w - 3) + "_");
    String result = "";
    String bases = "";
    bool have = false;
    if ui_note.len > 0 { result = "\x1b[91m" + right_of(ui_note, w); }
    else {
        if ui_line.len > 0 { have = eval_value(ui_line, false); }
        else if ui_done && ui_res.len > 0 { r_f = ans_f; r_i = ans_i; r_d = ans_d; have = true; }
        if have {
            result = "\x1b[92;1m" + right_of("= " + value_text(), w);
            if !r_f {
                bases = "hex 0x" + to_base(r_i, 16, 64);
                String both = bases + "  bin " + group4(to_base(r_i, 2, 64));
                if both.len <= w { bases = both + ""; }
            }
        }
    }
    put_row(result);
    put_row("\x1b[36m" + right_of(bases, w));
    // the keys
    i64 cw = sc_cols / 4;
    if cw > 12 { cw = 12; }
    for kr in 0..key_rows {
        i64 top = at_row + 1;
        for line in 0..tall {
            String row = "";
            for c in 0..4 {
                String label = key_label[kr * 4 + c] + "";
                String text = "";
                if line == 0 { text = label + ""; }
                i64 inner = cw - 1;
                i64 left = (inner - text.len) / 2;
                row.append(key_colour(label) + spaces(left) + text + spaces(inner - left - text.len) + "\x1b[0m ");
            }
            put_row(row);
        }
        for c in 0..4 {
            key_top.push(top); key_bot.push(at_row);
            key_from.push(c * cw + 1); key_to.push(c * cw + cw - 1);
            key_no.push(kr * 4 + c);
        }
    }
    while at_row < sc_rows { put_row(""); }
    jout << frame;
}

// ---- what the keys do
bool is_operator(String k) { return k == "+" || k == "-" || k == "*" || k == "/" || k == "%" || k == "&" || k == "|" || k == "**" || k == " mod " || k == " xor "; }

void ui_type(String k) {
    ui_note = "";
    if ui_done && ui_line.len == 0 && is_operator(k) && ui_res.len > 0 { ui_line = "ans"; }
    ui_done = false;
    ui_line.append(k);
}

void ui_equals() {
    if ui_line.len == 0 { return; }
    if !eval_value(ui_line, true) { ui_note = err + ""; return; }
    ui_expr.push(ui_line + "");
    ui_res.push(value_text());
    ans_f = r_f; ans_i = r_i; ans_d = r_d;            // what is shown after = (also for  x = 5)
    ui_line = "";
    ui_note = "";
    ui_done = true;
    ui_recall = ui_expr.len;
}

void ui_delete() {
    ui_note = "";
    ui_done = false;
    if ui_line.len > 0 { ui_line = ui_line.slice(0, ui_line.len - 1); }
}

void ui_clear() { ui_line = ""; ui_note = ""; ui_done = false; }

void ui_go(i64 step) {
    if ui_expr.len == 0 { return; }
    i64 n = ui_recall + step;
    if n < 0 { n = 0; }
    if n >= ui_expr.len { ui_recall = ui_expr.len; ui_clear(); return; }
    ui_recall = n;
    ui_line = ui_expr[n] + "";
    ui_note = "";
    ui_done = false;
}

void ui_press(String label) {
    if label == "C" { ui_clear(); }
    else if label == "DEL" { ui_delete(); }
    else if label == "=" { ui_equals(); }
    else if label == "off" { ui_over = true; }
    else if label == "sqrt" { ui_type("sqrt("); }
    else if label == "mod" || label == "xor" { ui_type(" " + label + " "); }
    else { ui_type(label); }
}

void ui_tap(i64 x, i64 y) {
    for i in 0..key_no.len {
        if y >= key_top[i] && y <= key_bot[i] && x >= key_from[i] && x <= key_to[i] { ui_press(key_label[key_no[i]]); return; }
    }
}

// the bytes that arrived together: keys, arrows, taps
void ui_input(char^ b, i64 n) {
    i64 i = 0;
    while i < n {
        i64 c = b[i] & 255;
        if c == 27 {
            if i + 1 >= n || b[i + 1] != '[' { ui_clear(); i += 1; continue; }
            i64 j = i + 2;
            if j < n && b[j] == '<' {                      // a tap: ESC [ < button ; column ; row  M (down) or m (up)
                j += 1;
                i64[] v = arr(4);
                i64 num = 0;
                while j < n && b[j] != 'M' && b[j] != 'm' {
                    if b[j] == ';' { v.push(num); num = 0; }
                    else { num = num * 10 + (b[j] - '0'); }
                    j += 1;
                }
                v.push(num);
                if j < n && b[j] == 'M' && v.len == 3 && v[0] == 0 { ui_tap(v[1], v[2]); }
                i = j + 1;
                continue;
            }
            while j < n && !(b[j] >= '@' && b[j] <= '~') { j += 1; }
            if j < n && b[j] == 'A' { ui_go(0 - 1); }
            else if j < n && b[j] == 'B' { ui_go(1); }
            i = j + 1;
            continue;
        }
        if c == 17 || c == 3 || c == 4 { ui_over = true; }
        else if c == 13 || c == 10 { ui_equals(); }
        else if c == '=' && ui_line.len == 0 && ui_done && ui_expr.len > 0 {          // a second = : it was a comparison (==)
            ui_res.pop();
            ui_line = ui_expr.pop() + "==";
            ui_done = false;
        }
        else if c == '=' && ui_line.len > 0 && !is_name_only(ui_line) && !compare_begun(ui_line) { ui_equals(); }
        else if c == 127 || c == 8 { ui_delete(); }
        else if c == 12 { ui_expr = arr(8); ui_res = arr(8); ui_recall = 0; ui_clear(); }
        else if c >= 32 && c < 127 { String one = ""; one.push((char)c); ui_type(one); }
        i += 1;
    }
}

// the line ends in the first half of  <=  >=  !=  ==
bool compare_begun(String s) { char c = s[s.len - 1]; return c == '<' || c == '>' || c == '!' || c == '='; }

// a line that is only a name (so that  =  after it makes a variable)
bool is_name_only(String s) {
    if s.len == 0 || !is_name_start(s[0]) { return false; }
    for i in 0..s.len { if !is_name_char(s[i]) && s[i] != ' ' { return false; } }
    return true;
}

i64 screen() {
    key_label = "C ( ) DEL 7 8 9 / 4 5 6 * 1 2 3 - 0 . = + sqrt ** mod ans xor & | off".split(" ");
    ui_line = ""; ui_note = ""; ui_expr = arr(8); ui_res = arr(8); ui_done = false; ui_recall = 0; ui_over = false;
    raw_mode(true);
    jout << "\x1b[?1049h\x1b[?1000h\x1b[?1006h\x1b[2J";
    while !ui_over {
        draw();
        char b[128];
        i64 n = Sys::read(0, @b, 128);
        if n <= 0 { break; }
        ui_input(@b, n);
    }
    jout << "\x1b[?1006l\x1b[?1000l\x1b[0m\x1b[?25h\x1b[?1049l";
    raw_mode(false);
    return 0;
}
