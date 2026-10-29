// jgitnet -- the network of jgit: clone, fetch, pull and push over http(s) (the "smart" protocol of git), with a token for the password.
// The objects that come are written as loose objects (one file for each), so no index of a pack has to be made. Merges are not made: a pull moves
// the branch forward only when it can (fast-forward).

// ---------------------------------------------------------------- the address and the password
struct Url {
    bool secure;
    String host;
    int port;
    String hostport;
    String path;                       // /user/repo.git (without a slash at the end)
}

// https://host/path.git, http://host:port/path, or the form of ssh git@host:user/repo (read as https://host/user/repo)
bool parse_url(String url0, Url^ out) {
    String url = url0 + "";
    if url.starts_with("git@") && url.contains(":") && !url.contains("://") {
        int c = url.find(":");
        url = "https://" + url.slice(4, c) + "/" + url.slice(c + 1, url.len);
    }
    int plen = 0;
    out^.secure = false;
    out^.port = 80;
    if url.starts_with("https://") { plen = 8; out^.secure = true; out^.port = 443; }
    else if url.starts_with("http://") { plen = 7; }
    else { return false; }
    String rest = url.slice(plen, url.len);
    int slash = rest.find("/");
    if slash < 0 { return false; }
    out^.hostport = rest.slice(0, slash);
    out^.path = rest.slice(slash, rest.len);
    while out^.path.len > 1 && out^.path.ends_with("/") { out^.path = out^.path.slice(0, out^.path.len - 1); }
    out^.host = out^.hostport;
    int colon = out^.hostport.find(":");
    if colon >= 0 {
        out^.host = out^.hostport.slice(0, colon);
        out^.port = out^.hostport.slice(colon + 1, out^.hostport.len).to_int();
    }
    int at = out^.host.find("@");                                     // user:password@host is not used: the token comes from jgit login
    if at >= 0 { out^.host = out^.host.slice(at + 1, out^.host.len); out^.hostport = out^.hostport.slice(out^.hostport.find("@") + 1, out^.hostport.len); }
    return out^.host.len > 0;
}

String b64(String s) { return Base64::encode(s); }

// the line of the header with the password of this host: JGIT_TOKEN (and JGIT_USER), else ~/.jgit/credentials ("host user token" on a line); "" when none
String auth_header(String host) {
    String token = "";
    String user = "jgit";
    switch Env::get("JGIT_TOKEN") { Option::Some(t): { token = t; } Option::None: { } }
    switch Env::get("JGIT_USER") { Option::Some(u): { if u.len > 0 { user = u; } } Option::None: { } }
    if token.len == 0 {
        String[] ls = read_text_file(home_dir() + "/.jgit/credentials").split("\n");
        for i in 0..ls.len {
            String[] f = ls[i].trim().split(" ");
            if f.len >= 3 && f[0] == host { user = f[1] + ""; token = f[2] + ""; }
        }
    }
    if token.len == 0 { return ""; }
    return "Authorization: Basic " + b64(user + ":" + token) + "\r\n";
}

// ---------------------------------------------------------------- http
struct Resp {
    int code;
    String head;
    String body;
}

