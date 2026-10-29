// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// pkg: the packages of Jcmp-pkg (git, clang, python ...): programs built for the prefix of Jaric. index.json lists them;
// a package is a .tar.gz of the folder usr/ (with links); it is unpacked into the folder that holds usr/ (PREFIX without /usr),
// and the names it put there are written to  usr/var/lib/jcpkg/NAME.list  so it can be removed.

String pkg_index_address() {
    return env_or("JC_PKG_INDEX", "https://raw.githubusercontent.com/J2k-studio/Jcmp-pkg/main/index.json");
}

// the folder that holds usr/ : JC_PKG_ROOT, else PREFIX without its last part, else ~/.jaric
String pkg_root() {
    String r = env_or("JC_PKG_ROOT", "");
    if r.len > 0 { return r; }
    String p = env_or("PREFIX", "");
    if p.ends_with("/usr") { return p.slice(0, p.len - 4); }
    return env_or("HOME", ".") + "/.jaric";
}

String pkg_state() { return pkg_root() + "/usr/var/lib/jcpkg"; }

// the text of a file ("" when it cannot be read)
String pkg_read(String path) {
    String text = "";
    switch Fs::read_bytes(path) {
        Result::Ok(t): { text = t; }
        Result::Err(e): { }
    }
    return text;
}

// the text of index.json: fetched, or read when the address is a file
String pkg_fetch_index() {
    String addr = pkg_index_address();
    if !addr.starts_with("http") {
        String local = pkg_read(addr);
        if local.len == 0 { err("jc: cannot read the package index " + addr + "\n"); }
        return local;
    }
    String tmp = pkg_root() + "/.index.tmp";
    make_dir(pkg_root());
    if !download(addr, tmp, true) { err("jc: cannot fetch the package index " + addr + "\n"); return ""; }
    String fetched = pkg_read(tmp);
    Fs::remove(tmp);
    return fetched;
}

// "version|url|sha256|dep,dep|size" of the package, "" when the index has none of that name
String pkg_entry(String index, String name) {
    String found = "";
    Result<JsonDoc, Error> pj = Json::parse(index);
    switch pj {
        Result::Ok(d): {
            int n = d.len(0);
            for i in 0..n {
                int e = d.at(0, i);
                int nn = d.get(e, "name");
                if nn >= 0 {
                    if d.text(nn) == name {
                        String deps = "";
                        int dn = d.get(e, "depends");
                        if dn >= 0 {
                            for k in 0..d.len(dn) {
                                if deps.len > 0 { deps += ","; }
                                deps += d.text(d.at(dn, k));
                            }
                        }
                        String ver = "";
                        String url = "";
                        String sha = "";
                        int vn = d.get(e, "version");
                        if vn >= 0 { ver = d.text(vn); }
                        int un = d.get(e, "url");
                        if un >= 0 { url = d.text(un); }
                        int sn = d.get(e, "sha256");
                        if sn >= 0 { sha = d.text(sn); }
                        found = ver + "|" + url + "|" + sha + "|" + deps;
                    }
                }
            }
        }
        Result::Err(e): { err("jc: the package index is not valid JSON: " + e.message + "\n"); }
    }
    return found;
}

bool pkg_installed(String name) { return Fs::exists(pkg_state() + "/" + name + ".list"); }

int pkg_install(String index, String name, int depth) {
    if pkg_installed(name) { return 0; }
    if depth > 20 { err("jc: the dependencies of " + name + " go too deep\n"); return 1; }
    String line = pkg_entry(index, name);
    if line.len == 0 { err("jc: no package named " + name + " (jc pkg search)\n"); return 1; }
    String[] f = line.split("|");
    String[] deps = f[3].split(",");
    for i in 0..deps.len {
        if deps[i].len > 0 {
            if pkg_install(index, deps[i] + "", depth + 1) != 0 { return 1; }
        }
    }
    String root = pkg_root();
    make_dir(pkg_state());
    String tmp = root + "/.pkg-" + name + ".tar.gz";
    cout << "jc: " << name << " " << f[0] << "\n";
    if !download(f[1], tmp, true) { err("jc: cannot download " + name + "\n"); return 1; }
    switch Sha256::file(tmp) {
        Result::Ok(h): {
            if h != f[2] {
                Fs::remove(tmp);
                err("jc: the checksum of " + name + " does not match the index, nothing was installed\n");
                return 1;
            }
        }
        Result::Err(e): { err("jc: cannot check " + name + ": " + e.message + "\n"); return 1; }
    }
    tar_names = "";
    tar_record = true;
    bool ok = untar(tmp, root);
    tar_record = false;
    Fs::remove(tmp);
    if !ok { err("jc: cannot unpack " + name + "\n"); return 1; }
    String list = f[0] + "\n" + tar_names;
    Result<int, Error> wr = Fs::write_bytes(pkg_state() + "/" + name + ".list", list);
    if !wr.is_ok() { err("jc: cannot write the list of " + name + "\n"); return 1; }
    return 0;
}

