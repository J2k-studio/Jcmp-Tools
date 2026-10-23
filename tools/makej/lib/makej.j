// makej: a build tool that is a library. A build file is an ordinary J2K program:
//
//   #import <makej>
//   int main() {
//       Build b = Build::make();
//       b.program("hello", "src/hello.jk", "");           // jcmp src/hello.jk -o _out/hello
//       b.library("core", "core/core.jk", "-l");          // _out/libcore.so
//       b.step("test", "sh test.sh");                     // any command
//       b.needs("test", "hello");                         // test runs after hello is built
//       return b.run();                                   // makej [target] [-v]; the default target is "all" (every program and library)
//   }
//
// A program or library is built again only when a .jk / .j file of the folder of its main file (and below) is newer than the result.

struct Build {
    String[] names;
    String[] kinds;       // program, library, step
    String[] mains;       // the main file, or the command of a step
    String[] flags;
    String[] needs_of;    // the names this target needs, separated by spaces
    int verbose;
    int dry;              // -n: show what would be done
    String install_to;     // makej install FOLDER
    int jobs;
    String want;
    String outdir;
    String jcmp;
    bool live;            // a terminal and a jcmp that tells the percent: bars while it works
    int live_lines;       // the lines of the bars on the screen now
    int jcmp_j;           // the processes of one jcmp (0: do not say)

