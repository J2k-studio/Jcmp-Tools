// jget as a curl: a request with a method, headers and a body, and what comes back. Used when one of these is on the command line:
//   -X METHOD   -H "Name: value"   -d DATA (@file reads a file, @- the keyboard)   -I (the head only)   -i (the head, then the body)
//   -u user:password   -A agent   -f (a code of 400 or more is an error: exit 22)   -L (follow redirects: it is on; --no-location turns it off)
//   -s (quiet)   -o FILE   -O (the name in the address)   -w "%{http_code}" (the code, then a new line, after the body)
// The body goes to the screen (curl does that too) unless -o or -O is given.

struct ReqOpts {
    String method;
    String headers;          // "Name: value\r\n" for each -H
    String body;
    bool head_only;
    bool with_head;
    bool fail;
    bool follow;
    bool by_name;
    bool write_code;
    String to;
    String url;
}

bool req_flag_takes_value(String a) {
    return a == "-X" || a == "-H" || a == "-d" || a == "-u" || a == "-A" || a == "-o" || a == "-w" || a == "--data" || a == "--header" || a == "--request" || a == "--user" || a == "--user-agent" || a == "--output" || a == "--data-raw";
}

// is this a request in the curl sense (not a plain download)?
bool req_wanted(String[] av, i64 at) {
    for i in at..av.len {
        String a = av[i];
        if a == "-X" || a == "-H" || a == "-d" || a == "-I" || a == "-i" || a == "-u" || a == "-A" || a == "-f" || a == "-w" || a == "--no-location" || a == "--head" || a == "--include" || a == "--data" || a == "--header" || a == "--request" || a == "--fail" || a == "--data-raw" { return true; }
    }
    return false;
}

String req_read_body(String spec) {
    if spec.starts_with("@") {
        String file = spec.slice(1, spec.len) + "";
        if file == "-" {
            String all = "";
            while true {
                String l = Input::line();
                if l.len == 0 { break; }
                all.append(l);
                all.append("\n");
            }
            return all;
        }
        Result<String, Error> r = Fs::read_text(file);
        if !r.is_ok() { err("jget: cannot read " + file + "\n"); return ""; }
        return r.take();
    }
    return spec + "";
}

i64 cmd_request(String[] av, i64 at) {
    ReqOpts o;
    o.method = "";
    o.headers = "";
    o.body = "";
    o.to = "";
    o.url = "";
    o.follow = true;
    bool has_ctype = false;
    i64 i = at;
    while i < av.len {
        String a = av[i];
        if req_flag_takes_value(a) && i + 1 >= av.len { err("jget: " + a + " needs a value\n"); return 2; }
        if a == "-X" || a == "--request" { o.method = av[i + 1].upper(); i += 2; }
        else if a == "-H" || a == "--header" {
            String h = av[i + 1].trim();
            if h.lower().starts_with("content-type:") { has_ctype = true; }
            o.headers.append(h + "\r\n");
            i += 2;
        }
        else if a == "-d" || a == "--data" || a == "--data-raw" {
            if o.body.len > 0 { o.body.append("&"); }
            o.body.append(req_read_body(av[i + 1]));
            i += 2;
        }
        else if a == "-u" || a == "--user" { o.headers.append("Authorization: Basic " + Base64::encode(av[i + 1] + "") + "\r\n"); i += 2; }
        else if a == "-A" || a == "--user-agent" { o.headers.append("User-Agent: " + av[i + 1] + "\r\n"); i += 2; }
        else if a == "-o" || a == "--output" { o.to = av[i + 1] + ""; i += 2; }
        else if a == "-w" { o.write_code = true; i += 2; }
        else if a == "-I" || a == "--head" { o.head_only = true; i += 1; }
        else if a == "-i" || a == "--include" { o.with_head = true; i += 1; }
        else if a == "-f" || a == "--fail" { o.fail = true; i += 1; }
        else if a == "-L" || a == "--location" { o.follow = true; i += 1; }
        else if a == "--no-location" { o.follow = false; i += 1; }
        else if a == "-O" { o.by_name = true; i += 1; }
        else if a == "-s" || a == "-S" || a == "-h" { i += 1; }
        else if a.starts_with("-") && a.len > 1 { err("jget: unknown option " + a + "\n"); return 2; }
        else if o.url.len == 0 { o.url = a + ""; i += 1; }
        else { err("jget: one address only (got " + o.url + " and " + a + ")\n"); return 2; }
    }
    if o.url.len == 0 { return usage(); }
    if o.method.len == 0 {
        if o.head_only { o.method = "HEAD"; }
        else if o.body.len > 0 { o.method = "POST"; }
        else { o.method = "GET"; }
    }
    if o.body.len > 0 && !has_ctype { o.headers.append("Content-Type: application/x-www-form-urlencoded\r\n"); }
    i64 follow = 0;
    if o.follow { follow = 1; }
    String reply = "";
    switch Net::http_exchange(o.method, o.url, o.headers, o.body, follow, 0) {
        Result::Ok(t): { reply = t; }
        Result::Err(e): { err("jget: " + e.message + "\n"); return 1; }
    }
    i64 he = reply.find("\r\n\r\n");
    String head = reply.slice(0, he) + "";
    String body = reply.slice(he + 4, reply.len) + "";
    i64 code = 0;
    if head.len >= 12 { code = head.slice(9, 12).to_int(); }
    String out = "";
    if o.head_only { out = head + "\r\n\r\n"; }
    else if o.with_head { out = head + "\r\n\r\n" + body; }
    else { out = body; }
    if o.fail && code >= 400 {
        err("jget: the server answered " + str(code) + "\n");
        return 22;
    }
    String to = o.to;
    if to.len == 0 && o.by_name { to = name_of(o.url); }
    if to.len == 0 || to == "-" {
        jout << out;
    } else {
        switch Fs::write_text(to, out) {
            Result::Ok(n): { }
            Result::Err(e): { err("jget: cannot write " + to + ": " + e.message + "\n"); return 1; }
        }
    }
    if o.write_code { jout << str(code) << "\n"; }
    return 0;
}
