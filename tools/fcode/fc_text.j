// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: characters, columns, the lines of the text, errors of the compiler (a part of fcode.jk, imported in the order of the old file)

// ---------------------------------------------------------------- characters and columns
bool is_cont(String s, i64 i) { return i >= 0 && i < s.len && (s[i] & 192) == 128; }
i64 prev_char(String s, i64 at) {
    if at <= 0 { return 0; }
    at -= 1;
    while at > 0 && is_cont(s, at) { at -= 1; }
    return at;
}
i64 next_char(String s, i64 at) {
    if at >= s.len { return s.len; }
    at += 1;
    while at < s.len && is_cont(s, at) { at += 1; }
    return at;
}
// a Thai vowel above or below a letter, or a tone mark, takes no column of its own
bool zero_width(String s, i64 i) {
    if i + 2 >= s.len + 0 { if i + 2 > s.len - 1 { return false; } }
    i64 b0 = s[i] & 255;
    i64 b1 = s[i + 1] & 255;
    i64 b2 = s[i + 2] & 255;
    if b0 != 224 { return false; }
    if b1 == 184 { return b2 == 177 || (b2 >= 180 && b2 <= 186); }
    if b1 == 185 { return b2 >= 135 && b2 <= 142; }
    return false;
}
// the column on the screen of the byte at upto (a tab goes to the next multiple of 4)
i64 col_of(String s, i64 upto) {
    i64 col = 0;
    i64 i = 0;
    while i < upto && i < s.len {
        i64 c = s[i] & 255;
        if c == 9 { col = (col / tabsize + 1) * tabsize; }
        else if !is_cont(s, i) && !zero_width(s, i) { col += 1; }
        i += 1;
    }
    return col;
}
// the byte of the line that is at the column (the nearest character start)
i64 byte_at_col(String s, i64 want) {
    i64 i = 0;
    while i < s.len {
        i64 n = next_char(s, i);
        if col_of(s, n) > want { return i; }
        i = n;
    }
    return s.len;
}

// ---------------------------------------------------------------- the text
void insert_line(i64 at, String s) {
    String[] n = arr(lines.len + 16);
    for i in 0..lines.len {
        if i == at { n.push(s); }
        n.push(lines[i]);
    }
    if at >= lines.len { n.push(s); }
    lines = n;
}
void remove_line(i64 at) {
    String[] n = arr(lines.len + 16);
    for i in 0..lines.len { if i != at { n.push(lines[i]); } }
    if n.len == 0 { n.push(""); }
    lines = n;
}

void load(String p) {
    lines = arr(64);
    Result<String, Error> r = Fs::read_text(p);
    String text = "";
    if r.is_ok() { text = r.take(); msg = "opened " + p; }
    else { msg = "new file " + p; }
    if text.len > 0 {
        String[] parts = text.split("\n");
        i64 n = parts.len;
        if n > 0 && parts[n - 1].len == 0 { n -= 1; }
        for i in 0..n {
            String l = parts[i];
            if l.len > 0 && l[l.len - 1] == 13 { l = l.slice(0, l.len - 1); }
            lines.push(l);
        }
    }
    if lines.len == 0 { lines.push(""); }
}

// ---------------------------------------------------------------- the extension j2k: the errors of the compiler (jcmp on the PATH)
i64[] err_line;
String[] err_msg;
i64 err_i;
bool has_err(i64 y) {
    for i in 0..err_line.len { if err_line[i] == y { return true; } }
    return false;
}
// runs the compiler on the saved file; the lines with an error get a red number, the first one is shown (next: the others)
void check_code() {
    err_line = arr(8);
    err_msg = arr(8);
    err_i = 0;
    if !(path.ends_with(".jk") || path.ends_with(".j")) { return; }
    String out = path + ".chk";
    String[] args = arr(4);
    args.push("-c");
    args.push("jcmp '" + path + "' -o '" + out + "' 2>&1");
    Result<String, Error> r = Proc::output("sh", args);
    Fs::remove(out);
    if !r.is_ok() { return; }
    String[] ls = r.take().split("\n");
    for i in 0..ls.len {
        String l = ls[i];
        i64 at = 0;
        bool found = false;
        while at + 9 <= l.len && !found { if l.slice(at, at + 9) == ": error: " { found = true; } else { at += 1; } }
        if !found { continue; }
        String[] parts = l.slice(0, at).split(":");
        if parts.len < 3 { continue; }
        i64 ln = parts[parts.len - 2].to_int();
        if ln < 1 { continue; }
        err_line.push(ln - 1);
        err_msg.push(l.slice(at + 9, l.len) + "");
    }
    if err_line.len == 0 { msg = msg + "  no errors"; return; }
    show_error();
}
void show_error() {
    if err_line.len == 0 { msg = "no errors (save to check)"; return; }
    i64 y = err_line[err_i];
    if y >= lines.len { y = lines.len - 1; }
    move_to(y, 0, false);
    msg = "error " + str(err_i + 1) + "/" + str(err_line.len) + " line " + str(y + 1) + ": " + err_msg[err_i];
}

void save() {
    String text = "";
    for i in 0..lines.len { text = text + lines[i] + "\n"; }
    Result<i64, Error> r = Fs::write_text(path, text);
    if r.is_ok() { dirty = false; msg = "saved " + path + " (" + str(lines.len) + " lines)"; if ext_j2k { check_code(); } }
    else { msg = "cannot save " + path; }
}