    static Build make() {
        Build b;
        b.names = arr(8);
        b.kinds = arr(8);
        b.mains = arr(8);
        b.flags = arr(8);
        b.needs_of = arr(8);
        b.verbose = 0;
        b.want = "all";
        b.install_to = "";
        b.dry = 0;
        b.outdir = "_out";
        b.jcmp = "jcmp";
        b.live = false;
        b.live_lines = 0;
        b.jcmp_j = 0;
        b.jobs = Build::cores();
        String[] a = Env::args();
        int i = 1;
        while i < a.len {
            if a[i] == "-v" { b.verbose = 1; }
            else if a[i] == "-n" { b.dry = 1; b.verbose = 1; }
            else if a[i] == "-j" && i + 1 < a.len { b.jobs = a[i + 1].to_int(); i += 1; }
            else if a[i].starts_with("-j") && a[i].len > 2 { b.jobs = a[i].slice(2, a[i].len).to_int(); }
            else if a[i] == "install" && i + 1 < a.len { b.want = "install"; b.install_to = a[i + 1]; i += 1; }
            else { b.want = a[i]; }
            i += 1;
        }
        if b.jobs < 1 { b.jobs = 1; }
        return b;
    }
    // the number of cores this process may use (Cpus_allowed_list of /proc/self/status: 2-3,5), else the cores that are on, 4 when none can be read
    static int cores() {
        int n = 0;
        Result<String, Error> st = Fs::read_text("/proc/self/status");
        if st.is_ok() {
            String[] lines = st.take().split("\n");
            for i in 0..lines.len {
                if lines[i].starts_with("Cpus_allowed_list:") {
                    String[] parts = lines[i].slice(18, lines[i].len).trim().split(",");
                    for k in 0..parts.len {
                        int dash = parts[k].find("-");
                        if dash > 0 { n += parts[k].slice(dash + 1, parts[k].len).to_int() - parts[k].slice(0, dash).to_int() + 1; }
                        else if parts[k].len > 0 { n += 1; }
                    }
                }
            }
        }
        if n >= 1 { return n; }
        Result<String, Error> r = Fs::read_text("/sys/devices/system/cpu/online");
        switch r {
            Result::Ok(t): {
                String[] parts = t.trim().split(",");
                for i in 0..parts.len {
                    int dash = parts[i].find("-");
                    if dash > 0 { n += parts[i].slice(dash + 1, parts[i].len).to_int() - parts[i].slice(0, dash).to_int() + 1; }
                    else if parts[i].len > 0 { n += 1; }
                }
            }
            Result::Err(e): n = 4;
        }
        if n < 1 { n = 4; }
        return n;
    }
    // read the build file written by hand (the file called makej, a simple TOML):
    //   [program.jemu]            [library.core]              [step.test]
    //   main = "core/jemu.jk"     main = "core/core.jk"       run = "sh tools/run_tests.sh"
    //   flags = ""                flags = "-l"                needs = "jemu"
    //   [makej]
    //   out = "_out"              # the folder of the results; jcmp = "jcmp" is the compiler
    static Build from_file(String path) {
        Build b = Build::make();
        Result<String[], Error> r = Fs::read_lines(path);
        switch r {
            Result::Ok(ls): b.parse(ls);
            Result::Err(e): cerr << "makej: cannot read " << path << "\n";
        }
        return b;
    }
    // the lines of the build file (the lines are only looked at here: they stay with the Result)
    void parse(self, String[] lines) {
        Build^ b = self;
        String kind = "";
        String name = "";
        String main = "";
        String flags = "";
        String needs = "";
        for i in 0..lines.len + 1 {
            String t = "";
            if i < lines.len { t = lines[i].trim(); }
            bool header = t.len > 1 && t[0] == '[';
            if header || i == lines.len {
                if kind.len > 0 && name.len > 0 {
                    b^.add(name, kind, main, flags);
                    if needs.len > 0 { String[] ns = needs.split(" "); for k in 0..ns.len { if ns[k].len > 0 { b^.needs(name, ns[k]); } } }
                }
                kind = ""; name = ""; main = ""; flags = ""; needs = "";
                if header {
                    String h = t.slice(1, t.len - 1).trim();
                    int dot = h.find(".");
                    if dot > 0 { kind = h.slice(0, dot); name = h.slice(dot + 1, h.len); }
                    else { kind = h; }
                }
                continue;
            }
            if t.len == 0 || t[0] == '#' { continue; }
            int eq = t.find("=");
            if eq < 1 { continue; }
            String key = t.slice(0, eq).trim();
            String val = t.slice(eq + 1, t.len).trim();
            if val.len >= 2 && val[0] == '"' {
                int endq = val.len - 1;
                while endq > 0 && val[endq] != '"' { endq -= 1; }
                val = val.slice(1, endq);
            }
            if kind == "makej" {
                if key == "out" { b^.outdir = val; }
                if key == "jcmp" { b^.jcmp = val; }
            } else {
                if key == "main" || key == "run" { main = val; }
                if key == "flags" { flags = val; }
                if key == "needs" { needs = val; }
            }
        }
    }
    void add(self, String name, String kind, String main, String flags) {
        self.names.push(name);
        self.kinds.push(kind);
        self.mains.push(main);
        self.flags.push(flags);
        self.needs_of.push("");
    }
    void program(self, String name, String main, String flags) { self.add(name, "program", main, flags); }
    void library(self, String name, String main, String flags) { self.add(name, "library", main, flags); }
    void step(self, String name, String command) { self.add(name, "step", command, ""); }
    void needs(self, String name, String other) {
        for i in 0..self.names.len {
            if self.names[i] == name { self.needs_of[i] = self.needs_of[i] + other + " "; }
        }
    }
    int find(self, String name) {
        for i in 0..self.names.len { if self.names[i] == name { return i; } }
        return 0 - 1;
    }
    // the file that a target makes
    String out_of(self, int i) {
        if self.kinds[i] == "library" { return self.outdir + "/lib" + self.names[i] + ".so"; }
        return self.outdir + "/" + self.names[i];
    }
    // the newest modification time (seconds) of the .jk / .j files in a folder and below
    static int newest(String dir) {
        int best = 0;
        Result<String[], Error> r = Dir::list(dir);
        switch r {
            Result::Ok(names): {
                for i in 0..names.len {
                    String p = Path::join(dir, names[i]);
                    if Dir::exists(p) {
                        int t = Build::newest(p);
                        if t > best { best = t; }
                    } else if names[i].ends_with(".jk") || names[i].ends_with(".j") {
                        int t2 = Build::mtime(p);
                        if t2 > best { best = t2; }
                    }
                }
            }
            Result::Err(e): { }
        }
        return best;
    }
    // the modification time of a file in seconds since 1970, 0 if it is not there
    static int mtime(String path) {
        int st[24];
        if Sys::stat(path.c(), @st) < 0 { return 0; }
        return st[11];
    }
    int sh(self, String command) {
        if self.verbose == 1 { cout << "  $ " << command << "\n"; }
        String[] args = arr(2);
        args.push("-c");
        args.push(command);
        Result<int, Error> r = Proc::run("sh", args);
        switch r {
            Result::Ok(code): return code;
            Result::Err(e): { cerr << "makej: cannot run sh: " << e.message << "\n"; return 127; }
        }
        return 127;
    }
    String out_text(self, int i) { return Path::join(self.outdir, ".out_" + self.names[i]); }

