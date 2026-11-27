// exapi 0.1.0: what the app exshell can do, for your programs:  #import <exapi>  then  Ex::notify("done", "the build passed");
// Needs jcmp 1.2.41.4 or newer, and the app exshell 0.1.89 or newer.
// The app listens on a socket in its own folder (the variable EXSHELL_API): only the programs of exshell can reach it, in a screen program and in
// the background alike. Outside exshell every call answers that there is no app (Ex::inside() is false).
//
//   Ex::toast(text)  Ex::notify(title, text)  Ex::copy(text)  Ex::paste()  Ex::vibrate(ms)  Ex::torch(on)  Ex::battery()  Ex::charging()
//   Ex::open(file or link)  Ex::share(file)  Ex::share_text(text)  Ex::pick("image" or "file")  Ex::apk(file)  Ex::apps()  Ex::launch(name)
//   Ex::call(number)  Ex::play(file)  Ex::pause()  Ex::resume()  Ex::stop()  Ex::tab(command)  Ex::set(key, value)  Ex::get(key)
//   Ex::awake(on)  Ex::exit_app()  Ex::version()  Ex::system(command)  Ex::output(command)  Ex::send("TOOL ARGS")  Ex::request(words)
//
// License: MPL-2.0
#import <stdlib>

struct ExResult {
    bool ok;                  // the call did what was asked
    bool missing;             // send: there is no such tool
    String text;              // what the app or the tool said
    String hint;              // send: how to get a missing tool
}

ExResult ex_result(bool ok, String text) {
    ExResult r;
    r.ok = ok;
    r.missing = false;
    r.text = text + "";
    r.hint = "";
    return r;
}

// the words of a line: spaces part them, "..." and '...' keep spaces together
String[] ex_words(String line) {
    String[] out = arr(8);
    String w = "";
    bool have = false;
    char quote = (char)0;
    for i in 0..line.len {
        char c = line[i];
        if quote != (char)0 {
            if c == quote { quote = (char)0; } else { w.push(c); }
        } else if c == '"' || c == (char)39 { quote = c; have = true; }
        else if c == ' ' || c == (char)9 {
            if have { out.push(w + ""); w = ""; have = false; }
        } else { w.push(c); have = true; }
    }
    if have { out.push(w + ""); }
    return out;
}

// the whole path of a file, also for the drive names of jsh (u:/...); the name itself when it cannot be opened, and links stay links
String ex_path(String name) {
    if name.contains("://") { return name + ""; }
    i64 fd = Sys::open_read(name.c());
    if fd < 0 { return name + ""; }
    String link = "/proc/self/fd/" + stg(fd);
    char buf[4096];
    i64 n = Sys::readlink(link.c(), (char^)@buf, 4095);
    Sys::close(fd);
    if n <= 0 { return name + ""; }
    buf[n] = 0;
    String r = (char^)@buf;
    return r + "";
}

struct Ex {
    // is this program running in exshell (is the app there to be asked)
    static bool inside() { return Env::get("EXSHELL_API").or("").len > 0; }

    // one request to the app: the words, and what came back. The protocol: the words parted by a zero byte, then the end of the sending side;
    // the answer is one letter (0 done, 1 not done) and a text.
    static ExResult request(String[] words) {
        String path = Env::get("EXSHELL_API").or("");
        if path.len == 0 { return ex_result(false, "this is not exshell (or the app is too old: ex app update)"); }
        char addr[112];
        for i in 0..112 { addr[i] = 0; }
        if path.len > 106 { return ex_result(false, "the path of the app is too long"); }
        addr[0] = 1;                                                 // AF_UNIX
        for i in 0..path.len { addr[2 + i] = path[i]; }
        i64 fd = Sys::call(198, 1, 1, 0, 0, 0, 0);                   // socket(AF_UNIX, SOCK_STREAM)
        if fd < 0 { return ex_result(false, "no socket"); }
        if Sys::connect(fd, @addr, 2 + path.len + 1) < 0 { Sys::close(fd); return ex_result(false, "the app does not answer (is exshell open?)"); }
        String all = "";
        for i in 0..words.len { if i > 0 { all.push((char)0); } all.append(words[i]); }
        i64 off = 0;
        while off < all.len {
            i64 n = Sys::write(fd, all.c() + off, all.len - off);
            if n <= 0 { Sys::close(fd); return ex_result(false, "the request could not be sent"); }
            off += n;
        }
        Sys::call(210, fd, 1, 0, 0, 0, 0);                           // shutdown: no more to send
        String got = "";
        char buf[4096];
        while true {
            i64 n = Sys::read(fd, @buf, 4096);
            if n <= 0 { break; }
            for i in 0..n { got.push(buf[i]); }
        }
        Sys::close(fd);
        if got.len == 0 { return ex_result(false, "the app gave no answer"); }
        return ex_result(got[0] == '0', got.slice(1, got.len));
    }

    // a request of one, two or three words
    static ExResult ask1(String a) { String[] w = arr(2); w.push(a + ""); return Ex::request(w); }
    static ExResult ask2(String a, String b) { String[] w = arr(2); w.push(a + ""); w.push(b + ""); return Ex::request(w); }
    static ExResult ask3(String a, String b, String c) { String[] w = arr(4); w.push(a + ""); w.push(b + ""); w.push(c + ""); return Ex::request(w); }