Resp http_do(String method, Url u, String path, String extra, String body, int depth) {
    Resp r;
    r.code = 0; r.head = ""; r.body = "";
    if depth > 4 { return r; }
    int h = 0;
    int secv = 0;
    if u.secure { secv = 1; }
    switch Net::http_open(u.host, u.port, secv) {
        Result::Ok(x): { h = x; }
        Result::Err(e): { r.head = e.message + ""; return r; }
    }
    int sec = 0;
    if u.secure { sec = 1; }
    String req = method + " " + path + " HTTP/1.1\r\nHost: " + u.hostport + "\r\nUser-Agent: jgit/" + jgit_version() + "\r\nAccept: */*\r\nConnection: close\r\n" + auth_header(u.host) + extra;
    if method == "POST" { req = req + "Content-Length: " + str(body.len) + "\r\n"; }
    req = req + "\r\n";
    switch Net::http_chan_send(sec, h, req) {
        Result::Ok(n): { }
        Result::Err(e): { Net::http_chan_close(sec, h); r.head = e.message + ""; return r; }
    }
    if method == "POST" {
        // the body in pieces (a pack can be big)
        int at = 0;
        while at < body.len {
            int to = at + 60000;
            if to > body.len { to = body.len; }
            switch Net::http_chan_send(sec, h, body.slice(at, to)) {
                Result::Ok(n): { }
                Result::Err(e): { Net::http_chan_close(sec, h); r.head = e.message + ""; return r; }
            }
            at = to;
        }
    }
    String all = "";
    switch Net::http_read_all(sec, h) {
        Result::Ok(t): { all = t; }
        Result::Err(e): { Net::http_chan_close(sec, h); r.head = e.message + ""; return r; }
    }
    Net::http_chan_close(sec, h);
    int he = all.find("\r\n\r\n");
    if he < 0 { r.head = "no header in the answer"; return r; }
    r.head = all.slice(0, he);
    String raw = all.slice(he + 4, all.len);
    String lh = Net::http_lower_ascii(r.head);
    if r.head.len > 12 && r.head.starts_with("HTTP/") { r.code = r.head.slice(9, 12).to_int(); }
    if r.code == 301 || r.code == 302 || r.code == 303 || r.code == 307 || r.code == 308 {
        int li = lh.find("\r\nlocation:");
        if li >= 0 {
            int le = Net::http_find_from(r.head, "\r\n", li + 11);
            if le < 0 { le = r.head.len; }
            String loc = r.head.slice(li + 11, le).trim();
            Url n;
            String full = loc;
            if loc.starts_with("/") { String sch = "http://"; if u.secure { sch = "https://"; } full = sch + u.hostport + loc; }
            if parse_url(full, @n) {
                String qs = "";
                int qi = full.find("?");
                if qi >= 0 { qs = full.slice(qi, full.len); }
                String np = n.path + qs;
                // a redirect of  /info/refs?service=...  gives the new address of the repository: keep the tail we asked for
                int ii = path.find("/info/refs");
                int ni = np.find("/info/refs");
                if ii >= 0 && ni < 0 { np = n.path + path.slice(ii, path.len); }
                return http_do(method, n, np, extra, body, depth + 1);
            }
        }
    }
    if lh.contains("\r\ntransfer-encoding: chunked") {
        int ok[1];
        r.body = Net::http_unchunk(raw, @ok);
    } else { r.body = raw; }
    return r;
}

// ---------------------------------------------------------------- the lines of the protocol ("pkt-line": four hex digits with the length, then the line; 0000 is a flush)
String pkt(String s) {
    String h = "0123456789abcdef";
    int n = s.len + 4;
    String r = "";
    r.push(h[(n >> 12) & 15]); r.push(h[(n >> 8) & 15]); r.push(h[(n >> 4) & 15]); r.push(h[n & 15]);
    return r + s;
}

// the lines of a text of pkt-lines; a flush is an empty line "" that is marked by the number in `flush` (kept in the list as "\x00FLUSH")
String[] pkt_split(String data) {
    String[] out = arr(16);
    int p = 0;
    while p + 4 <= data.len {
        int n = 0;
        for k in 0..4 { int hv = hexval(data[p + k]); if hv < 0 { return out; } n = n * 16 + hv; }
        if n == 0 { out.push("\x01FLUSH"); p += 4; continue; }
        if n < 4 || p + n > data.len { return out; }
        out.push(data.slice(p + 4, p + n));
        p += n;
    }
    return out;
}

// the references that a server advertises: names, hashes, and the capabilities of the first line
String[] g_ref_name;
String[] g_ref_sha;
String g_caps;

String repo_path(Url u, String tail) { return u.path + tail; }