    // where jcmp writes how far the compile of a target is
    String prog_file(self, int i) { return Path::join(self.outdir, ".prog_" + self.names[i]); }

    // does this jcmp tell the percent (-progress) and take -j N? (an old one would stop with "unknown option")
    String jcmp_help(self) {
        String[] a = arr(2);
        a.push("-help");
        Result<String, Error> r = Proc::output(self.jcmp, a);
        if r.is_ok() { return r.take(); }
        return "";
    }

    // [||||||||      ] 62%
    static String bar(int pct, int width) {
        if pct < 0 { pct = 0; }
        if pct > 100 { pct = 100; }
        int filled = pct * width / 100;
        String r = "[";
        for k in 0..width { if k < filled { r = r + "|"; } else { r = r + " "; } }
        r = r + "] ";
        if pct < 100 { r = r + " "; }
        if pct < 10 { r = r + " "; }
        return r + str(pct) + "%";
    }

    // the bars of the targets that run now (and of the cores of a compile), made again in place
    void draw_live(self, int^ state, int^ t_start) {
        int n = self.names.len;
        String f = "";
        if self.live_lines > 0 { f = f + "\e[" + str(self.live_lines) + "A"; }
        int lines = 0;
        for i in 0..n {
            if state[i] != 1 { continue; }
            int pct = 0;
            String stage = "";
            String cores = "";
            if self.kinds[i] != "step" {
                String file = self.prog_file(i);
                if Fs::exists(file) {
                    Result<String, Error> r = Fs::read_text(file);
                    if r.is_ok() {
                        String[] w = r.take().trim().split(" ");
                        if w.len >= 3 { pct = w[0].to_int(); stage = w[1] + ""; cores = w[2] + ""; }
                    }
                }
                f = f + "\e[K  " + Build::bar(pct, 24) + "  " + self.names[i] + "  " + stage + "\n";
                lines += 1;
                if cores.len > 1 {
                    String[] cs = cores.split(",");
                    String row = "";
                    for k in 0..cs.len { row = row + "core " + str(k + 1) + " " + Build::bar(cs[k].to_int(), 10) + "  "; }
                    f = f + "\e[K      " + row + "\n";
                    lines += 1;
                }
            } else {
                int secs = (Time::now_ms() - t_start[i]) / 1000;
                f = f + "\e[K  running  " + self.names[i] + "  " + str(secs) + " s\n";
                lines += 1;
            }
        }
        f = f + "\e[J";
        self.live_lines = lines;
        cout << f;
    }

    // take the bars off the screen (before a line of text is written)
    void clear_live(self) {
        if self.live_lines > 0 { cout << "\e[" << self.live_lines << "A\e[J"; }
        self.live_lines = 0;
    }

