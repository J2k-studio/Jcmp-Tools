// manage.j: the tools and the libraries: the lists, the newest versions, install with a SHA-256 check, update, remove. (jc uses it: it was part of jget before jget 1.0.0.)
String lib_dir() {
    switch Env::get("JGET_LIB") {
        Option::Some(d): return d;
        Option::None: { }
    }
    switch Env::get("HOME") {
        Option::Some(h): return h + "/.j2k/Library";
        Option::None: return "./Library";
    }
    return "./Library";
}

String default_index() { return "https://raw.githubusercontent.com/J2k-studio/Jcmp-libs/main/index.txt"; }

// the addresses of the index, in the order to try
String[] index_addresses() {
    String spec = default_index();
    switch Env::get("JGET_INDEX") {
        Option::Some(u): { if u.trim().len > 0 { spec = u; } }
        Option::None: { }
    }
    String[] all = spec.split(" ");
    String[] r = arr(0);
    for i in 0..all.len {
        String a = all[i].trim();
        if a.len > 0 { r.push(a); }
    }
    return r;
}

// the text of the index, from the first address that works
String fetch_index(String dir) {
    String[] where = index_addresses();
    String tmp = dir + "/.index.tmp";
    for i in 0..where.len {
        if download_one(where[i], tmp, true) {
            switch Fs::read_text(tmp) {
                Result::Ok(t): { Fs::remove(tmp); return t; }
                Result::Err(e): { err("jc: cannot read the index: " + e.message + "\n"); }
            }
        }
    }
    err("jc: the index of libraries could not be fetched; set JGET_INDEX to the address (or the path) of an index\n");
    return "";
}

// the line of the index for `name`, split in four; an empty list when there is none
String[] find_entry(String index, String name) {
    String[] lines = index.split("\n");
    for i in 0..lines.len {
        String line = lines[i].trim();
        if line.len == 0 || line.starts_with("#") { continue; }
        String[] w = line.split(" ");
        if w.len >= 4 && w[0] == name { return w; }
    }
    String[] none = arr(0);
    return none;
}

// the libraries that come with the compiler (its folder Library): #import <name> needs no install
bool builtin_name(String n) {
    String[] b = "stdlib std core number text files system time data crypto net math cpu vector matrix".split(" ");
    for i in 0..b.len {
        if b[i] == n { return true; }
    }
    return false;
}

int cmd_install(String name) {
    if name == "gfx" {
        // the graphics library is made of canvas and screen
        int a = cmd_install("canvas");
        int b = cmd_install("screen");
        if a != 0 { return a; }
        return b;
    }
    if builtin_name(name) {
        cout << name << " is part of the standard library (installed with the compiler): write  #import <" << name << ">  in your program; nothing to install" << nl;
        return 0;
    }
    if !name_ok(name) {
        err("jc: '" + name + "' is not a library name (letters, digits and _ only)\n");
        return 1;
    }
    String dir = lib_dir();
    if !make_dir(dir) { return 1; }
    String index = fetch_index(dir);
    if index.len == 0 { return 1; }
    String[] e = find_entry(index, name);
    if e.len < 4 {
        err("jc: the index has no library named '" + name + "' (try: jc lib list)\n");
        return 1;
    }
    String tmp = dir + "/." + name + ".tmp";
    if !download(e[2], tmp, g_quiet == 1) { return 1; }
    switch Sha256::file(tmp) {
        Result::Ok(h): {
            if h != e[3] {
                Fs::remove(tmp);
                err("jc: the checksum of " + name + " does not match the index, nothing was installed\n");
                err("  index: " + e[3] + "\n");
                err("  file : " + h + "\n");
                return 1;
            }
        }
        Result::Err(er): {
            err("jc: cannot check the file: " + er.message + "\n");
            return 1;
        }
    }
    String target = dir + "/" + name + ".j";
    switch Fs::rename(tmp, target) {
        Result::Ok(x): { cout << "installed " << name << " " << e[1] << " in " << target << nl; return 0; }
        Result::Err(er): { err("jc: cannot install: " + er.message + "\n"); return 1; }
    }
    return 1;
}

int cmd_remove(String name) {
    if !name_ok(name) {
        err("jc: '" + name + "' is not a library name\n");
        return 1;
    }
    String target = lib_dir() + "/" + name + ".j";
    if !Fs::exists(target) {
        err("jc: " + name + " is not installed\n");
        return 1;
    }
    switch Fs::remove(target) {
        Result::Ok(x): { cout << "removed " << name << nl; return 0; }
        Result::Err(er): { err("jc: cannot remove: " + er.message + "\n"); return 1; }
    }
    return 1;
}

