// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// config: who answers (the provider), with which model and address, and the other settings, kept in  ~/.config/ascode/config  (lines
// "name = value"). A key is kept in its own file, for the person only: key (Claude), key.NAME (the others). It is never printed.

String cfg_provider;
String cfg_url;               // the address of the person: custom, local, ollama
String cfg_note;              // added to what the model is told first
i64 cfg_max;                  // the longest answer in tokens, 0: the usual
String cfg_mode;
String[] cfg_models;          // "provider=model"
bool cfg_exists;

#define DEFAULT_MODEL "claude-opus-5-5"
#define PROVIDERS "claude openrouter openai gemini groq deepseek mistral together local ollama custom"

String[] provider_list() { return PROVIDERS.split(" "); }

bool provider_known(String p) {
    String all = " ";
    all.append(PROVIDERS);
    all.push(' ');
    String one = " " + p + " ";
    return p.len > 0 && all.contains(one);
}

// the claude provider speaks the Messages API of Anthropic; all the others speak "chat completions"
bool provider_anthropic(String p) { return p == "claude"; }

// without a key these cannot be asked
bool provider_needs_key(String p) { return !(p == "local" || p == "ollama" || p == "custom"); }

String provider_url(String p) {
    if p == "claude" { return "https://api.anthropic.com/v1"; }
    if p == "openrouter" { return "https://openrouter.ai/api/v1"; }
    if p == "openai" { return "https://api.openai.com/v1"; }
    if p == "gemini" { return "https://generativelanguage.googleapis.com/v1beta/openai"; }
    if p == "groq" { return "https://api.groq.com/openai/v1"; }
    if p == "deepseek" { return "https://api.deepseek.com/v1"; }
    if p == "mistral" { return "https://api.mistral.ai/v1"; }
    if p == "together" { return "https://api.together.xyz/v1"; }
    if p == "local" { return "http://127.0.0.1:8080/v1"; }
    if p == "ollama" { return "http://127.0.0.1:11434/v1"; }
    return "";
}

String provider_about(String p) {
    if p == "claude" { return "Anthropic"; }
    if p == "openrouter" { return "many models, one key"; }
    if p == "openai" { return "OpenAI"; }
    if p == "gemini" { return "Google"; }
    if p == "local" { return "llama.cpp on here"; }
    if p == "ollama" { return "Ollama on here"; }
    if p == "custom" { return "your own address"; }
    return "";
}

// where a key is made
String provider_key_place(String p) {
    if p == "claude" { return "console.anthropic.com"; }
    if p == "openrouter" { return "openrouter.ai/keys"; }
    if p == "openai" { return "platform.openai.com"; }
    if p == "gemini" { return "aistudio.google.com"; }
    if p == "groq" { return "console.groq.com"; }
    if p == "deepseek" { return "platform.deepseek.com"; }
    if p == "mistral" { return "console.mistral.ai"; }
    if p == "together" { return "api.together.xyz"; }
    return "";
}

String cfg_dir() { return Env::get("HOME").or(".") + "/.config/ascode"; }

void cfg_mkdir() {
    String up = Env::get("HOME").or(".") + "/.config";
    Sys::mkdir(up.c(), 448);
    String d = cfg_dir();
    Sys::mkdir(d.c(), 448);
}

