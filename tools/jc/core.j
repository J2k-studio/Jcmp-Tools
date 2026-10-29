// core.j: what jget and jc share: the HTTPS client (TLS 1.3), downloads with a progress bar and checks, tar, small helpers. (jget is the program that downloads; jc installs the tools and the libraries with it.)


int g_quiet;                 // -q: no progress bar
int g_exec;                  // -x: make the downloaded file executable

// the error output (the language has no cerr yet)
void err(String m) {
    Sys::write(2, m.c(), m.len);
}

bool is_tty() {
    return Sys::isatty(2) == 0;
}

// a name is letters, digits and _ only: it becomes a file name, so no / and no ..
bool name_ok(String n) {
    if n.len == 0 || n.len > 60 { return false; }
    for i in 0..n.len {
        int c = n[i];
        bool good = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
        if !good { return false; }
    }
    return true;
}

// run a program and give its exit code (127: it was not found or could not start)
int run_prog(String cmd, String[] args) {
    switch Proc::run(cmd, args) {
        Result::Ok(code): return code;
        Result::Err(e): return 127;
    }
    return 127;
}

// the name of the file for an address: the last part of the path, without ? and #; index.html when there is none
String name_of(String url) {
    String u = url;
    int q = u.find("?");
    if q >= 0 { u = u.slice(0, q); }
    int h = u.find("#");
    if h >= 0 { u = u.slice(0, h); }
    int scheme = u.find("://");
    if scheme >= 0 { u = u.slice(scheme + 3, u.len); }
    int slash = u.find("/");
    if slash < 0 { return "index.html"; }
    String path = u.slice(slash, u.len);
    int last = 0;
    for i in 0..path.len {
        if path[i] == '/' { last = i + 1; }
    }
    String n = url_decode(path.slice(last, path.len));
    if n.len == 0 || n == "." || n == ".." { return "index.html"; }
    return n;
}

int hex_digit(int c) {
    if c >= '0' && c <= '9' { return c - '0'; }
    if c >= 'a' && c <= 'f' { return c - 'a' + 10; }
    if c >= 'A' && c <= 'F' { return c - 'A' + 10; }
    return -1;
}

// %20 -> a space, %E0%B8... -> the letters; a / or a zero byte in it becomes _ (the name stays one file name)
String url_decode(String s) {
    String r = "";
    int i = 0;
    while i < s.len {
        if s[i] == '%' && i + 2 < s.len && hex_digit(s[i + 1] & 255) >= 0 && hex_digit(s[i + 2] & 255) >= 0 {
            int c = hex_digit(s[i + 1] & 255) * 16 + hex_digit(s[i + 2] & 255);
            if c == '/' || c == 0 { c = '_'; }
            r.push((char)c);
            i += 3;
        } else { r.push(s[i]); i += 1; }
    }
    return r;
}

// move a finished file into place (a rename: the file is whole or it is not there)
bool put_in_place(String part, String to) {
    int r = Sys::rename(part.c(), to.c());
    if r < 0 {
        err("jget: cannot write " + to + ": " + Error::reason(r) + "\n");
        Sys::unlink(part.c());
        return false;
    }
    return true;
}

// curl, or wget when there is no curl; the file is written to to.part and renamed when it is whole. false (with a message) when it cannot
bool download_external(String address, String to, bool quiet) {
    bool show = !quiet && is_tty() && to != "-";
    String target = to + ".part";
    String[] a = arr(0);
    a.push("-fL");
    if show { a.push("--progress-bar"); } else { a.push("-sS"); }
    if to != "-" {
        a.push("-o");
        a.push(target);
    }
    a.push(address);
    int code = run_prog("curl", a);
    if code == 127 {
        String[] w = arr(0);
        if !show { w.push("-q"); }
        w.push("-O");
        if to == "-" { w.push("-"); } else { w.push(target); }
        w.push(address);
        code = run_prog("wget", w);
        if code == 127 {
            err("jget: neither curl nor wget was found; jget fetches http:// and https:// addresses by itself, but this one failed and the other kinds of address need curl or wget: " + address + "\n");
            return false;
        }
    }
    if code != 0 {
        if to != "-" { Sys::unlink(target.c()); }
        err("jget: cannot fetch " + address + " (exit code " + str(code) + ")\n");
        return false;
    }
    if to == "-" { return true; }
    return put_in_place(target, to);
}

// a refusal because of the certificate or the proof of the key: curl would not be asked then (the answer is "no")
bool security_refusal(String why) {
    return why.contains("certificate") || why.contains("not trusted") || why.contains("did not prove");
}