int cmd_list() {
    String dir = lib_dir();
    if !make_dir(dir) { return 1; }
    String index = fetch_index(dir);
    if index.len == 0 { return 1; }
    String[] lines = index.split("\n");
    for i in 0..lines.len {
        String line = lines[i].trim();
        if line.len == 0 || line.starts_with("#") { continue; }
        String[] w = line.split(" ");
        if w.len < 4 { continue; }
        String mark = " ";
        if Fs::exists(dir + "/" + w[0] + ".j") { mark = "*"; }
        cout << mark << " " << w[0] << " " << w[1] << nl;
    }
    return 0;
}

int cmd_installed() {
    String dir = lib_dir();
    switch Dir::list(dir) {
        Result::Ok(names): {
            for i in 0..names.len {
                if names[i].ends_with(".j") && !names[i].starts_with(".") {
                    cout << names[i].slice(0, names[i].len - 2) << nl;
                }
            }
            return 0;
        }
        Result::Err(er): { cout << "(no libraries installed)" << nl; return 0; }
    }
    return 0;
}

// jc tools | jc install NAME ... : the tools of Jcmp-Tools (jsh, jbox, coderin, makej ...), put next to jget, checked with their SHA-256
// where the files of Jcmp-Tools are: the repository (raw) and the releases; JCMPTOOLS_RAW and JCMPTOOLS_DL name others (a mirror, the tests)
String tools_raw() {
    switch Env::get("JCMPTOOLS_RAW") { Option::Some(v): { if v.len > 0 { return v; } } Option::None: { } }
    return "https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main";
}

String tools_dl() {
    switch Env::get("JCMPTOOLS_DL") { Option::Some(v): { if v.len > 0 { return v; } } Option::None: { } }
    return "https://github.com/J2k-studio/Jcmp-Tools/releases/download";
}

// ---- jc update / unstall
// is version a newer than version b (numbers with dots; 2026.10.21 and 3.14.0.3 work too)
bool tool_ver_newer(String a, String b) {
    String[] x = a.split(".");
    String[] y = b.split(".");
    int n = x.len;
    if y.len > n { n = y.len; }
    for i in 0..n {
        int p = 0;
        int q = 0;
        if i < x.len { p = x[i].to_int(); }
        if i < y.len { q = y[i].to_int(); }
        if p > q { return true; }
        if p < q { return false; }
    }
    return false;
}

// the version of an installed tool: the marker .NAME.version that jget wrote, else what NAME --version says; "" when it is not installed
String tool_installed_version(String dir, String name) {
    if !Fs::exists(dir + "/" + name) { return ""; }
    String marker = dir + "/." + name + ".version";
    if Fs::exists(marker) {
        switch Fs::read_text(marker) {
            Result::Ok(t): { if t.trim().len > 0 { return t.trim() + ""; } }
            Result::Err(e): { }
        }
    }
    String[] va = arr(1);
    va.push("--version");
    switch Proc::output(dir + "/" + name, va) {
        Result::Ok(t): {
            String[] w = t.trim().split(" ");
            if w.len >= 2 && w[0] == name { return w[1] + ""; }
        }
        Result::Err(e): { }
    }
    return "unknown";
}

// the newest versions of all the tools in one request (versions.txt: lines  NAME VERSION)
String tool_versions_text(String dir) {
    String f = dir + "/.versions.txt";
    if !download(tools_raw() + "/versions.txt", f, true) { return ""; }
    String t = "";
    switch Fs::read_text(f) {
        Result::Ok(x): { t = x; }
        Result::Err(e): { }
    }
    Fs::remove(f);
    return t;
}

String tool_latest(String vtext, String name) {
    String[] ls = vtext.split("\n");
    for i in 0..ls.len {
        String[] w = ls[i].trim().split(" ");
        if w.len >= 2 && w[0] == name { return w[1] + ""; }
    }
    return "";
}