void cfg_load() {
    cfg_provider = "claude"; cfg_url = ""; cfg_note = ""; cfg_max = 0; cfg_mode = "ask";
    cfg_models = arr(8);
    cfg_exists = false;
    String f = cfg_dir() + "/config";
    Result<String, Error> r = Fs::read_text(f);
    if r.is_err() { return; }
    cfg_exists = true;
    String all = r.take();
    String[] ls = all.split("\n");
    for i in 0..ls.len {
        i64 eq = ls[i].find("=");
        if eq <= 0 || ls[i][0] == '#' { continue; }
        String k = ls[i].slice(0, eq).trim() + "";
        String v = ls[i].slice(eq + 1, ls[i].len).trim() + "";
        if k == "provider" { if provider_known(v) { cfg_provider = v + ""; } }
        else if k == "url" { cfg_url = v + ""; }
        else if k == "note" { cfg_note = v + ""; }
        else if k == "max_tokens" { for j in 0..v.len { if v[j] >= '0' && v[j] <= '9' && cfg_max < 100000000 { cfg_max = cfg_max * 10 + (v[j] - '0'); } } }
        else if k == "mode" { if v == "ask" || v == "read" || v == "auto" { cfg_mode = v + ""; } }
        else if k.starts_with("model.") { cfg_models.push(k.slice(6, k.len) + "=" + v); }
    }
}

bool cfg_save() {
    cfg_mkdir();
    String t = "# ascode: the settings (ascode setup changes them)\n";
    t.append("provider = " + cfg_provider + "\n");
    t.append("mode = " + cfg_mode + "\n");
    if cfg_url.len > 0 { t.append("url = " + cfg_url + "\n"); }
    if cfg_max > 0 { t.append("max_tokens = " + stg(cfg_max) + "\n"); }
    if cfg_note.len > 0 { t.append("note = " + cfg_note + "\n"); }
    for i in 0..cfg_models.len {
        i64 eq = cfg_models[i].find("=");
        t.append("model." + cfg_models[i].slice(0, eq) + " = " + cfg_models[i].slice(eq + 1, cfg_models[i].len) + "\n");
    }
    String f = cfg_dir() + "/config";
    Result<i64, Error> w = Fs::write_text(f, t);
    if w.is_err() { return false; }
    cfg_exists = true;
    return true;
}

// the model chosen for a provider, "" when none is (Claude has one from the start)
String model_of(String p) {
    String head = p + "=";
    for i in 0..cfg_models.len { if cfg_models[i].starts_with(head) { return cfg_models[i].slice(head.len, cfg_models[i].len); } }
    String first = "";
    if p == "claude" { first.append(DEFAULT_MODEL); }
    return first;
}

void set_model_of(String p, String m) {
    String head = p + "=";
    for i in 0..cfg_models.len { if cfg_models[i].starts_with(head) { cfg_models[i] = head + m; return; } }
    cfg_models.push(head + m);
}

// the address of the chosen provider: the person's own one for custom, local and ollama
String base_url() {
    bool own = cfg_provider == "custom" || cfg_provider == "local" || cfg_provider == "ollama";
    String u = "";
    if own && cfg_url.len > 0 { u = cfg_url + ""; } else { u = provider_url(cfg_provider); }
    if u.ends_with("/") { return u.slice(0, u.len - 1); }
    return u;
}

// a key goes only over https, or to this machine itself
bool url_keeps_secret(String u) {
    return u.starts_with("https://") || u.starts_with("http://127.0.0.1") || u.starts_with("http://localhost");
}

String key_file(String p) {
    if p == "claude" { return cfg_dir() + "/key"; }
    return cfg_dir() + "/key." + p;
}

// the key of a provider: the variable (ANTHROPIC_API_KEY for Claude, ASCODE_API_KEY for the others) or the file; "" when there is none
String read_key_of(String p) {
    String v = "ASCODE_API_KEY";
    if p == "claude" { v = "ANTHROPIC_API_KEY"; }
    String k = Env::get(v).or("");
    if k.len > 0 { return k; }
    String f = key_file(p);
    Result<String, Error> r = Fs::read_text(f);
    if r.is_err() { return ""; }
    String t = r.take();
    String t2 = t.trim();
    return t2;
}

bool save_key_of(String p, String key) {
    cfg_mkdir();
    String f = key_file(p);
    Result<i64, Error> w = Fs::write_text(f, key + "\n");
    if w.is_err() { return false; }
    Sys::chmod(f.c(), 384);
    return true;
}