// fetch one address; to = "-" writes it to the screen. false (with a message) when it cannot
bool download_one(String address, String to, bool quiet) {
    String native_err = "";
    if address.starts_with("http://") || address.starts_with("https://") {
        if to == "-" {
            switch Net::http.try_get(address) {
                Result::Ok(body): { Sys::write(1, body.c(), body.len); return true; }
                Result::Err(e): { native_err = e.message; }
            }
        } else {
            int show = 1;
            if quiet { show = 0; }
            switch Net::http.try_download(address, to, show) {
                Result::Ok(n): { return true; }
                Result::Err(e): { native_err = e.message; }
            }
        }
        // the server answered with an error (curl would get the same answer), or the certificate was refused
        if native_err.starts_with("HTTP ") || security_refusal(native_err) {
            err("jget: " + native_err + "\n");
            return false;
        }
    }
    // other addresses (file://, ftp://), and a failure of the native client that curl or wget may do better (a server with an older TLS)
    if download_external(address, to, quiet) { return true; }
    if native_err.len > 0 { err("jget: " + native_err + "\n"); }
    return false;
}

// spec = one address, or several separated by | (the same file on several servers): the first that works
bool download(String spec, String to, bool quiet) {
    String[] list = spec.split("|");
    for i in 0..list.len {
        if list[i].trim().len > 0 {
            if download_one(list[i].trim(), to, quiet) { return true; }
        }
    }
    return false;
}

bool make_dir(String dir) {
    switch Dir::make_all(dir) {
        Result::Ok(x): return true;
        Result::Err(e): { err("jget: cannot make the folder " + dir + ": " + e.message + "\n"); return false; }
    }
    return false;
}

// the path of this program
String self_path() {
    char buf[300];
    int n = Sys::readlink("/proc/self/exe", @buf, 290);
    String r = "";
    if n <= 0 { return r; }
    for i in 0..n { r.push(buf[i]); }
    return r;
}

String default_bin_dir() {
    switch Env::get("PREFIX") {
        Option::Some(p): { if p.len > 0 { return p + "/bin"; } }
        Option::None: { }
    }
    switch Env::get("HOME") {
        Option::Some(h): return h + "/.local/bin";
        Option::None: return "./bin";
    }
    return "./bin";
}

// copy the file `from` to `to` (to.new first, then renamed), with the permissions of an executable; any bytes
bool install_file(String from, String to) {
    int in = Sys::open_read(from.c());
    if in < 0 { err("jget: cannot read " + from + ": " + Error::reason(in) + "\n"); return false; }
    String tmp = to + ".new";
    int out = Sys::open(tmp.c(), 577, 493);
    if out < 0 {
        Sys::close(in);
        err("jget: cannot write " + tmp + ": " + Error::reason(out) + "\n");
        return false;
    }
    char buf[8192];
    bool ok = true;
    while true {
        int n = Sys::read(in, @buf, 8192);
        if n < 0 { ok = false; break; }
        if n == 0 { break; }
        int off = 0;
        while off < n {
            int w = Sys::write(out, @buf + off, n - off);
            if w <= 0 { ok = false; break; }
            off += w;
        }
        if !ok { break; }
    }
    Sys::close(in);
    Sys::close(out);
    if !ok {
        Sys::unlink(tmp.c());
        err("jget: cannot copy " + from + "\n");
        return false;
    }
    Sys::chmod(tmp.c(), 493);
    return put_in_place(tmp, to);
}

// ---- tar files (no compression): the files that belong to a tool, such as the library of the compiler
bool read_exact(int fd, char^ buf, int n) {
    int got = 0;
    while got < n {
        int r = Sys::read(fd, buf + got, n - got);
        if r <= 0 { return false; }
        got += r;
    }
    return true;
}

int tar_number(char^ p, int len) {
    int v = 0;
    for i in 0..len {
        int c = p[i] & 255;
        if c >= '0' && c <= '7' { v = v * 8 + (c - '0'); } else if v > 0 { break; }
    }
    return v;
}

// puts the files of the tar into the folder dir; a name with .. or a name that starts with / is refused
// a tar that is packed with gzip (the files of a tool, a .tar.gz): unpacked next to itself first, then read as a tar
bool untar(String path, String dir) {
    int g = Sys::open_read(path.c());
    if g < 0 { err("jget: cannot read " + path + "\n"); return false; }
    char magic[2];
    int got = Sys::read(g, @magic, 2);
    Sys::close(g);
    if got == 2 && (magic[0] & 255) == 31 && (magic[1] & 255) == 139 {
        Result<String, Error> rz = Fs::read_bytes(path);
        if !rz.is_ok() { err("jget: cannot read " + path + "\n"); return false; }
        bool zok = false;
        String plain = Gzip::unpack(rz.take(), @zok);
        if !zok { err("jget: the gzip file " + path + " is damaged\n"); return false; }
        String tmp = path + ".plain";
        if !Fs::write_bytes(tmp, plain).is_ok() { err("jget: cannot write " + tmp + "\n"); return false; }
        plain = "";
        bool good = untar_plain(tmp, dir);
        Fs::remove(tmp);
        return good;
    }
    return untar_plain(path, dir);
}

String tar_names;                                                   // the names that untar_plain put in place, one per line (when tar_record)
bool tar_record;

