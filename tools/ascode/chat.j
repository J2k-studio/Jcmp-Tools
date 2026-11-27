// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// chat: the session of ascode: the first time (who answers, the key, the model), then one line after the other, with the talk remembered, and
// the commands that start with /. Every line fits a screen of 40 columns.

// the number a text is, -1 when it is not one (to_int would stop the program)
i64 number_of(String s) {
    if s.len == 0 || s.len > 9 { return -1; }
    i64 n = 0;
    for i in 0..s.len { if s[i] < '0' || s[i] > '9' { return -1; } n = n * 10 + (s[i] - '0'); }
    return n;
}

// a line of the person, trimmed
String ask_line(String question) {
    jout << question;
    String l = read_text_line(false);
    String t = l.trim();
    return t;
}

// what was pasted without the marks a terminal may put round it, without spaces and control letters
String clean_key(String raw) {
    String s = raw.replace("\x1b[200~", "");
    String s2 = s.replace("\x1b[201~", "");
    String out = "";
    for i in 0..s2.len { char c = s2[i]; if c > 32 && c < 127 { out.push(c); } }
    return out;
}

// asks for the key of the provider and keeps it; false when none was given (a provider that works without one: an empty line is fine)
bool ask_key() {
    bool needed = provider_needs_key(cfg_provider);
    String place = provider_key_place(cfg_provider);
    if cfg_provider == "claude" { jout << "Paste your Claude API key (it\nstarts with sk-ant-), then Enter.\n"; }
    else { jout << "Paste your " << cfg_provider << " API key,\nthen Enter.\n"; }
    if place.len > 0 { jout << "make one: " << place << nl; }
    if needed { jout << "It shows as stars.  q leaves.\n"; }
    else { jout << "Enter alone: no key.  q leaves.\n"; }
    i64 empty = 0;
    while true {
        jout << "key: ";
        String raw = read_text_line(true);
        String t = clean_key(raw);
        jout << nl;
        if t == "q" || (g_eof && t.len == 0) { return false; }
        if t.len == 0 {
            if !needed { cl_key = ""; return true; }
            empty += 1;                                     // an Enter by mistake does not leave at once
            if empty >= 3 { return false; }
            jout << "nothing came. Use the Paste key,\nthen Enter  (q leaves)\n";
            continue;
        }
        cl_key = t + "";
        if save_key_of(cfg_provider, t) { String f = key_file(cfg_provider); jout << "saved in ~/.config/ascode/" << Path::name(f) << nl; }
        else { jout << "ascode: the key could not be saved\n"; }
        if cfg_provider == "claude" && !t.starts_with("sk-") { jout << "note: a Claude key starts with\nsk-ant- ; /key changes it\n"; }
        return true;
    }
    return false;
}

// the names of the models the provider offers (empty when they cannot be asked)
String[] fetch_models() {
    String[] out = arr(32);
    i64 status = 0;
    String url = base_url() + "/models";
    String headers = oa_headers();
    if provider_anthropic(cfg_provider) { headers = cl_headers(); url = url + "?limit=100"; }
    String body = api_send("GET", url, headers, "", @status);
    if body.len == 0 { return out; }
    Result<JsonDoc, Error> pr = Json::parse(body);
    if pr.is_err() { jerr << "ascode: the list of models is not JSON (HTTP " << status << ")\n"; return out; }
    JsonDoc d = pr.take();
    if status != 200 { api_failed(status, api_error_text(@d)); return out; }
    i64 data = d.get(0, "data");
    if data < 0 { return out; }
    for i in 0..d.len(data) {
        i64 m = d.at(data, i);
        String id = cl_str(@d, m, "id");
        if id.len > 0 { out.push(id); }
    }
    out.sort();
    return out;
}

// those that hold the word
String[] matching(String[] all, String word) {
    String[] out = arr(32);
    for i in 0..all.len { if word.len == 0 || all[i].contains(word) { out.push(all[i] + ""); } }
    return out;
}

void show_models(String[] list) {
    i64 n = list.len;
    if n > 15 { n = 15; }
    for i in 0..n { jout << " " << i + 1 << " " << list[i] << nl; }
    if list.len > n { jout << " ... " << list.len - n << " more: type a word\n"; }
}

