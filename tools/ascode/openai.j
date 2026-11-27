// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// openai: the providers that speak "chat completions" (OpenRouter, OpenAI, Gemini, Groq, llama.cpp, Ollama and others). The talk and the tools
// are the same as with Claude; only the form of the messages differs. (A brace in a text is written \x7b / \x7d.)

// the tools in this form: the same names and parameters as claude.j gives, wrapped as functions
String oa_tools() {
    String c = cl_tools();
    String a = c.replace("\x7b\"name\":", "\x7b\"type\":\"function\",\"function\":\x7b\"name\":");
    String b = a.replace("\"input_schema\":", "\"parameters\":");
    // each function object is closed before the next one begins, and the last one before the list ends
    String mid = b.replace("\x7d,\x7b\"type\":\"function\"", "\x7d\x7d,\x7b\"type\":\"function\"");
    return mid.slice(0, mid.len - 1) + "\x7d]";
}

String oa_body() {
    String b = "\x7b\"model\":" + Json::quote(cl_model);
    if cfg_max > 0 { b.append(",\"max_tokens\":" + stg(cfg_max)); }
    b.append(",\"tools\":" + oa_tools() + ",\"messages\":[\x7b\"role\":\"system\",\"content\":" + Json::quote(cl_system()) + "\x7d");
    for i in 0..cl_messages.len { b.push(','); b.append(cl_messages[i]); }
    b.append("]\x7d");
    return b;
}

String oa_headers() {
    String h = "content-type: application/json\r\n";
    if cl_key.len > 0 { h.append("authorization: Bearer " + cl_key + "\r\n"); }
    return h;
}

// the message of an error answer: {"error":{"message":...}} or {"error":"..."}
String api_error_text(JsonDoc^ d) {
    i64 er = d^.get(0, "error");
    if er < 0 { return ""; }
    String s = d^.text(er);
    if s.len > 0 { return s; }
    return cl_str(d, er, "message");
}

i64 oa_run(String task) {
    cl_user_text(task);
    for turn in 0..40 {
        i64 status = 0;
        String url = base_url() + "/chat/completions";
        String body = api_send("POST", url, oa_headers(), oa_body(), @status);
        if body.len == 0 { return 1; }
        Result<JsonDoc, Error> pr = Json::parse(body);
        if pr.is_err() { jerr << "ascode: the answer is not JSON (HTTP " << status << ")\n"; return 1; }
        JsonDoc d = pr.take();
        if status != 200 { api_failed(status, api_error_text(@d)); return 1; }
        i64 choices = d.get(0, "choices");
        if choices < 0 || d.len(choices) == 0 { String why = api_error_text(@d); jerr << "ascode: an answer without a choice " << why << "\n"; return 1; }
        i64 first = d.at(choices, 0);
        i64 msg = d.get(first, "message");
        if msg < 0 { jerr << "ascode: an answer without a message\n"; return 1; }
        String text = cl_str(@d, msg, "content");
        if text.len > 0 { jout << text << nl; }
        cl_messages.push(d.dump(msg));
        i64 calls = d.get(msg, "tool_calls");
        i64 n = 0;
        if calls >= 0 { n = d.len(calls); }
        for i in 0..n {
            i64 call = d.at(calls, i);
            String id = cl_str(@d, call, "id");
            i64 fun = d.get(call, "function");
            if fun < 0 { continue; }
            String name = cl_str(@d, fun, "name");
            String given = cl_str(@d, fun, "arguments");           // the arguments are a text that holds JSON
            String res = "";
            Result<JsonDoc, Error> pa = Json::parse(given);
            if pa.is_err() { res = "error: the arguments of the tool are not JSON"; g_args = arr(1); jout << "* " << name << " (bad arguments)\n"; }
            else {
                JsonDoc args = pa.take();
                res = use_tool(name, @args, 0);
            }
            cl_messages.push("\x7b\"role\":\"tool\",\"tool_call_id\":" + Json::quote(id) + ",\"content\":" + Json::quote(res) + "\x7d");
        }
        String stop = cl_str(@d, first, "finish_reason");
        if stop == "length" { jout << "ascode: the answer was cut (too long; /max changes the limit)\n"; return 1; }
        if n == 0 { return 0; }
    }
    jout << "ascode: stopped after 40 steps\n";
    return 1;
}