// info/refs for upload-pack (the fetch) or receive-pack (the push); false with a message when it did not work
bool advertise(Url u, String service) {
    Resp r = http_do("GET", u, repo_path(u, "/info/refs?service=" + service), "", "", 0);
    if r.code == 401 || r.code == 403 { cerr << "jgit: the server wants a password (a token): jgit token HOST TOKEN\n"; return false; }
    if r.code == 404 { cerr << "jgit: there is no repository at " << u.hostport << u.path << "\n"; return false; }
    if r.code != 200 { cerr << "jgit: the server answered " << r.code << " " << r.head.slice(0, 60) << "\n"; return false; }
    String[] ls = pkt_split(r.body);
    g_ref_name = arr(16); g_ref_sha = arr(16); g_caps = "";
    bool first = true;
    for i in 0..ls.len {
        String l = ls[i];
        if l == "\x01FLUSH" || l.starts_with("# service=") { continue; }
        if l.ends_with("\n") { l = l.slice(0, l.len - 1); }
        int z = 0 - 1;
        for q in 0..l.len { if l[q] == 0 && z < 0 { z = q; } }                  // the first zero byte: the capabilities follow it
        if z >= 0 { if first { g_caps = l.slice(z + 1, l.len); } l = l.slice(0, z); }
        first = false;
        if l.len < 42 { continue; }
        g_ref_sha.push(l.slice(0, 40)); g_ref_name.push(l.slice(41, l.len));
    }
    return true;
}

// ---------------------------------------------------------------- the objects of a pack
// writes the objects of a pack as loose objects; the number written, or -1
int unpack_pack(String pack) {
    if pack.len < 32 || !pack.starts_with("PACK") { cerr << "jgit: the answer is not a pack\n"; return 0 - 1; }
    int n = be32(pack, 8);
    int p = 12;
    int[] starts = arr(n + 1);
    String[] kinds = arr(n + 1);
    String[] bodies = arr(n + 1);
    String[] hexes = arr(n + 1);
    for i in 0..n {
        if p >= pack.len { cerr << "jgit: the pack is cut\n"; return 0 - 1; }
        int start = p;
        int c = pack[p] & 255;
        p += 1;
        int type = (c >> 4) & 7;
        int size = c & 15;
        int shift = 4;
        while (c & 128) != 0 { c = pack[p] & 255; p += 1; size = size | ((c & 127) << shift); shift += 7; }
        int base_at = 0 - 1;
        String base_hex = "";
        if type == 6 {
            c = pack[p] & 255; p += 1;
            int off = c & 127;
            while (c & 128) != 0 { c = pack[p] & 255; p += 1; off = ((off + 1) << 7) | (c & 127); }
            base_at = start - off;
        } else if type == 7 {
            base_hex = to_hex(pack.slice(p, p + 20));
            p += 20;
        }
        bool ok = false;
        String data = dfl_inflate_raw(pack, p + 2, pack.len, @ok);
        if !ok { cerr << "jgit: an object of the pack is damaged\n"; return 0 - 1; }
        p = dfl_inf_pos + 4;                                          // after the zlib check number
        String kind = "";
        String body = "";
        if type == 1 { kind = "commit"; body = data; }
        else if type == 2 { kind = "tree"; body = data; }
        else if type == 3 { kind = "blob"; body = data; }
        else if type == 4 { kind = "tag"; body = data; }
        else {
            String bkind = "";
            String bbody = "";
            if type == 6 {
                for k in 0..i { if starts[k] == base_at { bkind = kinds[k]; bbody = bodies[k]; } }
            } else {
                for k in 0..i { if hexes[k] == base_hex { bkind = kinds[k]; bbody = bodies[k]; } }
                if bkind.len == 0 { bbody = read_object(base_hex); bkind = g_kind; }
            }
            if bkind.len == 0 { cerr << "jgit: a delta without its base\n"; return 0 - 1; }
            kind = bkind;
            body = apply_delta(bbody, data);
        }
        starts.push(start); kinds.push(kind); bodies.push(body);
        String hx = write_object(kind, body);
        hexes.push(hx);
    }
    return n;
}

