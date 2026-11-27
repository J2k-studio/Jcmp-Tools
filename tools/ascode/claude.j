// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// (A brace in a text is written \x7b / \x7d here: the compiler would read some braces as a value to put into the text.)
// claude: the model of ascode that speaks the Messages API of Anthropic (https). The key is read from  ~/.config/ascode/key  (or the variable
// ANTHROPIC_API_KEY) and is only sent in the header of the request: it is never printed, written elsewhere or shown to the model.
//   The conversation is kept as the JSON texts of the messages; what the model answered is sent back exactly as it came (its thinking blocks too).


String cl_model;
String cl_key;
String[] cl_messages;

// the address; ASCODE_API_URL names another (the tests)
String cl_url() {
    String own = base_url() + "/messages";
    return Env::get("ASCODE_API_URL").or(own);
}

String cl_system() {
    String s = "You work in the folder of the person on a phone (Android, the terminal exshell). Use the tools to look before you change anything. The person is asked before a change; a refusal is final. Answer in the language of the person. Keep answers short: the screen is narrow.";
    if cfg_note.len > 0 { s.append(" The person also says: " + cfg_note); }
    return s;
}

// the tools, in the form of the API
String cl_tools() {
    String t = "";
    t.append("[\x7b\"name\":\"read\",\"description\":\"Read a text file\",\"input_schema\":\x7b\"type\":\"object\",\"properties\":\x7b\"path\":\x7b\"type\":\"string\"\x7d\x7d,\"required\":[\"path\"]\x7d\x7d,");
    t.append("\x7b\"name\":\"list\",\"description\":\"List a folder\",\"input_schema\":\x7b\"type\":\"object\",\"properties\":\x7b\"dir\":\x7b\"type\":\"string\"\x7d\x7d,\"required\":[]\x7d\x7d,");
    t.append("\x7b\"name\":\"search\",\"description\":\"Find the lines of the files of a folder that hold a text (plain text)\",\"input_schema\":\x7b\"type\":\"object\",\"properties\":\x7b\"text\":\x7b\"type\":\"string\"\x7d,\"dir\":\x7b\"type\":\"string\"\x7d\x7d,\"required\":[\"text\"]\x7d\x7d,");
    t.append("\x7b\"name\":\"write\",\"description\":\"Write a whole file (asks the person)\",\"input_schema\":\x7b\"type\":\"object\",\"properties\":\x7b\"path\":\x7b\"type\":\"string\"\x7d,\"content\":\x7b\"type\":\"string\"\x7d\x7d,\"required\":[\"path\",\"content\"]\x7d\x7d,");
    t.append("\x7b\"name\":\"edit\",\"description\":\"Replace a text that is in a file exactly once (asks the person)\",\"input_schema\":\x7b\"type\":\"object\",\"properties\":\x7b\"path\":\x7b\"type\":\"string\"\x7d,\"old\":\x7b\"type\":\"string\"\x7d,\"new\":\x7b\"type\":\"string\"\x7d\x7d,\"required\":[\"path\",\"old\",\"new\"]\x7d\x7d,");
    t.append("\x7b\"name\":\"run\",\"description\":\"Run a command in the shell jsh and get its output (asks the person)\",\"input_schema\":\x7b\"type\":\"object\",\"properties\":\x7b\"command\":\x7b\"type\":\"string\"\x7d\x7d,\"required\":[\"command\"]\x7d\x7d]");
    return t;
}

void cl_user_text(String text) {
    cl_messages.push("\x7b\"role\":\"user\",\"content\":" + Json::quote(text) + "\x7d");
}

// the newest Opus and Fable models can hand a declined request to another model inside the same call
bool cl_has_fallbacks() { return cl_model.starts_with("claude-opus-5") || cl_model.starts_with("claude-fable"); }

String cl_body() {
    i64 limit = 16000;
    if cfg_max > 0 { limit = cfg_max; }
    String b = "\x7b\"model\":" + Json::quote(cl_model) + ",\"max_tokens\":" + stg(limit);
    if cl_has_fallbacks() { b.append(",\"fallbacks\":\"default\""); }
    b.append(",\"system\":" + Json::quote(cl_system()) + ",\"tools\":" + cl_tools() + ",\"messages\":[");
    for i in 0..cl_messages.len { if i > 0 { b.push(','); } b.append(cl_messages[i]); }
    b.append("]\x7d");
    return b;
}

// the text of a string member of a node, "" when it is not there
String cl_str(JsonDoc^ d, i64 node, String name) {
    i64 n = d^.get(node, name);
    if n < 0 { return ""; }
    return d^.text(n);
}

