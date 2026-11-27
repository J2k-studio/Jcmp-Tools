// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: colour schemes and the settings folder (a part of fcode.jk, imported in the order of the old file)

// ---------------------------------------------------------------- the colours of J2K
bool is_word(i64 c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_'; }
bool in_list(String list, String w) {
    String[] ws = list.split(" ");
    for i in 0..ws.len { if ws[i] == w { return true; } }
    return false;
}
// kinds: 0 text, 1 keyword, 2 text in quotes, 3 number, 4 comment, 5 type
i64[] kinds_of(String s) {
    i64[] k = arr(s.len + 1);
    for i in 0..s.len { k.push(0); }
    i64 i = 0;
    while i < s.len {
        i64 c = s[i] & 255;
        if c == '/' && i + 1 < s.len && s[i + 1] == '/' {
            for j in i..s.len { k[j] = 4; }
            return k;
        }
        if c == '"' || c == 39 {
            i64 j = i + 1;
            while j < s.len && (s[j] & 255) != c {
                if s[j] == '\\' { j += 1; }
                j += 1;
            }
            if j >= s.len { j = s.len - 1; }
            for q in i..j + 1 { k[q] = 2; }
            i = j + 1;
        } else if c >= '0' && c <= '9' {
            i64 j = i;
            while j < s.len && (is_word(s[j] & 255) || s[j] == '.') { k[j] = 3; j += 1; }
            i = j;
        } else if is_word(c) {
            i64 j = i;
            while j < s.len && is_word(s[j] & 255) { j += 1; }
            String w = s.slice(i, j);
            i64 kind = 0;
            if in_list("if else while for in return break continue switch case default struct enum using module import defer try catch throw new delete true false null sizeof asm reg export operator naked loop", w) { kind = 1; }
            else if in_list("int uint double float bool char void String u8 u16 u32 u64 i8 i16 i32 i64 Result Option Error", w) { kind = 5; }
            if kind != 0 { for q in i..j { k[q] = kind; } }
            i = j;
        } else {
            i += 1;
        }
    }
    return k;
}
String rgb(i64 c) {
    return esc() + "[38;2;" + str((c >> 16) & 255) + ";" + str((c >> 8) & 255) + ";" + str(c & 255) + "m";
}
String bgs() { return esc() + "[48;2;" + str((c_bg >> 16) & 255) + ";" + str((c_bg >> 8) & 255) + ";" + str(c_bg & 255) + "m"; }
String color_of(i64 kind) {
    if kind == 1 { return rgb(c_kw); }
    if kind == 2 { return rgb(c_str); }
    if kind == 3 { return rgb(c_num); }
    if kind == 4 { return rgb(c_com); }
    if kind == 5 { return rgb(c_typ); }
    return rgb(c_txt);
}
// the colours of a scheme: dark (the default), light, mono, amber; a file ~/.config/fcode/colors/NAME with lines  keyword = #RRGGBB  changes or adds one
void apply_scheme(String name) {
    scheme = name;
    c_kw = 0xFF7B72; c_str = 0xA5D6FF; c_num = 0xD2A8FF; c_com = 0x7D8590; c_typ = 0x79C0FF; c_txt = 0xF2F2F2; c_gut = 0x7D8590; c_sel = 0x3C4666; c_bg = 0x0D1117;
    if name == "light" { c_kw = 0xCF222E; c_str = 0x0A3069; c_num = 0x8250DF; c_com = 0x6E7781; c_typ = 0x0550AE; c_txt = 0x1F2328; c_gut = 0x8C959F; c_sel = 0xB6D6F2; c_bg = 0xFAFAFA; }
    else if name == "mono" { c_kw = 0xFFFFFF; c_str = 0xCCCCCC; c_num = 0xCCCCCC; c_com = 0x808080; c_typ = 0xFFFFFF; c_txt = 0xE0E0E0; c_gut = 0x808080; c_sel = 0x444444; c_bg = 0x000000; }
    else if name == "amber" { c_kw = 0xFFB000; c_str = 0xFFD060; c_num = 0xFFD060; c_com = 0x9A6B00; c_typ = 0xFFC030; c_txt = 0xFFB000; c_gut = 0x9A6B00; c_sel = 0x553A00; c_bg = 0x120C00; }
    if name == "devcpp" { c_kw = 0x000080; c_str = 0x800080; c_num = 0xCC0000; c_com = 0x008000; c_typ = 0x000080; c_txt = 0x000000; c_gut = 0x808080; c_sel = 0xC0C0FF; c_bg = 0xFFFFFF; menubar = true; }
    String file = config_dir() + "/colors/" + name;
    Result<String, Error> r = Fs::read_text(file);
    if r.is_ok() {
        String[] ls = r.take().split("\n");
        for i in 0..ls.len {
            String[] kv = ls[i].split("=");
            if kv.len != 2 { continue; }
            String key = kv[0].trim();
            String val = kv[1].trim();
            if val.len != 7 || val[0] != '#' { continue; }
            i64 v = hex_value(val.slice(1, 7));
            if key == "keyword" { c_kw = v; } else if key == "string" { c_str = v; } else if key == "number" { c_num = v; }
            else if key == "comment" { c_com = v; } else if key == "type" { c_typ = v; } else if key == "text" { c_txt = v; }
            else if key == "background" { c_bg = v; } else if key == "gutter" { c_gut = v; } else if key == "selection" { c_sel = v; }
        }
    }
}
i64 hex_value(String h) {
    i64 v = 0;
    for i in 0..h.len {
        i64 c = h[i] & 255;
        i64 d = 0;
        if c >= '0' && c <= '9' { d = c - '0'; }
        else if c >= 'a' && c <= 'f' { d = c - 'a' + 10; }
        else if c >= 'A' && c <= 'F' { d = c - 'A' + 10; }
        v = v * 16 + d;
    }
    return v;
}
String config_dir() {
    Option<String> h = Env::get("HOME");
    String home = "";
    if h.is_some() { home = h.unwrap(); }
    String now = home + "/.config/fcode";
    String before = home + "/.config/coderin";                      // the folder of the old name is used when there is no new one
    if !Dir::exists(now) && Dir::exists(before) { return before; }
    return now;
}
