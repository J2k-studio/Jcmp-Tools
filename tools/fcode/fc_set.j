// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: settings, key bindings, the command bar (a part of fcode.jk, imported in the order of the old file)

// ---------------------------------------------------------------- settings, key bindings, the command bar
String letter_of(i64 k) {
    String l = "";
    l.push((char)(k + 96));
    return l;
}

void bind_default() {
    bind_keys = arr(16);
    bind_acts = arr(16);
    String pairs = "Ctrl-s=save Ctrl-q=quit Ctrl-f=find Ctrl-g=goto Ctrl-c=copy Ctrl-x=cut Ctrl-v=paste Ctrl-a=selectall Ctrl-d=duplicate Ctrl-k=deleteline Ctrl-e=command Ctrl-z=undo Ctrl-y=redo";
    String[] ps = pairs.split(" ");
    for i in 0..ps.len {
        String[] kv = ps[i].split("=");
        bind_keys.push(kv[0]);
        bind_acts.push(kv[1]);
    }
}
// the key of an action, as ^S (the last binding of the action)
String binding_key_of(String act) {
    i64 i = bind_keys.len - 1;
    while i >= 0 {
        if bind_acts[i] == act && bind_keys[i].starts_with("Ctrl-") && bind_keys[i].len == 6 {
            String k = "^";
            k.push((char)(bind_keys[i][5] - 32));
            return k;
        }
        i -= 1;
    }
    return "";
}
// the action of a key; the last binding of a key counts (the file of the user comes after the defaults)
String binding(String key) {
    i64 i = bind_keys.len - 1;
    while i >= 0 {
        if bind_keys[i] == key { return bind_acts[i] + ""; }              // a copy (jcmp 1.0.0.0 gives away the String of the array itself: fixed after it)
        i -= 1;
    }
    return "";
}
bool on_off(String v) { return v == "on" || v == "true" || v == "yes" || v == "1"; }

void set_option(String name, String val) {
    if name == "tabsize" { i64 n = val.to_int(); if n >= 1 && n <= 16 { tabsize = n; } }
    else if name == "tabstospaces" { use_spaces = on_off(val); }
    else if name == "ruler" { ruler = on_off(val); }
    else if name == "autoindent" { autoindent = on_off(val); }
    else if name == "autopair" { autopair = on_off(val); }
    else if name == "helpbar" { helpbar = on_off(val); }
    else if name == "extensions" { ext_undo = false; ext_j2k = false; String[] ex = val.split(" "); for i in 0..ex.len { if ex[i] == "undo" { ext_undo = true; } if ex[i] == "j2k" { ext_j2k = true; } } }
    else if name == "mouse" {
        mouse_on = on_off(val);
        String e = esc();
        if mouse_on { jout << e << "[?1000h" << e << "[?1002h" << e << "[?1006h"; } else { jout << e << "[?1006l" << e << "[?1002l" << e << "[?1000l"; }
    }
    else if name == "colorscheme" { apply_scheme(val); }
    else { msg = "unknown setting " + name; }
}

// the settings that the Jaric app keeps for all its programs (jaric settings): ~/.config/jaric/settings, lines  name = value ; "" when there is none
String jaric_setting(String name) {
    Option<String> h = Env::get("HOME");
    String home = "";
    if h.is_some() { home = h.unwrap(); }
    Result<String, Error> r = Fs::read_text(home + "/.config/jaric/settings");
    if !r.is_ok() { return ""; }
    String[] ls = r.take().split("\n");
    for i in 0..ls.len {
        String l = ls[i].trim();
        if l.len == 0 || l[0] == '#' { continue; }
        String[] kv = l.split("=");
        if kv.len != 2 { continue; }
        String key = kv[0].trim();
        if key == name { return kv[1].trim() + ""; }
    }
    return "";
}

// the look of the editor when its own settings do not say: what jaric settings says; in the Jaric app the look of Dev-C++; elsewhere dark
void choose_default_scheme() {
    String js = jaric_setting("fcode");
    if js.len == 0 { js = jaric_setting("coderin"); }                 // the setting of the old name
    if js.len > 0 { apply_scheme(js); return; }
    String jv = "";
    Option<String> j = Env::get("JARIC");
    if j.is_some() { jv = j.unwrap(); }
    if jv.len > 0 { apply_scheme("devcpp"); }
}