// the person chooses a model from the list of the provider (or types its name); false when they leave
bool pick_model() {
    String[] all = fetch_models();
    String[] now = matching(all, "");
    if all.len == 0 { jout << "no list of models.\n"; } else { show_models(now); }
    while true {
        String t = ask_line("model (number, name, or a word;\nq leaves): ");
        if t == "q" || (g_eof && t.len == 0) { return false; }
        if t.len == 0 { continue; }
        i64 num = number_of(t);
        if num >= 1 && num <= now.len && num <= 15 && t.len <= 2 { cl_model = now[num - 1] + ""; break; }
        bool exact = false;
        for i in 0..all.len { if all[i] == t { exact = true; } }
        if exact { cl_model = t + ""; break; }
        String[] some = matching(all, t);
        if some.len == 0 { cl_model = t + ""; break; }          // a name that is not listed is taken as it is
        now = some;
        show_models(now);
    }
    set_model_of(cfg_provider, cl_model);
    cfg_save();
    jout << "model " << cl_model << nl;
    return true;
}

// the key and the model of the chosen provider are made ready (asked when missing); false when the person leaves
bool provider_ready(bool ask_model) {
    cl_key = read_key_of(cfg_provider);
    cl_messages = arr(8);
    if cl_key.len == 0 && provider_needs_key(cfg_provider) {
        jout << "ascode: no API key for " << cfg_provider << " yet.\n";
        if !ask_key() { return false; }
    }
    cl_model = model_of(cfg_provider);
    if cl_model.len == 0 || ask_model { if !pick_model() { return false; } }
    return true;
}

// choosing who answers
bool setup() {
    String[] all = provider_list();
    jout << "\nwho answers?\n";
    for i in 0..all.len {
        String about = provider_about(all[i]);
        String pad = "";
        for k in all[i].len..11 { pad.push(' '); }
        jout << " " << i + 1 << " " << all[i] << pad << about << nl;
    }
    String chosen = "";
    while chosen.len == 0 {
        String t = ask_line("number or name (Enter: " + cfg_provider + "): ");
        if t == "q" || (g_eof && t.len == 0) { return false; }
        if t.len == 0 { chosen = cfg_provider + ""; }
        else if provider_known(t) { chosen = t + ""; }
        else { i64 n = number_of(t); if n >= 1 && n <= all.len { chosen = all[n - 1] + ""; } else { jout << "not in the list\n"; } }
    }
    cfg_provider = chosen;
    if chosen == "custom" || chosen == "local" || chosen == "ollama" {
        String usual = provider_url(chosen);
        if cfg_url.len > 0 { usual = cfg_url + ""; }
        jout << "address of the API (.../v1)\n";
        if usual.len > 0 { jout << "Enter: " << usual << nl; }
        String u = ask_line("address: ");
        if u.len > 0 { cfg_url = u + ""; }
        if base_url().len == 0 { jout << "no address\n"; return false; }
    }
    cfg_save();
    if chosen == "custom" {                          // a key (if it wants one) comes first: the list of models may need it
        String have = read_key_of(chosen);
        if have.len == 0 { cl_key = ""; if !ask_key() { return false; } }
    }
    if !provider_ready(false) { return false; }
    set_model_of(cfg_provider, cl_model);
    cfg_save();
    return true;
}

void chat_banner() {
    String folder = g_root + "";
    if folder.len > 28 { folder = "..." + folder.slice(folder.len - 25, folder.len); }
    jout << "\n+------------------------------+\n";
    jout << "| ascode " << ascode_version() << "                 |\n";
    jout << "+------------------------------+\n";
    jout << " who     " << cfg_provider << nl;
    jout << " model   " << cl_model << nl;
    jout << " mode    " << g_mode << nl;
    jout << " folder  " << folder << nl;
    jout << " /help commands   /exit leave\n";
}

void show_config() {
    String address = base_url();
    String key = "none";
    String k = read_key_of(cfg_provider);
    if k.len > 0 { key = "set"; }
    jout << "provider " << cfg_provider << nl;
    jout << "model    " << cl_model << nl;
    jout << "address  " << address << nl;
    jout << "key      " << key << nl;
    jout << "mode     " << g_mode << nl;
    if cfg_max > 0 { jout << "max      " << cfg_max << nl; } else { jout << "max      usual\n"; }
    if cfg_note.len > 0 { jout << "note     " << cfg_note << nl; }
}