bool untar_plain(String path, String dir) {
    int fd = Sys::open_read(path.c());
    if fd < 0 { err("jget: cannot read " + path + "\n"); return false; }
    char h[512];
    char blk[4096];
    bool ok = true;
    String longname = "";                                           // from a GNU long name entry (L), used by the next entry
    while ok {
        if !read_exact(fd, @h, 512) { break; }
        if h[0] == 0 { break; }
        String name = "";
        for i in 0..100 { if h[i] != 0 { name.push(h[i]); } else { break; } }
        String prefix = "";
        if h[257] == 'u' && h[258] == 's' && h[259] == 't' {
            for i in 345..500 { if h[i] != 0 { prefix.push(h[i]); } else { break; } }
        }
        if prefix.len > 0 { name = prefix + "/" + name; }
        int size = tar_number(@h + 124, 12);
        int kind = h[156] & 255;
        if kind == 'L' || kind == 'K' {                              // GNU long name / long link target: the text is in the data
            String text = "";
            int tleft = size;
            while tleft > 0 && ok {
                int n = tleft;
                if n > 4096 { n = 4096; }
                if !read_exact(fd, @blk, n) { ok = false; break; }
                for i in 0..n { if blk[i] != 0 { text.push(blk[i]); } }
                tleft -= n;
            }
            int tpad = (512 - size % 512) % 512;
            if tpad > 0 && ok { if !read_exact(fd, @blk, tpad) { ok = false; } }
            if kind == 'L' { longname = text; }
            continue;
        }
        if longname.len > 0 { name = longname; longname = ""; }
        bool bad = name.len == 0 || name[0] == '/';
        for i in 0..name.len { if name[i] == '.' && i + 1 < name.len && name[i + 1] == '.' { bad = true; } }
        if bad { err("jget: a file name in the tar is not allowed: " + name + "\n"); ok = false; break; }
        String full = dir + "/" + name;
        if tar_record && kind != '5' { tar_names += name + "\n"; }
        if kind == '5' || name[name.len - 1] == '/' {
            if !make_dir(full) { ok = false; }
        } else if kind == '0' || kind == 0 {
            int slash = 0 - 1;
            for i in 0..full.len { if full[i] == '/' { slash = i; } }
            if slash > 0 { make_dir(full.slice(0, slash)); }
            int out = Sys::open_write(full.c());
            if out < 0 { err("jget: cannot write " + full + "\n"); ok = false; break; }
            int left = size;
            while left > 0 {
                int n = left;
                if n > 4096 { n = 4096; }
                if !read_exact(fd, @blk, n) { ok = false; break; }
                Sys::write(out, @blk, n);
                left -= n;
            }
            Sys::close(out);
            int mode = tar_number(@h + 100, 8);
            if (mode & 64) != 0 { Sys::chmod(full.c(), 493); }          // the x bit of the tar: a program stays a program (0755)
            int pad = (512 - size % 512) % 512;
            if pad > 0 && ok { if !read_exact(fd, @blk, pad) { ok = false; } }
        } else if kind == '2' || kind == '1' {                       // a symbolic link, a hard link
            String target = "";
            for i in 157..257 { if h[i] != 0 { target.push(h[i]); } else { break; } }
            int slash2 = 0 - 1;
            for i in 0..full.len { if full[i] == '/' { slash2 = i; } }
            if slash2 > 0 { make_dir(full.slice(0, slash2)); }
            Sys::unlink(full.c());
            int lr = 0;
            if kind == '2' {
                // a package of Jcmp-pkg (checked by its sha256) may point to a path of the prefix
                if target.len == 0 || (target[0] == '/' && !tar_record) { err("jget: a link in the tar is not allowed: " + name + "\n"); ok = false; break; }
                lr = Sys::call(36, (int)target.c(), -100, (int)full.c(), 0, 0, 0);
            } else {
                String from = dir + "/" + target;
                lr = Sys::call(37, -100, (int)from.c(), -100, (int)full.c(), 0, 0);
                if lr < 0 && install_file(from, full) { lr = 0; }          // a system that refuses hard links (Android): a copy
            }
            if lr < 0 { err("jget: cannot make the link " + full + ": " + Error::reason(lr) + "\n"); ok = false; break; }
        } else {
            int skip = (size + 511) / 512 * 512;                    // another kind of entry (a link ...): skipped
            while skip > 0 {
                int n = skip;
                if n > 4096 { n = 4096; }
                if !read_exact(fd, @blk, n) { ok = false; break; }
                skip -= n;
            }
        }
    }
    Sys::close(fd);
    return ok;
}

void remove_tree(String path) {
    if Dir::exists(path) {
        switch Dir::list(path) {
            Result::Ok(names): { for i in 0..names.len { remove_tree(path + "/" + names[i]); } }
            Result::Err(e): { }
        }
        Dir::remove(path);
    } else { Fs::remove(path); }
}