// ---------------------------------------------------------------- fetch
// asks for the objects of the wanted hashes (those that are not here yet) and writes them; the number of objects, or -1
int fetch_objects(Url u, String[] want) {
    String body = "";
    bool first = true;
    for i in 0..want.len {
        String line = "want " + want[i];
        if first { line = line + " ofs-delta agent=jgit/" + jgit_version(); first = false; }
        body = body + pkt(line + "\n");
    }
    body = body + "0000" + pkt("done\n");
    Resp r = http_do("POST", u, repo_path(u, "/git-upload-pack"), "Content-Type: application/x-git-upload-pack-request\r\nAccept: application/x-git-upload-pack-result\r\n", body, 0);
    if r.code != 200 { cerr << "jgit: the server answered " << r.code << " to the request of objects\n"; return 0 - 1; }
    // the answer: a line NAK (or ACK ...), then the pack
    int at = r.body.find("PACK");
    if at < 0 { cerr << "jgit: no pack in the answer\n"; return 0 - 1; }
    return unpack_pack(r.body.slice(at, r.body.len));
}

bool have_object(String hex) { return Fs::exists(obj_path(hex)) || pack_find(hex) >= 0; }

String remote_url(String name) {
    return config_value(read_text_file(g_git + "/config"), "remote \"" + name + "\"", "url");
}

// fetch: the branches of the remote go to refs/remotes/NAME/BRANCH; returns the number of new branch tips
int do_fetch_remote(String name, bool quiet) {
    String us = remote_url(name);
    if us.len == 0 { return fail("there is no remote " + name + " (jgit remote add NAME URL)"); }
    Url u;
    if !parse_url(us, @u) { return fail("this address is not read: " + us + " (https:// or http:// addresses are known)"); }
    if !advertise(u, "git-upload-pack") { return 1; }
    String[] want = arr(8);
    for i in 0..g_ref_name.len {
        if g_ref_name[i].starts_with("refs/heads/") && !have_object(g_ref_sha[i]) {
            bool dup = false;
            for k in 0..want.len { if want[k] == g_ref_sha[i] { dup = true; } }
            if !dup { want.push(g_ref_sha[i] + ""); }
        }
    }
    int got = 0;
    if want.len > 0 {
        got = fetch_objects(u, want);
        if got < 0 { return 1; }
    }
    int moved = 0;
    for i in 0..g_ref_name.len {
        if !g_ref_name[i].starts_with("refs/heads/") { continue; }
        String b = g_ref_name[i].slice(11, g_ref_name[i].len);
        String rf = "refs/remotes/" + name + "/" + b;
        if ref_hash(rf) != g_ref_sha[i] {
            Dir::make_all(Path::parent(g_git + "/" + rf));
            Fs::write_text(g_git + "/" + rf, g_ref_sha[i] + "\n");
            moved += 1;
            if !quiet { cout << " " << b << " -> " << name << "/" << b << "\n"; }
        }
    }
    if !quiet { cout << "fetched " << got << " objects, " << moved << " branches moved\n"; }
    return 0;
}

// the files of a commit are written in the folder and the index is made (the tree of a branch)
bool checkout_commit(String hex) {
    String[] np = arr(8); String[] ns = arr(8); int[] nm = arr(8);
    String tree = commit_tree(hex);
    if tree.len != 40 { return false; }
    tree_files(tree, "", np, ns, nm);
    ix_clear();
    for k in 0..np.len {
        String body = read_object(to_hex(ns[k]));
        if g_kind != "blob" { cerr << "jgit: cannot read " << np[k] << "\n"; return false; }
        String full = g_top + "/" + np[k];
        Dir::make_all(Path::parent(full));
        Fs::write_bytes(full, body);
        if nm[k] == 33261 { Sys::chmod(full.c(), 493); }
        ix_set(np[k], ns[k], nm[k], body.len, mtime_of(full));
    }
    ix_save();
    return true;
}