// one exchange with an API: the status code in status, the body as the result ("" and status 0 when nothing came)
String api_send(String method, String url, String headers, String body, i64^ status) {
    status^ = 0;
    if cl_key.len > 0 && !url_keeps_secret(url) { jerr << "ascode: the key is only sent over https (or to this machine): " << url << "\n"; return ""; }
    Result<String, Error> r = Net::http_exchange(method, url, headers, body, 0, 0);
    if r.is_err() { jerr << "ascode: no answer from " << url << "\n(check the network, /url)\n"; return ""; }
    String reply = r.take();
    i64 sp = reply.find(" ");
    i64 code = 0;
    if sp > 0 { for k in sp + 1..sp + 4 { if k < reply.len && reply[k] >= '0' && reply[k] <= '9' { code = code * 10 + (reply[k] - '0'); } } }
    status^ = code;
    i64 he = reply.find("\r\n\r\n");
    if he < 0 { return ""; }
    return reply.slice(he + 4, reply.len);
}

String cl_headers() {
    String h = "content-type: application/json\r\nx-api-key: " + cl_key + "\r\nanthropic-version: 2026-10-21\r\n";
    if cl_has_fallbacks() { h.append("anthropic-beta: server-side-fallback-2026-07-01\r\n"); }
    return h;
}

void api_failed(i64 status, String why) {
    jerr << "ascode: the API says HTTP " << status << ": " << why << "\n";
    if status == 401 || status == 403 { jerr << "ascode: check the key (/key)\n"; }
    if status == 404 { jerr << "ascode: check the model (/models) and the address (/config)\n"; }
}

// a tool the model asks for: it is shown, done (a change asks the person first), and what it gave comes back
String use_tool(String name, JsonDoc^ d, i64 input) {
    g_args = arr(4);
    if input >= 0 {
        if name == "read" { g_args.push(cl_str(d, input, "path")); }
        else if name == "list" { g_args.push(cl_str(d, input, "dir")); }
        else if name == "search" { g_args.push(cl_str(d, input, "text")); g_args.push(cl_str(d, input, "dir")); }
        else if name == "write" { g_args.push(cl_str(d, input, "path")); g_args.push(cl_str(d, input, "content")); }
        else if name == "edit" { g_args.push(cl_str(d, input, "path")); g_args.push(cl_str(d, input, "old")); g_args.push(cl_str(d, input, "new")); }
        else if name == "run" { g_args.push(cl_str(d, input, "command")); }
    }
    String shown = arg_of(0);
    if shown.len > 200 { shown = shown.slice(0, 200) + "..."; }
    jout << "* " << name << " " << shown << nl;
    return do_tool(name);
}

// the loop with the model: its text is printed, each tool it asks for is done (do_tool asks the person for a change) and the results go back
// together; until the model ends. 0 ok, 1 something went wrong.
i64 cl_run(String task) {
    cl_user_text(task);
    for turn in 0..40 {
        i64 status = 0;
        String url = cl_url();
        String body = api_send("POST", url, cl_headers(), cl_body(), @status);
        if body.len == 0 { return 1; }
        Result<JsonDoc, Error> pr = Json::parse(body);
        if pr.is_err() { jerr << "ascode: the answer is not JSON (HTTP " << status << ")\n"; return 1; }
        JsonDoc d = pr.take();
        if status != 200 { api_failed(status, api_error_text(@d)); return 1; }
        String stop = cl_str(@d, 0, "stop_reason");
        if stop == "refusal" { jout << "ascode: the model declined this request\n"; return 1; }
        i64 content = d.get(0, "content");
        if content < 0 { jerr << "ascode: an answer without content\n"; return 1; }
        String results = "";
        for i in 0..d.len(content) {
            i64 blk = d.at(content, i);
            String kind = cl_str(@d, blk, "type");
            if kind == "text" { jout << cl_str(@d, blk, "text") << nl; }
            if kind == "tool_use" {
                String name = cl_str(@d, blk, "name");
                String id = cl_str(@d, blk, "id");
                i64 input = d.get(blk, "input");
                String res = use_tool(name, @d, input);
                String bad = "";
                if res.starts_with("error:") || res.starts_with("refused:") { bad = ",\"is_error\":true"; }
                if results.len > 0 { results.push(','); }
                results.append("\x7b\"type\":\"tool_result\",\"tool_use_id\":" + Json::quote(id) + ",\"content\":" + Json::quote(res) + bad + "\x7d");
            }
        }
        cl_messages.push("\x7b\"role\":\"assistant\",\"content\":" + d.dump(content) + "\x7d");
        if stop == "max_tokens" { jout << "ascode: the answer was cut (too long)\n"; return 1; }
        if results.len == 0 { return 0; }
        cl_messages.push("\x7b\"role\":\"user\",\"content\":[" + results + "]\x7d");
    }
    jout << "ascode: stopped after 40 steps\n";
    return 1;
}
