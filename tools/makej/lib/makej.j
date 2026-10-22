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
        String[] a = Env::args();
        for i in 1..a.len {
            if a[i] == "-v" { b.verbose = 1; }
            else { b.want = a[i]; }
        }
        return b;
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
    // make one target (its needs first); 0 is success
    int make_one(self, String name, int^ done) {
        int i = self.find(name);
        if i < 0 { cerr << "makej: there is no target '" << name << "'\n"; return 2; }
        if done[i] == 1 { return 0; }
        done[i] = 1;
        String[] ns = self.needs_of[i].split(" ");
        for k in 0..ns.len {
            if ns[k].len > 0 {
                int rc = self.make_one(ns[k], done);
                if rc != 0 { return rc; }
            }
        }
        if self.kinds[i] == "step" {
            cout << "makej: " << name << "\n";
            return self.sh(self.mains[i]);
        }
        String out = self.out_of(i);
        String src = Path::parent(self.mains[i]);
        if src.len == 0 { src = "."; }
        int newest = Build::newest(src);
        if Build::mtime(out) > newest && newest > 0 {
            if self.verbose == 1 { cout << "makej: " << name << " is up to date\n"; }
            return 0;
        }
        cout << "makej: building " << name << "\n";
        Dir::make_all(self.outdir);
        String cmd = self.jcmp + " " + self.mains[i] + " -o " + out;
        if self.flags[i].len > 0 { cmd = cmd + " " + self.flags[i]; }
        return self.sh(cmd);
    }
    int run(self) {
        int^ done = (int^)Mem::alloc0(8 * (self.names.len + 1));
        int rc = 0;
        if self.want == "all" {
            for i in 0..self.names.len {
                if self.kinds[i] != "step" && rc == 0 { rc = self.make_one(self.names[i], done); }
            }
        } else {
            rc = self.make_one(self.want, done);
        }
        Mem::free(done);
        if rc == 0 { cout << "makej: done\n"; }
        return rc;
    }
}