void load_settings() {
    Result<String, Error> r = Fs::read_text(config_dir() + "/settings");
    if !r.is_ok() { return; }
    String[] ls = r.take().split("\n");
    for i in 0..ls.len {
        String l = ls[i].trim();
        if l.len == 0 || l[0] == '#' { continue; }
        String[] kv = l.split("=");
        if kv.len == 2 { set_option(kv[0].trim(), kv[1].trim()); }
    }
}
void load_bindings() {
    Result<String, Error> r = Fs::read_text(config_dir() + "/bindings");
    if !r.is_ok() { return; }
    String[] ls = r.take().split("\n");
    for i in 0..ls.len {
        String l = ls[i].trim();
        if l.len == 0 || l[0] == '#' { continue; }
        String[] kv = l.split("=");
        if kv.len == 2 { bind_keys.push(kv[0].trim()); bind_acts.push(kv[1].trim()); }
    }
}
// the command  set NAME VALUE  is kept in the file settings (this is the only time fcode writes in ~/.config/fcode)
void save_setting(String name, String val) {
    Dir::make_all(config_dir());
    String file = config_dir() + "/settings";
    String out = "";
    bool done = false;
    Result<String, Error> r = Fs::read_text(file);
    if r.is_ok() {
        String[] ls = r.take().split("\n");
        for i in 0..ls.len {
            if ls[i].len == 0 { continue; }
            String[] kv = ls[i].split("=");
            bool same = false;
            if kv.len == 2 {
                String key = kv[0].trim();
                same = key == name;
            }
            if same { out = out + name + " = " + val + "\n"; done = true; }
            else { out = out + ls[i] + "\n"; }
        }
    }
    if !done { out = out + name + " = " + val + "\n"; }
    Fs::write_text(file, out);
}

void command_bar() {
    String c = ask("> ").trim();
    if c.len == 0 { return; }
    String[] w = c.split(" ");
    String cmd = w[0];
    if cmd == "save" { save(); }
    else if cmd == "quit" { if any_dirty() { msg = "unsaved changes: use Ctrl-Q twice, or  q!"; } else { quit_asked = 2; } }
    else if cmd == "q!" { quit_asked = 2; }
    else if cmd == "goto" && w.len > 1 { i64 n = w[1].to_int(); if n < 1 { n = 1; } if n > lines.len { n = lines.len; } move_to(n - 1, 0, false); }
    else if cmd == "find" && w.len > 1 { find_next(c.slice(5, c.len), cy, cx + 1); }
    else if cmd == "replace" && w.len == 3 {
        begin_edit(0);
        i64 n = 0;
        for y in 0..lines.len {
            String l = lines[y];
            String nl = l.replace(w[1], w[2]);
            if nl != l { lines[y] = nl; n += 1; dirty = true; }
        }
        msg = "replaced in " + str(n) + " lines";
    }
    else if cmd == "set" && w.len == 3 { set_option(w[1], w[2]); save_setting(w[1], w[2]); if msg.len == 0 { msg = w[1] + " = " + w[2]; } }
    else if cmd == "bind" && w.len == 3 { bind_keys.push(w[1]); bind_acts.push(w[2]); msg = w[1] + " does " + w[2] + " (put it in ~/.config/fcode/bindings to keep it)"; }
    else if cmd == "check" { check_code(); if err_line.len == 0 { msg = "no errors"; } }
    else if cmd == "next" { if err_line.len > 0 { err_i = (err_i + 1) % err_line.len; } show_error(); }
    else if cmd == "run" && w.len > 1 { run_ext_command(w[1]); }
    else if cmd == "extensions" { msg = "loaded: "; for i in 0..xs_loaded.len { msg = msg + xs_loaded[i] + " "; } if xs_loaded.len == 0 { msg = "none in ~/.config/fcode/extensions/"; } }
    else if cmd == "help" { msg = "check next (errors of the compiler) run NAME (extension command) extensions save quit goto N find TEXT replace A B set NAME VALUE bind Ctrl-x ACTION; settings: tabsize tabstospaces ruler autoindent autopair helpbar mouse colorscheme"; }
    else { msg = "unknown command: " + cmd + " (help)"; }
}