void chat_help() {
    jout << "/setup         who, key, model\n";
    jout << "/provider NAME another one\n";
    jout << "/models [word] what it offers\n";
    jout << "/model NAME    choose a model\n";
    jout << "/key           a new API key\n";
    jout << "/url ADDRESS   local or custom\n";
    jout << "/mode ask|read|auto\n";
    jout << "     ask: a change needs a y\n";
    jout << "     read: changes are refused\n";
    jout << "     auto: changes in the folder\n";
    jout << "/max N         answer length\n";
    jout << "/note TEXT     always told\n";
    jout << "/config        the settings\n";
    jout << "/clear         a new talk\n";
    jout << "/exit          leave\n";
}

void chat_command(String line) {
    i64 sp = line.find(" ");
    String c = line + "";
    String v = "";
    if sp > 0 { c = line.slice(0, sp) + ""; v = line.slice(sp + 1, line.len).trim() + ""; }
    if c == "/help" { chat_help(); return; }
    if c == "/config" { show_config(); return; }
    if c == "/clear" { cl_messages = arr(8); jout << "a new talk\n"; return; }
    if c == "/key" { ask_key(); return; }
    if c == "/setup" || c == "/provider" {
        String before = cfg_provider + "";
        bool ok = false;
        if c == "/provider" && v.len > 0 {
            if !provider_known(v) { jout << "no provider " << v << " (/provider shows them)\n"; return; }
            cfg_provider = v + "";
            ok = provider_ready(false);
            if ok { cfg_save(); }
        } else { ok = setup(); }
        if !ok { cfg_provider = before + ""; provider_ready(false); jout << "still " << cfg_provider << nl; return; }
        jout << cfg_provider << ", model " << cl_model << " (a new talk)\n";
        return;
    }
    if c == "/mode" {
        if v == "ask" || v == "read" || v == "auto" { g_mode = v + ""; cfg_mode = v + ""; cfg_save(); }
        else if v.len > 0 { jout << "the mode is ask, read or auto\n"; }
        jout << "mode: " << g_mode << nl;
        return;
    }
    if c == "/models" {
        String[] all = fetch_models();
        String[] some = matching(all, v);
        if some.len == 0 { jout << "none\n"; return; }
        show_models(some);
        return;
    }
    if c == "/model" {
        if v.len == 0 { if pick_model() { cl_messages = arr(8); } return; }
        cl_model = v + "";
        set_model_of(cfg_provider, v);
        cfg_save();
        cl_messages = arr(8);                    // the thoughts of one model are not given to another
        jout << "model " << cl_model << " (a new talk)\n";
        return;
    }
    if c == "/url" {
        if v.len > 0 {
            if cfg_provider != "custom" && cfg_provider != "local" && cfg_provider != "ollama" { jout << "only custom, local and ollama\nhave their own address\n"; return; }
            cfg_url = v + "";
            cfg_save();
        }
        String a = base_url();
        jout << "address " << a << nl;
        return;
    }
    if c == "/max" {
        if v.len > 0 { cfg_max = number_of(v); if cfg_max < 0 { cfg_max = 0; } cfg_save(); }
        if cfg_max > 0 { jout << "max " << cfg_max << " tokens\n"; } else { jout << "max: usual\n"; }
        return;
    }
    if c == "/note" {
        if v == "none" { cfg_note = ""; cfg_save(); } else if v.len > 0 { cfg_note = v + ""; cfg_save(); }
        if cfg_note.len > 0 { jout << "note: " << cfg_note << nl; } else { jout << "no note (/note TEXT, /note none)\n"; }
        return;
    }
    jout << "no command " << c << " (see /help)\n";
}

i64 run_model(String task) {
    if provider_anthropic(cfg_provider) { return cl_run(task); }
    return oa_run(task);
}

// the session; first: nothing was chosen yet
i64 chat(bool first) {
    if first { if !setup() { return 1; } }
    else { if !provider_ready(false) { return 1; } }
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
        if run_model(t) != 0 {                      // a talk that failed is forgotten, so that the next one is whole
            while cl_messages.len > before { cl_messages.pop(); }
        }
    }
    jout << nl;
    return 0;
}
