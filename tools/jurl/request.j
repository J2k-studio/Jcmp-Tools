// jurl as a curl: a request with a method, headers and a body, and what comes back. Used when one of these is on the command line:
//   -X METHOD   -H "Name: value"   -d DATA (@file reads a file, @- the keyboard)   -I (the head only)   -i (the head, then the body)
//   -u user:password   -A agent   -f (a code of 400 or more is an error: exit 22)   -L (follow redirects: it is on; --no-location turns it off)
//   -s (quiet)   -o FILE   -O (the name in the address)   -w "%{http_code}" (the code, then a new line, after the body)
// The body goes to the screen (curl does that too) unless -o or -O is given.

// The commands people copy from the web are written for curl. Their flags are brought to one form before anything looks at them: a bundle
// (-fsSL) is parted, a value written right after its letter (-oNAME) is parted too, long names become the letters, and what changes nothing
// here (--compressed, --max-time 30 ...) is dropped. What comes after -sh / -jsh belongs to the script and is left as it is.
String curl_long(String a) {
    if a == "--silent" { return "-s"; }
    if a == "--show-error" { return "-S"; }
    if a == "--fail" { return "-f"; }
    if a == "--location" { return "-L"; }
    if a == "--remote-name" { return "-O"; }
    if a == "--head" { return "-I"; }
    if a == "--include" { return "-i"; }
    if a == "--output" { return "-o"; }
    if a == "--request" { return "-X"; }
    if a == "--header" { return "-H"; }
    if a == "--data" || a == "--data-raw" || a == "--data-binary" { return "-d"; }
    if a == "--user" { return "-u"; }
    if a == "--user-agent" { return "-A"; }
    if a == "--write-out" { return "-w"; }
    if a == "--retry" { return "-r"; }
    if a == "--insecure" { return "-k"; }
    return a + "";
}

// the words with a value that is dropped, and those without
bool curl_dropped_value(String a) { return a == "--max-time" || a == "--connect-timeout" || a == "--retry-delay" || a == "--retry-max-time" || a == "-m_" || a == "--proto"; }
bool curl_dropped(String a) { return a == "--compressed" || a == "--progress-bar" || a == "--tlsv1.2" || a == "--tlsv1.3" || a == "--http1.1" || a == "--http2" || a == "--ipv4" || a == "-4" || a == "-6" || a == "-#" || a == "--no-progress-meter"; }

String[] curl_words(String[] av) {
    String[] out = arr(av.len + 8);
    bool script = false;
    i64 i = 0;
    while i < av.len {
        String a = av[i] + "";
        if i == 0 || script { out.push(a + ""); i += 1; continue; }
        if a == "-sh" || a == "-jsh" { script = true; out.push(a + ""); i += 1; continue; }
        if curl_dropped(a) { i += 1; continue; }
        if curl_dropped_value(a) { i += 2; continue; }
        if a.starts_with("--") {
            String s = curl_long(a);
            out.push(s + "");
            i += 1;
            if req_letter_takes_value(s) && i < av.len { out.push(av[i] + ""); i += 1; }
            continue;
        }
        if a.len > 2 && a[0] == '-' && a != "-li" && cluster_known(a) {
            bool took = false;
            for k in 1..a.len {
                if took { break; }
                String one = "-";
                one.push(a[k]);
                if one == "-4" || one == "-6" || one == "-#" { continue; }
                out.push(one + "");
                if req_letter_takes_value(one) {
                    if k + 1 < a.len { out.push(a.slice(k + 1, a.len)); }
                    else if i + 1 < av.len { i += 1; out.push(av[i] + ""); }
                    took = true;
                }
            }
            i += 1;
            continue;
        }
        out.push(a + "");
        i += 1;
        if req_letter_takes_value(a) && i < av.len { out.push(av[i] + ""); i += 1; }          // the value stays as it is, whatever it looks like
    }
    return out;
}

bool req_letter_takes_value(String a) { return a == "-o" || a == "-X" || a == "-H" || a == "-d" || a == "-u" || a == "-A" || a == "-w" || a == "-r" || a == "-P" || a == "-l"; }

// is every letter of a bundle one that is known (up to the first that takes a value)
bool cluster_known(String a) {
    String plain = "fsSLOIivkq46#";
    String valued = "oXHdAuwrP";
    for k in 1..a.len {
        String c = "";
        c.push(a[k]);
        if valued.contains(c) { return true; }
        if !plain.contains(c) { return false; }
    }
    return true;
}

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
        if !r.is_ok() { err("jurl: cannot read " + file + "\n"); return ""; }
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
        if req_flag_takes_value(a) && i + 1 >= av.len { err("jurl: " + a + " needs a value\n"); return 2; }
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
        else if a == "-s" || a == "-S" || a == "-h" || a == "-v" || a == "-q" { i += 1; }
        else if a == "-r" && i + 1 < av.len { i += 2; }
        else if a.starts_with("-") && a.len > 1 { err("jurl: unknown option " + a + "\n"); return 2; }
        else if o.url.len == 0 { o.url = a + ""; i += 1; }
        else { err("jurl: one address only (got " + o.url + " and " + a + ")\n"); return 2; }
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
        Result::Err(e): { err("jurl: " + e.message + "\n"); return 1; }
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
        err("jurl: the server answered " + str(code) + "\n");
        return 22;
    }
    String to = o.to;
    if to.len == 0 && o.by_name { to = name_of(o.url); }
    if to.len == 0 || to == "-" {
        jout << out;
    } else {
        switch Fs::write_text(to, out) {
            Result::Ok(n): { }
            Result::Err(e): { err("jurl: cannot write " + to + ": " + e.message + "\n"); return 1; }
        }
    }
    if o.write_code { jout << str(code) << "\n"; }
    return 0;
}
