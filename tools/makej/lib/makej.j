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
    int jobs;
    String want;
    String outdir;
    String jcmp;

    static Build make() {
        Build b;
        b.names = arr(8);
        b.kinds = arr(8);
        b.mains = arr(8);
        b.flags = arr(8);
        b.needs_of = arr(8);
        b.verbose = 0;
        b.want = "all";
        b.outdir = "_out";
        b.jcmp = "jcmp";
        b.jobs = Build::cores();
        String[] a = Env::args();
        int i = 1;
        while i < a.len {
            if a[i] == "-v" { b.verbose = 1; }
            else if a[i] == "-j" && i + 1 < a.len { b.jobs = a[i + 1].to_int(); i += 1; }
            else if a[i].starts_with("-j") && a[i].len > 2 { b.jobs = a[i].slice(2, a[i].len).to_int(); }
            else { b.want = a[i]; }
            i += 1;
        }
        if b.jobs < 1 { b.jobs = 1; }
        return b;
    }
    // the number of cores that are on (the file /sys/devices/system/cpu/online: 0-7 or 0-3,6), 4 when it cannot be read
    static int cores() {
        Result<String, Error> r = Fs::read_text("/sys/devices/system/cpu/online");
        int n = 0;
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
        return cmd;
    }
    // mark a target and what it needs as wanted
    void want_it(self, String name, int^ wanted) {
        int i = self.find(name);
        if i < 0 { cerr << "makej: there is no target '" << name << "'\n"; wanted[self.names.len] = 1; return; }
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
        int^ wanted = (int^)Mem::alloc0(8 * (n + 1));
        int^ state = (int^)Mem::alloc0(8 * (n + 1));      // 0 waiting, 1 running, 2 done, 3 failed
        int^ pid_of = (int^)Mem::alloc0(8 * (n + 1));
        if self.want == "all" {
            for i in 0..n { if self.kinds[i] != "step" { self.want_it(self.names[i], wanted); } }
        } else {
            self.want_it(self.want, wanted);
        }
        if wanted[n] == 1 { return 2; }
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
                            if self.kinds[i] == "step" { cout << "makej: " << self.names[i] << "\n"; } else { cout << "makej: building " << self.names[i] << "\n"; }
                            if self.verbose == 1 { cout << "  $ " << cmd << "\n"; }
                            if self.kinds[i] != "step" { Dir::make_all(self.outdir); }
                            String[] args = arr(2);
                            args.push("-c");
                            args.push(cmd);
                            pid_of[i] = Proc::launch("sh", args, 0 - 1);
                            state[i] = 1;
                            running += 1;
                            progress = true;
                        }
                    }
                }
            }
            // wait for one of them
            if running > 0 {
                int status = 0;
                int done_pid = Sys::wait(0 - 1, @status);
                for i in 0..n {
                    if state[i] == 1 && pid_of[i] == done_pid {
                        running -= 1;
                        int code = (status >> 8) & 255;
                        if (status & 127) != 0 { code = 128 + (status & 127); }
                        if code == 0 { state[i] = 2; }
                        else {
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
        if rc == 0 { cout << "makej: done\n"; }
        return rc;
    }
}