    static String version() { ExResult r = Ex::ask1("version"); if !r.ok { return ""; } return r.text + ""; }
    static bool toast(String text) { ExResult r = Ex::ask2("toast", text); return r.ok; }
    static bool notify(String title, String text) { ExResult r = Ex::ask3("notify", title, text); return r.ok; }
    static bool copy(String text) { ExResult r = Ex::ask2("copy", text); return r.ok; }
    static String paste() { ExResult r = Ex::ask1("paste"); if !r.ok { return ""; } return r.text + ""; }
    static bool vibrate(i64 ms) { ExResult r = Ex::ask2("vibrate", stg(ms)); return r.ok; }
    static bool torch(bool on) { String v = "off"; if on { v = "on"; } ExResult r = Ex::ask2("torch", v); return r.ok; }
    // the battery in percent, -1 when it is not known
    static i64 battery() { ExResult r = Ex::ask1("battery"); if !r.ok { return -1; } String[] w = r.text.split(" "); if w.len == 0 { return -1; } return w[0].to_int(); }
    static bool charging() { ExResult r = Ex::ask1("battery"); return r.ok && r.text.ends_with(" charging"); }
    static bool open(String what) { ExResult r = Ex::ask2("open", ex_path(what)); return r.ok; }
    static bool share(String file) { ExResult r = Ex::ask2("share", ex_path(file)); return r.ok; }
    static bool share_text(String text) { ExResult r = Ex::ask2("send", text); return r.ok; }
    // the person chooses a file on the phone: the path of a copy of it, "" when nothing was chosen
    static String pick(String kind) { ExResult r = Ex::ask2("pick", kind); if !r.ok { return ""; } return r.text + ""; }
    static bool apk(String file) { ExResult r = Ex::ask2("apk", ex_path(file)); return r.ok; }
    static String apps() { ExResult r = Ex::ask1("apps"); if !r.ok { return ""; } return r.text + ""; }
    static bool launch(String name) { ExResult r = Ex::ask2("launch", name); return r.ok; }
    static bool call(String number) { ExResult r = Ex::ask2("call", number); return r.ok; }          // opens the dialler; it does not call by itself
    static bool play(String file) { ExResult r = Ex::ask2("play", ex_path(file)); return r.ok; }
    static bool pause() { ExResult r = Ex::ask1("pause"); return r.ok; }
    static bool resume() { ExResult r = Ex::ask1("resume"); return r.ok; }
    static bool stop() { ExResult r = Ex::ask1("stop"); return r.ok; }
    static bool tab(String command) { ExResult r = Ex::ask2("tab", command); return r.ok; }
    static bool set(String key, String value) { ExResult r = Ex::ask3("set", key, value); return r.ok; }
    static String get(String key) { ExResult r = Ex::ask2("get", key); if !r.ok { return ""; } return r.text + ""; }
    static bool awake(bool on) { String v = "off"; if on { v = "on"; } ExResult r = Ex::ask2("awake", v); return r.ok; }
    static bool exit_app() { ExResult r = Ex::ask1("exit"); return r.ok; }

    // a command of the shell, like system() of C: it runs in jsh on this terminal; the result is its exit code
    static i64 system(String command) {
        String[] a = arr(2);
        a.push("-c");
        a.push(command + "");
        Result<i64, Error> r = Proc::run(ex_shell(), a);
        if r.is_err() { return 127; }
        return r.take();
    }

    // what a command of the shell prints
    static String output(String command) {
        String[] a = arr(2);
        a.push("-c");
        a.push(command + "");
        Result<String, Error> r = Proc::output(ex_shell(), a);
        if r.is_err() { return ""; }
        return r.take();
    }

    // "TOOL ARGUMENTS": the tool is looked for among the installed programs and run; what it printed (also its errors) comes back. A tool that
    // is not there: missing, with the command that gets it.
    static ExResult send(String line) {
        String[] w = ex_words(line);
        if w.len == 0 { return ex_result(false, "nothing to send"); }
        String tool = w[0] + "";
        String found = ex_find(tool);
        if found.len == 0 {
            ExResult m = ex_result(false, "there is no tool " + tool);
            m.missing = true;
            m.hint = "ex install " + tool;
            return m;
        }
        String[] a = arr(4);
        a.push("-c");
        a.push("\"$0\" \"$@\" 2>&1");
        a.push(found + "");
        for i in 1..w.len { a.push(w[i] + ""); }
        i64 fds[1];
        if Sys::pipe(@fds) < 0 { return ex_result(false, "no pipe"); }
        i64 rfd = fds[0] & 4294967295;
        i64 wfd = fds[0] >> 32;
        i64 pid = Proc::launch("/system/bin/sh", a, wfd);
        Sys::close(wfd);
        if pid < 0 { Sys::close(rfd); return ex_result(false, tool + " could not be started"); }
        String text = "";
        char buf[4096];
        i64 n = Sys::read(rfd, @buf, 4096);
        while n > 0 {
            for i in 0..n { text.push(buf[i]); }
            n = Sys::read(rfd, @buf, 4096);
        }
        Sys::close(rfd);
        return ex_result(Proc::finish(pid) == 0, text);
    }
}

// the shell: jsh of the PATH, else the one of the system
String ex_shell() {
    String j = ex_find("jsh");
    if j.len > 0 { return j; }
    return "/system/bin/sh";
}

// the file of a program of the PATH, "" when there is none
String ex_find(String name) {
    if name.contains("/") { if Fs::exists(name) { return name + ""; } return ""; }
    String path = Env::get("PATH").or("");
    String[] dirs = path.split(":");
    for i in 0..dirs.len {
        if dirs[i].len == 0 { continue; }
        String f = dirs[i] + "/" + name;
        if Fs::exists(f) { return f; }
    }
    return "";
}