// jc install unstall NAME ...: the program of a tool and the files that came with it
int tool_unstall(String[] av, int at, String dir) {
    int rc = 0;
    for k in at..av.len {
        String name = av[k];
        if name == "jget" || name == "jc" { err("jc: " + name + " stays: jc uses it (delete the file by hand if you want to)\n"); rc = 1; continue; }
        if name == "jsh" { err("jc: jsh is the shell: it stays (jc update brings it up to date)\n"); rc = 1; continue; }
        if !Fs::exists(dir + "/" + name) { err("jc: " + name + " is not installed here\n"); rc = 1; continue; }
        String[] extra = arr(4);
        if name == "python" { extra.push("python3"); extra.push("pip"); extra.push("pip3"); extra.push("python-android"); }
        else if name == "neuron" { extra.push("xr"); extra.push("xaiorin"); }
        else if name == "yt-dlp" { extra.push("yt-dlp.pyz"); }
        else if name == "jcmp" { extra.push("Library"); extra.push("coderin-extensions"); }
        for i in 0..extra.len { if Fs::exists(dir + "/" + extra[i]) { remove_tree(dir + "/" + extra[i]); } }
        remove_tree(dir + "/" + name);
        Fs::remove(dir + "/." + name + ".version");
        cout << "removed " << name << nl;
    }
    return rc;
}