int do_remote(String[] a) {
    if !find_repo() { return fail("this is not a repository"); }
    String cfg = read_text_file(g_git + "/config");
    if a.len == 2 || a[2] == "-v" {
        String[] ls = cfg.split("\n");
        String cur = "";
        for i in 0..ls.len {
            String ln = ls[i].trim();
            if ln.starts_with("[remote \"") { cur = ln.slice(9, ln.len - 2); }
            else if ln.starts_with("[") { cur = ""; }
            else if cur.len > 0 && ln.starts_with("url") { cout << cur << "\t" << ln.slice(ln.find("=") + 1, ln.len).trim() << "\n"; }
        }
        return 0;
    }
    if a[2] == "add" && a.len >= 5 {
        if remote_url(a[3]).len > 0 { return fail("the remote " + a[3] + " is there already"); }
        Fs::write_text(g_git + "/config", cfg + "[remote \"" + a[3] + "\"]\n\turl = " + a[4] + "\n\tfetch = +refs/heads/*:refs/remotes/" + a[3] + "/*\n");
        cout << "remote " << a[3] << " added\n";
        return 0;
    }
    if (a[2] == "remove" || a[2] == "rm") && a.len >= 4 {
        String[] ls = cfg.split("\n");
        String out = "";
        bool skip = false;
        for i in 0..ls.len {
            String ln = ls[i].trim();
            if ln.starts_with("[") { skip = ln == "[remote \"" + a[3] + "\"]"; }
            if !skip { out = out + ls[i] + "\n"; }
        }
        Fs::write_text(g_git + "/config", out.trim() + "\n");
        cout << "remote " << a[3] << " removed\n";
        return 0;
    }
    return fail("usage: jgit remote [-v] | add NAME URL | remove NAME");
}

int do_clone(String[] a) {
    if a.len < 3 { return fail("usage: jgit clone URL [FOLDER]"); }
    String us = a[2];
    Url u;
    if !parse_url(us, @u) { return fail("this address is not read: " + us + " (https:// addresses are known)"); }
    String dir = "";
    if a.len > 3 { dir = a[3] + ""; }
    else {
        String last = u.path;
        int sl = 0 - 1;
        for i in 0..last.len { if last[i] == '/' { sl = i; } }
        last = last.slice(sl + 1, last.len);
        if last.ends_with(".git") { last = last.slice(0, last.len - 4); }
        dir = last;
    }
    if dir.len == 0 { return fail("name the folder: jgit clone URL FOLDER"); }
    if Fs::exists(dir) {
        Result<String[], Error> er = Dir::list(dir);
        if er.is_ok() {
            String[] ents = er.take();
            if ents.len > 2 { return fail(dir + " is there and not empty"); }
        }
    }
    String[] ia = arr(3);
    ia.push("jgit"); ia.push("init"); ia.push(dir);
    if do_init(ia) != 0 { return 1; }
    Sys::chdir(dir.c());
    if !find_repo() { return fail("cannot enter " + dir); }
    String cfg = read_text_file(g_git + "/config");
    Fs::write_text(g_git + "/config", cfg + "[remote \"origin\"]\n\turl = " + us + "\n\tfetch = +refs/heads/*:refs/remotes/origin/*\n");
    if !advertise(u, "git-upload-pack") { return 1; }
    if g_ref_name.len == 0 { cout << "the repository is empty\n"; return 0; }
    // the branch to bring: HEAD of the server (symref=HEAD:refs/heads/NAME), else main, master, the first
    String branch = "";
    int sy = g_caps.find("symref=HEAD:refs/heads/");
    if sy >= 0 {
        String t = g_caps.slice(sy + 23, g_caps.len);
        int sp = t.find(" ");
        if sp >= 0 { t = t.slice(0, sp); }
        branch = t;
    }
    if branch.len == 0 {
        for i in 0..g_ref_name.len { if g_ref_name[i] == "refs/heads/main" { branch = "main"; } }
        if branch.len == 0 { for i in 0..g_ref_name.len { if g_ref_name[i] == "refs/heads/master" { branch = "master"; } } }
        if branch.len == 0 { for i in 0..g_ref_name.len { if g_ref_name[i].starts_with("refs/heads/") && branch.len == 0 { branch = g_ref_name[i].slice(11, g_ref_name[i].len); } } }
    }
    int rc = do_fetch_remote("origin", true);
    if rc != 0 { return rc; }
    String tip = ref_hash("refs/remotes/origin/" + branch);
    if tip.len != 40 { return fail("the server has no branch " + branch); }
    Fs::write_text(g_git + "/refs/heads/" + branch, tip + "\n");
    Fs::write_text(g_git + "/HEAD", "ref: refs/heads/" + branch + "\n");
    Fs::write_text(g_git + "/config", read_text_file(g_git + "/config") + "[branch \"" + branch + "\"]\n\tremote = origin\n\tmerge = refs/heads/" + branch + "\n");
    if !checkout_commit(tip) { return 1; }
    cout << "cloned " << us << " into " << dir << " (branch " << branch << ")\n";
    return 0;
}

