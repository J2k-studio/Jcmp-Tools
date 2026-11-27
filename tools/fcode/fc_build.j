// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: compile and run, the errors, the examples (a part of fcode.jk, imported in the order of the old file)

// the errors of the compiler in the lines of its text (file:line:col: error: ...): the lines get a red number, show_error goes to the first
void parse_errors(String[] ls) {
    err_line = arr(8);
    err_msg = arr(8);
    err_i = 0;
    for i in 0..ls.len {
        String l = ls[i];
        i64 at = 0;
        bool found = false;
        while at + 9 <= l.len && !found { if l.slice(at, at + 9) == ": error: " { found = true; } else { at += 1; } }
        if !found { continue; }
        String[] parts = l.slice(0, at).split(":");
        if parts.len < 3 { continue; }
        i64 ln = parts[parts.len - 2].to_int();
        if ln < 1 { continue; }
        err_line.push(ln - 1);
        err_msg.push(l.slice(at + 9, l.len) + "");
    }
}

String[] text_lines(String text) {
    String[] ls = text.replace("\r", "").split("\n");
    i64 last = ls.len;
    while last > 0 && ls[last - 1].len == 0 { last -= 1; }          // the empty lines at the end go
    i64 from = 0;
    if last > 200 { from = last - 200; }
    String[] r = arr(16);
    for i in from..last { r.push(ls[i] + ""); }
    return r;
}

// F9 / F11 / F5: compile the file (jcmp), show the log, go to the first error; when run is true and it compiled, run it and show what it printed
void build_run(bool run) {
    if !(path.ends_with(".jk") || path.ends_with(".j")) { msg = "compile: this is not a .jk / .j file"; return; }
    if dirty { save(); }
    String exe = path.slice(0, path.len - 2);
    if path.ends_with(".jk") { exe = path.slice(0, path.len - 3); }
    String[] a = arr(4);
    a.push("-c");
    a.push("jcmp '" + path + "' -o '" + exe + "' 2>&1");
    Result<String, Error> r = Proc::output("sh", a);
    String text = "";
    if r.is_ok() { text = r.take(); }
    String[] ls = text_lines(text);
    parse_errors(ls);
    pane_title = "Compile Log";
    i64 nlines = ls.len;
    pane = arr(4);
    for i in 0..nlines { pane.push(ls[i] + ""); }
    if err_line.len > 0 {
        pane_on = true;
        show_error();
        return;
    }
    if nlines == 0 { pane.push("Compiled: " + exe); }
    pane_on = true;
    if !run { msg = "compiled " + exe; return; }
    String runp = exe;
    if !exe.starts_with("/") { runp = "./" + exe; }
    String[] b = arr(4);
    b.push("-c");
    b.push("timeout 20 '" + runp + "' < /dev/null 2>&1; echo \"[exit $?]\"");
    Result<String, Error> o = Proc::output("sh", b);
    String out = "";
    if o.is_ok() { out = o.take(); }
    String[] outl = text_lines(out);
    i64 nout = outl.len;
    pane = arr(4);
    for i in 0..nout { pane.push(outl[i] + ""); }
    pane_title = "Output of " + exe;
    msg = "ran " + exe;
}

String example_text(i64 n) {
    String t = "#import <stdlib>\n\n";
    if n == 1 { t = t + "void main() {\n    jout << \"Hello from J2K!\\n\";\n}\n"; }
    else if n == 2 { t = t + "void main() {\n    int sum = 0;\n    for i in 1..11 { sum += i; }\n    jout << \"sum of 1 to 10 = \" << sum << \"\\n\";\n    int n = 0;\n    while n < 3 {\n        jout << \"n = \" << n << \"\\n\";\n        n += 1;\n    }\n}\n"; }
    else if n == 3 { t = t + "struct Point {\n    int x;\n    int y;\n}\n\nvoid main() {\n    Point a;\n    a.x = 3;\n    a.y = 4;\n    jout << \"x * x + y * y = \" << a.x * a.x + a.y * a.y << \"\\n\";\n}\n"; }
    else if n == 4 { t = "#import <stdlib>\n#import <files>\n\nvoid main() {\n    Result<String, Error> r = Fs::read_text(\"hello.jk\");\n    if r.is_ok() {\n        String text = r.take();\n        jout << \"hello.jk has \" << text.len << \" bytes\\n\";\n    } else {\n        jout << \"cannot read hello.jk\\n\";\n    }\n}\n"; }
    else { t = t + "void main() {\n    String[] a = Env::args();\n    jout << \"arguments: \" << a.len - 1 << \"\\n\";\n    for i in 1..a.len { jout << a[i] << \"\\n\"; }\n}\n"; }
    return t;
}

void examples_menu() {
    String c = ask("example: 1 hello  2 loops  3 struct  4 read a file  5 arguments  > ").trim();
    i64 n = c.to_int();
    if n < 1 || n > 5 { msg = "no such example"; return; }
    if dirty { msg = "save first (Ctrl-S): an example replaces the text"; return; }
    set_from_text(example_text(n));
    cy = 0; cx = 0; top = 0; left = 0; sel = false;
    dirty = true;
    msg = "example " + str(n) + "  (F11 builds and runs it)";
}

void pane_text(String title, String body) {
    pane_title = title;
    String[] bl = text_lines(body);
    i64 nb = bl.len;
    pane = arr(4);
    for i in 0..nb { pane.push(bl[i] + ""); }
    pane_on = true;
}