    // the command that makes a target ("" when the result is up to date)
    String command_of(self, int i) {
        if self.kinds[i] == "step" { return self.mains[i]; }
        String out = self.out_of(i);
        String src = Path::parent(self.mains[i]);
        if src.len == 0 { src = "."; }
        int newest = Build::newest(src);
        if Build::mtime(out) > newest && newest > 0 { return ""; }
        String cmd = self.jcmp + " " + self.mains[i] + " -o " + out;
        if self.flags[i].len > 0 { cmd = cmd + " " + self.flags[i]; }
        if self.live { cmd = cmd + " -progress '" + self.prog_file(i) + "'"; }
        if self.jcmp_j > 0 && !self.flags[i].contains("-j") { cmd = cmd + " -j " + str(self.jcmp_j); }
        if self.live { cmd = cmd + " > '" + self.out_text(i) + "' 2>&1"; }          // what jcmp says is shown after the bars are gone
        return cmd;
    }
    // mark a target and what it needs as wanted
    void want_it(self, String name, int^ wanted) {
        int i = self.find(name);
        if i < 0 {
            cerr << "makej: there is no target '" << name << "'. The targets: ";
            for k in 0..self.names.len { cerr << self.names[k] << " "; }
            cerr << "(makej list shows them)\n";
            wanted[self.names.len] = 1;
            return;
        }
        if wanted[i] == 1 { return; }
        wanted[i] = 1;
        String[] ns = self.needs_of[i].split(" ");
        for k in 0..ns.len {
            if ns[k].len > 0 { self.want_it(ns[k], wanted); }
        }
    }
    // the targets run at the same time (up to jobs processes), each as soon as what it needs is done
    int run(self) {
        int n = self.names.len;
        if self.want == "list" {                                   // makej list: the targets and what they need
            for i in 0..n {
                String needs = self.needs_of[i].trim();
                cout << self.names[i] << "\t" << self.kinds[i] << "\t" << self.mains[i];
                if self.flags[i].len > 0 { cout << "  [" << self.flags[i] << "]"; }
                if needs.len > 0 { cout << "  needs: " << needs; }
                cout << "\n";
            }
            return 0;
        }
        if self.want == "clean" {                                  // makej clean: the folder of the results goes
            if Dir::exists(self.outdir) { self.sh("rm -rf '" + self.outdir + "'"); cout << "makej: removed " << self.outdir << "\n"; }
            else { cout << "makej: nothing to clean\n"; }
            return 0;
        }
        if self.want == "install" {                                // makej install FOLDER: build everything, then copy the results there
            String keep = self.want;
            self.want = "all";
            int rc0 = self.run();
            self.want = keep;
            if rc0 != 0 { return rc0; }
            if self.install_to.len == 0 { cerr << "makej: usage: makej install FOLDER\n"; return 2; }
            Dir::make_all(self.install_to);
            for i in 0..n {
                if self.kinds[i] != "step" { self.sh("cp '" + self.out_of(i) + "' '" + self.install_to + "/'"); cout << "makej: installed " << self.names[i] << " in " << self.install_to << "\n"; }
            }
            return 0;
        }
        int started_at = Time::now_ms();
        int^ wanted = (int^)Mem::alloc0(8 * (n + 1));
        int^ state = (int^)Mem::alloc0(8 * (n + 1));      // 0 waiting, 1 running, 2 done, 3 failed
        int^ pid_of = (int^)Mem::alloc0(8 * (n + 1));
        if self.want == "all" {
            for i in 0..n { if self.kinds[i] != "step" { self.want_it(self.names[i], wanted); } }
        } else {
            self.want_it(self.want, wanted);
        }
        if wanted[n] == 1 { return 2; }
        int^ t_start = (int^)Mem::alloc0(8 * (n + 1));
        // bars: a terminal, no -n, and a jcmp that tells the percent; the processes of one jcmp share the cores that the programs built at the same time do not use
        if self.dry == 0 && Sys::isatty(1) == 0 {
            String hp = self.jcmp_help();
            if hp.contains("-progress") { self.live = true; }
            if hp.contains(" -j N") {
                int progs = 0;
                for i in 0..n { if wanted[i] == 1 && self.kinds[i] != "step" { progs += 1; } }
                int at_once = progs;
                if at_once > self.jobs { at_once = self.jobs; }
                if at_once < 1 { at_once = 1; }
                self.jcmp_j = self.jobs / at_once;
                if self.jcmp_j < 1 { self.jcmp_j = 1; }
            }
        }
        int running = 0;
        bool failed = false;
        bool progress = true;
        while progress {
            progress = false;
            // start every target that is ready
            for i in 0..n {
                if wanted[i] == 1 && state[i] == 0 && !failed && running < self.jobs {
                    bool ready = true;
                    String[] ns = self.needs_of[i].split(" ");
                    for k in 0..ns.len {
                        if ns[k].len > 0 {
                            int j = self.find(ns[k]);
                            if j < 0 || state[j] != 2 { ready = false; }
                        }
                    }
                    if ready {
                        String cmd = self.command_of(i);
                        if cmd.len == 0 {
                            if self.verbose == 1 { cout << "makej: " << self.names[i] << " is up to date\n"; }
                            state[i] = 2;
                            progress = true;
                        } else {
                            if !self.live {
                                if self.kinds[i] == "step" { cout << "makej: " << self.names[i] << "\n"; } else { cout << "makej: building " << self.names[i] << "\n"; }
                            }
                            if self.verbose == 1 { self.clear_live(); cout << "  $ " << cmd << "\n"; }
                            if self.live { Fs::remove(self.prog_file(i)); }
                            t_start[i] = Time::now_ms();
                            if self.kinds[i] != "step" { Dir::make_all(self.outdir); }
                            String[] args = arr(2);
                            args.push("-c");
                            args.push(cmd);
                            if self.dry == 1 {
                                state[i] = 2;
                                progress = true;
                            } else {
                                pid_of[i] = Proc::launch("sh", args, 0 - 1);
                                state[i] = 1;
                                running += 1;
                                progress = true;
                            }
                        }
                    }
                }
            }
            // wait for one of them
            if running > 0 {
                int status = 0;
                int done_pid = 0;
                if self.live {
                    while done_pid <= 0 {
                        done_pid = Sys::call(260, 0 - 1, (int)@status, 1, 0, 0, 0);       // wait4 with WNOHANG
                        if done_pid == 0 { self.draw_live(state, t_start); Time::sleep_ms(80); }
                    }
                } else {
                    done_pid = Sys::wait(0 - 1, @status);
                }
                for i in 0..n {
                    if state[i] == 1 && pid_of[i] == done_pid {
                        running -= 1;
                        int code = (status >> 8) & 255;
                        if (status & 127) != 0 { code = 128 + (status & 127); }
                        if self.live {
                            self.clear_live();
                            if self.kinds[i] != "step" {
                                String of = self.out_text(i);
                                if Fs::exists(of) {
                                    Result<String, Error> orr = Fs::read_text(of);
                                    if orr.is_ok() { String said = orr.take(); if said.len > 0 { if code == 0 { cout << said; } else { cerr << said; } } }
                                    Fs::remove(of);
                                }
                            }
                        }
                        if code == 0 {
                            state[i] = 2;
                            if self.live {
                                int ms = Time::now_ms() - t_start[i];
                                String what = "built";
                                if self.kinds[i] == "step" { what = "done"; }
                                cout << "  " << Build::bar(100, 24) << "  " << self.names[i] << "  " << what << " in " << ms / 1000 << "." << (ms % 1000) / 100 << " s\n";
                                Fs::remove(self.prog_file(i));
                            }
                        } else {
                            state[i] = 3;
                            failed = true;
                            cerr << "makej: " << self.names[i] << " failed (exit code " << code << ")\n";
                        }
                    }
                }
                progress = true;
            }
        }
        int rc = 0;
        for i in 0..n {
            if wanted[i] == 1 && state[i] != 2 {
                rc = 1;
                if state[i] == 0 && !failed { cerr << "makej: " << self.names[i] << " cannot start: a needed target does not exist or the needs go round in a circle\n"; }
            }
        }
        Mem::free(wanted);
        Mem::free(state);
        Mem::free(pid_of);
        Mem::free(t_start);
        if self.live { self.clear_live(); }
        int secs10 = (Time::now_ms() - started_at) / 100;
        if rc == 0 { cout << "makej: done in " << secs10 / 10 << "." << secs10 % 10 << " s\n"; }
        return rc;
    }
}