// is a an ancestor of b (or the same)?
bool is_ancestor(String a, String b) {
    String[] todo = arr(8);
    todo.push(b + "");
    String[] seen = arr(16);
    int guard = 0;
    while todo.len > 0 && guard < 100000 {
        guard += 1;
        String c = todo[todo.len - 1];
        todo = drop_last(todo);
        if c == a { return true; }
        bool dup = false;
        for i in 0..seen.len { if seen[i] == c { dup = true; } }
        if dup { continue; }
        seen.push(c + "");
        String body = read_object(c);
        if g_kind != "commit" { continue; }
        String[] ls = body.split("\n");
        for i in 0..ls.len {
            if ls[i].len == 0 { break; }
            if ls[i].starts_with("parent ") { todo.push(ls[i].slice(7, ls[i].len)); }
        }
    }
    return false;
}

String[] drop_last(String[] l) {
    String[] r = arr(l.len);
    for i in 0..(l.len - 1) { r.push(l[i]); }
    return r;
}

int do_pull(String[] a) {
    if !find_repo() { return fail("this is not a repository"); }
    String remote = "origin";
    String br = head_ref();
    if !br.starts_with("refs/heads/") { return fail("not on a branch"); }
    String b = br.slice(11, br.len);
    int rc = do_fetch_remote(remote, true);
    if rc != 0 { return rc; }
    String theirs = ref_hash("refs/remotes/" + remote + "/" + b);
    String mine = head_commit();
    if theirs.len != 40 { return fail("the server has no branch " + b); }
    if theirs == mine { cout << "already up to date\n"; return 0; }
    if mine.len == 40 && is_ancestor(theirs, mine) { cout << "already up to date (you are ahead: jgit push)\n"; return 0; }
    if mine.len == 40 && !is_ancestor(mine, theirs) { return fail("the branches have both changed: a merge is needed and jgit does not make merges yet"); }
    // the files of the working folder must be saved (a fast-forward writes the new files)
    if !ix_load() { return 1; }
    for i in 0..ix_path.len {
        String full = g_top + "/" + ix_path[i];
        if !Fs::exists(full) { continue; }
        Result<String, Error> r = Fs::read_bytes(full);
        if !r.is_ok() { continue; }
        String d = r.take();
        String hb = "blob " + str(d.len);
        hb.push((char)0);
        hb.append(d);
        if sha1_raw(hb) != ix_sha[i] { return fail(ix_path[i] + " has changes that are not saved: commit or undo them first"); }
    }
    // the files that are not in the new tree are removed
    String[] op = arr(8); String[] os = arr(8); int[] om = arr(8);
    if mine.len == 40 { tree_files(commit_tree(mine), "", op, os, om); }
    String[] np = arr(8); String[] ns = arr(8); int[] nm = arr(8);
    tree_files(commit_tree(theirs), "", np, ns, nm);
    for i in 0..op.len {
        bool keep = false;
        for k in 0..np.len { if np[k] == op[i] { keep = true; } }
        if !keep { Fs::remove(g_top + "/" + op[i]); }
    }
    if !checkout_commit(theirs) { return 1; }
    Fs::write_text(g_git + "/" + br, theirs + "\n");
    cout << "moved " << b << " forward to " << theirs.slice(0, 7) << "\n";
    return 0;
}

