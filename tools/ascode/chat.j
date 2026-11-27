// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// chat: the session of ascode: a first time (the key is asked and saved), then one line after the other, with the talk remembered, and the
// commands that start with /. Every line fits a screen of 40 columns.

// the key file: for the person only
bool cl_save_key(String key) {
    String dir = Env::get("HOME").or(".") + "/.config";
    Sys::mkdir(dir.c(), 448);
    dir.append("/ascode");
    Sys::mkdir(dir.c(), 448);
    String f = dir + "/key";
    Result<i64, Error> w = Fs::write_text(f, key + "\n");
    if w.is_err() { return false; }
    Sys::chmod(f.c(), 384);
    return true;
}

// asks for the key and keeps it; false when none was given
bool ask_key() {
    jout << "Paste your Claude API key, then Enter\n(it is not shown; an empty line leaves): ";
    String k = read_text_line(true);
    String t = k.trim();
    jout << nl;
    if t.len == 0 { return false; }
    cl_key = t + "";
    if cl_save_key(t) { jout << "saved in ~/.config/ascode/key\n"; }
    else { jout << "ascode: the key could not be saved\n"; }
    return true;
}

void chat_banner() {
    String folder = g_root + "";
    if folder.len > 28 { folder = "..." + folder.slice(folder.len - 25, folder.len); }
    jout << "\n+------------------------------+\n";
    jout << "| ascode " << ascode_version() << "                 |\n";
    jout << "+------------------------------+\n";
    jout << " model   " << cl_model << nl;
    jout << " mode    " << g_mode << nl;
    jout << " folder  " << folder << nl;
    jout << " /help commands   /exit leave\n";
}

void chat_help() {
    jout << "/model [NAME]  see or change model\n";
    jout << "/mode ask|read|auto\n";
    jout << "     ask: a change needs a y\n";
    jout << "     read: changes are refused\n";
    jout << "     auto: changes in the folder\n";
    jout << "/key           a new API key\n";
    jout << "/clear         a new talk\n";
    jout << "/exit          leave\n";
}

void chat_command(String line) {
    String[] w = line.split(" ");
    String c = w[0] + "";
    String v = "";
    if w.len > 1 { v = w[w.len - 1] + ""; }
    if c == "/help" { chat_help(); return; }
    if c == "/clear" { cl_messages = arr(8); jout << "a new talk\n"; return; }
    if c == "/key" { ask_key(); return; }
    if c == "/mode" {
        if v == "ask" || v == "read" || v == "auto" { g_mode = v + ""; }
        else if v.len > 0 { jout << "the mode is ask, read or auto\n"; }
        jout << "mode: " << g_mode << nl;
        return;
    }
    if c == "/model" {
        if v.len == 0 {
            jout << "now: " << cl_model << nl;
            jout << "  claude-opus-5-5   (default)\n  claude-sonnet-5-5\n  claude-haiku-5-5\n";
            jout << "use: /model NAME\n";
            return;
        }
        cl_model = v + "";
        cl_messages = arr(8);                    // the thoughts of one model are not given to another
        jout << "model " << cl_model << " (a new talk)\n";
        return;
    }
    jout << "no command " << c << " (see /help)\n";
}

i64 chat(String id) {
    if !cl_open(id) {
        jout << "ascode: no API key yet.\nMake one at console.anthropic.com\n";
        if !ask_key() { return 1; }
    }
    chat_banner();
    while true {
        jout << "\n> ";
        String line = read_text_line(false);
        if g_eof && line.len == 0 { break; }
        String t = line.trim();
        if t.len == 0 { continue; }
        if t == "/exit" || t == "/quit" || t == "exit" { break; }
        if t.starts_with("/") { chat_command(t); continue; }
        i64 before = cl_messages.len;
        if cl_run(t) != 0 {                      // a talk that failed is forgotten, so that the next one is whole
            while cl_messages.len > before { cl_messages.pop(); }
        }
    }
    jout << nl;
    return 0;
}