int pkg_remove(String name) {
    String lp = pkg_state() + "/" + name + ".list";
    String listed = pkg_read(lp);
    if listed.len == 0 { err("jc: " + name + " is not installed\n"); return 1; }
    String[] lines = listed.split("\n");
    String root = pkg_root();
    for i in 1..lines.len {
        if lines[i].len > 0 && !lines[i].contains("..") { Sys::unlink((root + "/" + lines[i]).c()); }
    }
    Fs::remove(lp);
    cout << "jc: removed " << name << "\n";
    return 0;
}

// "NAME  VERSION" of one file of the state folder
String pkg_line(String st, String file) {
    String pname = file.slice(0, file.len - 5) + "";
    String body = pkg_read(st + "/" + file);
    String v = "";
    for k in 0..body.len { if body[k] == '\n' { break; } v.push(body[k]); }
    return pname + "  " + v;
}

int pkg_list() {
    String st = pkg_state();
    if !Dir::exists(st) { return 0; }
    switch Dir::list(st) {
        Result::Ok(names): {
            String[] mine = arr(names.len + 1);                          // copies first: reading a file must not touch the names
            for i in 0..names.len { if names[i].ends_with(".list") { mine.push(names[i] + ""); } }
            for i in 0..mine.len { cout << pkg_line(st, mine[i] + "") << "\n"; }
        }
        Result::Err(e): { }
    }
    return 0;
}

int pkg_search(String index, String word) {
    Result<JsonDoc, Error> pj = Json::parse(index);
    switch pj {
        Result::Ok(d): {
            for i in 0..d.len(0) {
                int e = d.at(0, i);
                int nn = d.get(e, "name");
                int vn = d.get(e, "version");
                if nn >= 0 && vn >= 0 {
                    String nm = d.text(nn);
                    if word.len == 0 || nm.contains(word) { cout << nm << "  " << d.text(vn) << "\n"; }
                }
            }
        }
        Result::Err(e): { err("jc: the package index is not valid JSON\n"); return 1; }
    }
    return 0;
}

// the installed packages that have another version in the index: removed and installed again (dry: only shown)
int pkg_update(String index, bool dry) {
    String st = pkg_state();
    if !Dir::exists(st) { cout << "no packages installed\n"; return 0; }
    String[] mine = arr(8);
    switch Dir::list(st) {
        Result::Ok(names): { for i in 0..names.len { if names[i].ends_with(".list") { mine.push(names[i] + ""); } } }
        Result::Err(e): { }
    }
    int shown = 0;
    int rc = 0;
    for i in 0..mine.len {
        String line = pkg_line(st, mine[i] + "");
        String[] pv = line.split("  ");
        String name = pv[0] + "";
        String have = pv[1] + "";
        String[] f = pkg_entry(index, name).split("|");
        String want = f[0] + "";
        if want.len == 0 || want == have { continue; }
        cout << name << ": " << have << " -> " << want << "\n";
        shown += 1;
        if dry { continue; }
        if pkg_remove(name) != 0 { rc = 1; continue; }
        if pkg_install(index, name, 0) != 0 { rc = 1; }
    }
    if shown == 0 { cout << "the packages are up to date\n"; }
    return rc;
}

// jc pkg install NAME... | remove NAME... | list | search [WORD]
int cmd_pkg(String[] a) {
    if a.len < 3 { err("usage: jc pkg install NAME | remove NAME | update [-n] | list | search [WORD]\n"); return 1; }
    String sub = a[2] + "";
    if sub == "list" { return pkg_list(); }
    if sub == "remove" && a.len >= 4 {
        for i in 3..a.len { if pkg_remove(a[i] + "") != 0 { return 1; } }
        return 0;
    }
    if sub == "install" || sub == "search" || sub == "update" {
        String index = pkg_fetch_index();
        if index.len == 0 { return 1; }
        if sub == "search" {
            String w = "";
            if a.len >= 4 { w = a[3] + ""; }
            return pkg_search(index, w);
        }
        if sub == "update" { return pkg_update(index, a.len >= 4 && a[3] == "-n"); }
        if a.len < 4 { err("usage: jc pkg install NAME\n"); return 1; }
        for i in 3..a.len { if pkg_install(index, a[i] + "", 0) != 0 { return 1; } }
        return 0;
    }
    err("usage: jc pkg install NAME | remove NAME | update [-n] | list | search [WORD]\n");
    return 1;
}