// ---------------------------------------------------------------- push
// every object that a commit needs: the commit, its tree, the trees below and the files; objects in `have` are left out (and not walked)
void collect_tree(String hex, String[] out, String[] have) {
    for i in 0..have.len { if have[i] == hex { return; } }
    for i in 0..out.len { if out[i] == hex { return; } }
    out.push(hex + "");
    String body = read_object(hex);
    if g_kind != "tree" { return; }
    int p = 0;
    while p < body.len {
        int sp = p;
        while sp < body.len && body[sp] != ' ' { sp += 1; }
        String mode = body.slice(p, sp);
        int z = sp;
        while z < body.len && body[z] != 0 { z += 1; }
        String sha = to_hex(body.slice(z + 1, z + 21));
        p = z + 21;
        if mode == "40000" { collect_tree(sha, out, have); }
        else {
            bool dup = false;
            for i in 0..have.len { if have[i] == sha { dup = true; } }
            for i in 0..out.len { if out[i] == sha { dup = true; } }
            if !dup { out.push(sha); }
        }
    }
}

// all the objects that the remote already has through its branch tip: the commits, their trees and files
void objects_of(String tip, String[] set) {
    String[] todo = arr(8);
    todo.push(tip + "");
    int guard = 0;
    while todo.len > 0 && guard < 20000 {
        guard += 1;
        String c = todo[todo.len - 1];
        todo = drop_last(todo);
        bool dup = false;
        for i in 0..set.len { if set[i] == c { dup = true; } }
        if dup { continue; }
        set.push(c + "");
        String body = read_object(c);
        if g_kind != "commit" { continue; }
        String[] ls = body.split("\n");
        for i in 0..ls.len {
            if ls[i].len == 0 { break; }
            if ls[i].starts_with("parent ") { todo.push(ls[i].slice(7, ls[i].len)); }
            if ls[i].starts_with("tree ") { String[] none = arr(2); collect_tree(ls[i].slice(5, ls[i].len), set, none); }
        }
    }
}

String pack_header(int type, int size) {
    String r = "";
    int c = (type << 4) | (size & 15);
    int rest = size >> 4;
    while rest > 0 { r.push((char)(c | 128)); c = rest & 127; rest = rest >> 7; }
    r.push((char)c);
    return r;
}

String make_pack(String[] hexes) {
    String pk = "PACK";
    put32(pk, 2);
    put32(pk, hexes.len);
    for i in 0..hexes.len {
        String body = read_object(hexes[i]);
        int type = 3;
        if g_kind == "commit" { type = 1; } else if g_kind == "tree" { type = 2; } else if g_kind == "tag" { type = 4; }
        pk.append(pack_header(type, body.len));
        pk.append(zlib_pack(body));
    }
    pk.append(sha1_raw(pk));
    return pk;
}