int cmd_tool(String[] av, int at) {
    String me = self_path();
    if me.len == 0 { err("jc: cannot find where this program is\n"); return 1; }
    String dir = default_bin_dir();
    int slash = 0 - 1;
    for i in 0..me.len { if me[i] == '/' { slash = i; } }
    if slash > 0 { dir = me.slice(0, slash); }                      // the tools go where jget is
    String list = me + ".tools";
    if !download(tools_raw() + "/tools.txt", list, true) { return 1; }
    String text = "";
    switch Fs::read_text(list) {
        Result::Ok(t): { text = t; }
        Result::Err(e): { }
    }
    Fs::remove(list);
    if av.len <= at || av[at] == "list" {
        String[] ls = text.split("\n");
        for i in 0..ls.len {
            if ls[i].len == 0 || ls[i][0] == '#' { continue; }
            String[] parts = ls[i].split("|");
            if parts.len >= 2 { cout << "  " << parts[0] << "   " << parts[1] << nl; }
        }
        if av.len <= at { cout << "jc install NAME installs one (more than one: jc install jsh jbox coderin)" << nl; }
        return 0;
    }
    if av[at] == "unstall" || av[at] == "uninstall" || av[at] == "remove" { return tool_unstall(av, at + 1, dir); }
    // `update` (and the old `all`) = jsh and the installed tools that have a newer version; with -n only the list
    String[] wanted = arr(8);
    bool want_update = false;
    bool dry = false;
    for k in at..av.len {
        if av[k] == "update" || av[k] == "all" { want_update = true; }
        else if av[k] == "-n" { dry = true; }
        else { wanted.push(av[k]); }
    }
    if want_update {
        String vtext = tool_versions_text(dir);
        String[] tl = text.split("\n");
        int shown = 0;
        // jsh first, then the others in the order of the list
        String[] order = arr(16);
        order.push("jsh");
        for i in 0..tl.len {
            if tl[i].len == 0 || tl[i][0] == '#' { continue; }
            String[] parts = tl[i].split("|");
            if parts.len >= 2 && parts[0] != "jsh" { order.push(parts[0] + ""); }
        }
        for i in 0..order.len {
            String name = order[i];
            String have = tool_installed_version(dir, name);
            if have.len == 0 && name != "jsh" { continue; }                                      // not installed: update does not add tools (jsh is the base)
            if have == "unknown" && name != "jsh" { continue; }                                  // a file that jget did not install (no marker, no NAME X.Y.Z): leave it alone
            String lat = tool_latest(vtext, name);
            if lat.len == 0 {                                                                    // no versions.txt: ask the tool itself
                String lv0 = dir + "/." + name + ".latest";
                if download(tools_raw() + "/tools/" + name + "/LATEST", lv0, true) {
                    switch Fs::read_text(lv0) { Result::Ok(t): { lat = t.trim() + ""; } Result::Err(e): { } }
                    Fs::remove(lv0);
                }
            }
            if lat.len == 0 { continue; }
            bool newer = have.len == 0 || have == "unknown" || tool_ver_newer(lat, have);
            if !newer { continue; }
            String from = have;
            if from.len == 0 { from = "(not installed)"; }
            cout << name << ": " << from << " -> " << lat << nl;
            wanted.push(name);
            shown += 1;
        }
        if shown == 0 { cout << "everything is up to date" << nl; return 0; }
        if dry { cout << "(jc update installs them)" << nl; return 0; }
    }
    int rc = 0;
    for k in 0..wanted.len {
        String name = wanted[k];
        bool known = false;
        String[] ls = text.split("\n");
        for i in 0..ls.len { if ls[i].starts_with(name + "|") { known = true; } }
        if !known {                                                  // not a tool: maybe a package of Jcmp-pkg (git, clang ...)
            String[] pw = arr(4);
            pw.push("jc");
            pw.push("pkg");
            pw.push("install");
            pw.push(name + "");
            if cmd_pkg(pw) != 0 { err("jc: there is no tool or package '" + name + "' (jc tools, jc pkg search)\n"); rc = 1; }
            continue;
        }
        String lv = dir + "/." + name + ".latest";
        if !download(tools_raw() + "/tools/" + name + "/LATEST", lv, true) { rc = 1; continue; }
        String ver = "";
        switch Fs::read_text(lv) {
            Result::Ok(t): { ver = t.trim(); }
            Result::Err(e): { }
        }
        Fs::remove(lv);
        if ver.len == 0 { err("jc: cannot read the newest version of " + name + "\n"); rc = 1; continue; }
        String base = tools_dl() + "/" + name + "-v" + ver;
        String tmp = dir + "/." + name + ".new";
        String sums = dir + "/." + name + ".sums";
        if !download(base + "/SHA256SUMS", sums, true) { rc = 1; continue; }
        if !download(base + "/" + name, tmp, g_quiet == 1) { Fs::remove(sums); rc = 1; continue; }
        String want = "";
        switch Fs::read_text(sums) {
            Result::Ok(t): {
                String[] sl = t.split("\n");
                for i in 0..sl.len {
                    String[] w = sl[i].trim().split(" ");
                    if w.len >= 2 && w[w.len - 1] == name { want = w[0]; }
                    String tarname = name + "-files.tar";
                    if w.len >= 2 && w[w.len - 1] == tarname { Fs::write_text(sums + ".keep", w[0]); }
                }
            }
            Result::Err(e): { }
        }
        Fs::remove(sums);
        String have = "";
        switch Sha256::file(tmp) {
            Result::Ok(h): { have = h; }
            Result::Err(e): { }
        }
        if want.len == 0 || want != have {
            Fs::remove(tmp);
            Fs::remove(sums + ".keep");
            err("jc: the checksum of " + name + " does not match, nothing was installed\n");
            rc = 1;
            continue;
        }
        Sys::chmod(tmp.c(), 493);
        if !put_in_place(tmp, dir + "/" + name) { rc = 1; continue; }
        // the files of the tool (the library of the compiler): NAME-files.tar, when it is in the release; it goes into the folder of the tool
        String extra = "";
        switch Fs::read_text(sums + ".keep") {
            Result::Ok(t): { extra = t; }
            Result::Err(e): { }
        }
        if extra.len > 0 {
            String tarfile = dir + "/." + name + ".files.tar";
            if download(base + "/" + name + "-files.tar", tarfile, g_quiet == 1) {
                String thave = "";
                switch Sha256::file(tarfile) {
                    Result::Ok(h): { thave = h; }
                    Result::Err(e): { }
                }
                if thave == extra { if !untar(tarfile, dir) { rc = 1; } } else { err("jc: the checksum of the files of " + name + " does not match\n"); rc = 1; }
                Fs::remove(tarfile);
            } else { rc = 1; }
            Fs::remove(sums + ".keep");
        }
        Fs::write_text(dir + "/." + name + ".version", ver);
        cout << "installed " << name << " " << ver << " in " << dir << nl;
        if name == "jbox" || name == "zipj" || name == "tarj" || name == "jamanager" {                                             // its commands as links next to it
            String[] ja = arr(2);
            ja.push("--install");
            ja.push(dir);
            Proc::run(dir + "/" + name, ja);
        }
    }
    return rc;
}

int cmd_library(String[] av, int at) {
    if av.len <= at { return usage(); }
    String cmd = av[at];
    if cmd == "list" { return cmd_list(); }
    if cmd == "installed" { return cmd_installed(); }
    if cmd == "install" || cmd == "remove" || cmd == "unstall" || cmd == "uninstall" {
        if av.len <= at + 1 { return usage(); }
        String name = av[at + 1];
        if cmd == "install" { return cmd_install(name); }
        return cmd_remove(name);
    }
    return usage();
}