int do_push(String[] a) {
    if !find_repo() { return fail("this is not a repository"); }
    String remote = "origin";
    if a.len > 2 && !a[2].starts_with("-") { remote = a[2] + ""; }
    String br = head_ref();
    if !br.starts_with("refs/heads/") { return fail("not on a branch"); }
    String b = br.slice(11, br.len);
    String mine = head_commit();
    if mine.len != 40 { return fail("nothing is saved yet: jgit commit first"); }
    String us = remote_url(remote);
    if us.len == 0 { return fail("there is no remote " + remote + " (jgit remote add NAME URL)"); }
    Url u;
    if !parse_url(us, @u) { return fail("this address is not read: " + us); }
    if !advertise(u, "git-receive-pack") { return 1; }
    String old = "0000000000000000000000000000000000000000";
    for i in 0..g_ref_name.len { if g_ref_name[i] == br { old = g_ref_sha[i] + ""; } }
    if old == mine { cout << "everything is up to date\n"; return 0; }
    String[] have = arr(16);
    if old != "0000000000000000000000000000000000000000" {
        if !have_object(old) { return fail("the server has changes that you do not have: jgit pull first"); }
        if !is_ancestor(old, mine) { return fail("the server has changes that you do not have (the branches differ): jgit pull first"); }
        objects_of(old, have);
    } else {
        // a new branch: what the other branches of the server give
        for i in 0..g_ref_name.len { if g_ref_name[i].starts_with("refs/heads/") && have_object(g_ref_sha[i]) { objects_of(g_ref_sha[i], have); } }
    }
    // the new commits: from mine back to what the server has
    String[] send = arr(16);
    String[] todo = arr(8);
    todo.push(mine + "");
    int guard = 0;
    while todo.len > 0 && guard < 20000 {
        guard += 1;
        String c = todo[todo.len - 1];
        todo = drop_last(todo);
        bool known = false;
        for i in 0..have.len { if have[i] == c { known = true; } }
        for i in 0..send.len { if send[i] == c { known = true; } }
        if known { continue; }
        send.push(c + "");
        String body = read_object(c);
        if g_kind != "commit" { continue; }
        String[] ls = body.split("\n");
        for i in 0..ls.len {
            if ls[i].len == 0 { break; }
            if ls[i].starts_with("parent ") { todo.push(ls[i].slice(7, ls[i].len)); }
            if ls[i].starts_with("tree ") { collect_tree(ls[i].slice(5, ls[i].len), send, have); }
        }
    }
    String pack = make_pack(send);
    String line = old + " " + mine + " " + br;
    line.push((char)0);                                              // a zero byte (not in a text: a text ends at it) ends the name; the capabilities follow
    line.append(" report-status agent=jgit/" + jgit_version() + "\n");
    String body = pkt(line) + "0000";
    body.append(pack);
    Resp r = http_do("POST", u, repo_path(u, "/git-receive-pack"), "Content-Type: application/x-git-receive-pack-request\r\nAccept: application/x-git-receive-pack-result\r\n", body, 0);
    if r.code == 401 || r.code == 403 { return fail("the server did not accept the password (a token with the right to write): jgit token HOST TOKEN"); }
    if r.code != 200 { return fail("the server answered " + str(r.code)); }
    String[] st = pkt_split(r.body);
    bool unpacked = false;
    bool refok = false;
    String why = "";
    for i in 0..st.len {
        String l = st[i];
        if l.starts_with("unpack ok") { unpacked = true; }
        if l.starts_with("ok " + br) { refok = true; }
        if l.starts_with("ng ") { why = l.trim(); }
    }
    if !unpacked || !refok {
        if Env::get("JGIT_DEBUG").is_some() { cerr << "answer: " << r.body << "\n"; }
        String more = "";
        if why.len > 0 { more = ": " + why; }
        return fail("the server did not take the branch" + more);
    }
    Dir::make_all(g_git + "/refs/remotes/" + remote);
    Fs::write_text(g_git + "/refs/remotes/" + remote + "/" + b, mine + "\n");
    cout << "pushed " << b << " to " << remote << " (" << send.len << " objects)\n";
    return 0;
}

// the password (a token) of a host: kept in ~/.jgit/credentials, readable by you only
int do_token(String[] a) {
    if a.len < 4 { return fail("usage: jgit token HOST TOKEN [USER]   (for https://github.com make a token at github.com/settings/tokens; USER is free)"); }
    String user = "jgit";
    if a.len > 4 { user = a[4] + ""; }
    String dir = home_dir() + "/.jgit";
    Dir::make_all(dir);
    String file = dir + "/credentials";
    String[] ls = read_text_file(file).split("\n");
    String out = "";
    for i in 0..ls.len {
        String[] f = ls[i].trim().split(" ");
        if f.len >= 3 && f[0] == a[2] { continue; }
        if ls[i].trim().len > 0 { out = out + ls[i].trim() + "\n"; }
    }
    out = out + a[2] + " " + user + " " + a[3] + "\n";
    Fs::write_text(file, out);
    Sys::chmod(file.c(), 384);
    cout << "kept the token for " << a[2] << " in " << file << "\n";
    return 0;
}
