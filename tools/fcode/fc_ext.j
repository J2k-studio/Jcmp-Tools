// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: extensions: snippets, words, commands (a part of fcode.jk, imported in the order of the old file)

// ---------------------------------------------------------------- the extension j2k: snippets and word completion with Tab
// ---------------------------------------------------------------- extensions that you write: ~/.config/fcode/extensions/NAME/
// NAME/snippets   lines  prefix = body   (\n is a new line, | is where the cursor goes)
// NAME/words      words for the Tab completion (any spaces and lines)
// NAME/commands   lines  name = shell command   (%f is the file; the command bar runs it:  run name )
String[] xs_pre;
String[] xs_body;
String[] xs_words;
String[] xc_name;
String[] xc_cmd;
String[] xs_loaded;
void load_extensions() {
    xs_pre = arr(8); xs_body = arr(8); xs_words = arr(8); xc_name = arr(8); xc_cmd = arr(8); xs_loaded = arr(4);
    load_ext_root(config_dir() + "/extensions");
    Option<String> pe = Env::get("PATH");                                     // a tool brings its own: DIR/fcode-extensions/NAME (DIR is on the PATH)
    if pe.is_some() {
        String[] pd = pe.unwrap().split(":");
        for k in 0..pd.len { if pd[k].len > 0 { load_ext_root(pd[k] + "/fcode-extensions"); load_ext_root(pd[k] + "/coderin-extensions"); } }
    }
}
void load_ext_root(String root) {
    if !Dir::exists(root) { return; }
    Result<String[], Error> r = Dir::list(root);
    if !r.is_ok() { return; }
    String[] names = r.take();
    for n in 0..names.len {
        String d = root + "/" + names[n];
        if !Dir::exists(d) { continue; }
        xs_loaded.push(names[n] + "");
        Result<String, Error> a = Fs::read_text(d + "/snippets");
        if a.is_ok() {
            String[] ls = a.take().split("\n");
            for i in 0..ls.len {
                String l = ls[i].trim();
                i64 eq = 0;
                while eq < l.len && l[eq] != '=' { eq += 1; }
                if l.len == 0 || l[0] == '#' || eq >= l.len { continue; }
                xs_pre.push(l.slice(0, eq).trim());
                xs_body.push(l.slice(eq + 1, l.len).trim().replace("\\n", "\n"));
            }
        }
        Result<String, Error> b = Fs::read_text(d + "/words");
        if b.is_ok() {
            String[] ws = b.take().replace("\n", " ").split(" ");
            for i in 0..ws.len { if ws[i].len > 0 { xs_words.push(ws[i] + ""); } }
        }
        Result<String, Error> c = Fs::read_text(d + "/commands");
        if c.is_ok() {
            String[] ls = c.take().split("\n");
            for i in 0..ls.len {
                String l = ls[i].trim();
                i64 eq = 0;
                while eq < l.len && l[eq] != '=' { eq += 1; }
                if l.len == 0 || l[0] == '#' || eq >= l.len { continue; }
                xc_name.push(l.slice(0, eq).trim());
                xc_cmd.push(l.slice(eq + 1, l.len).trim());
            }
        }
    }
}
void run_ext_command(String name) {
    for i in 0..xc_name.len {
        if xc_name[i] == name {
            if dirty { save(); }
            String[] args = arr(4);
            args.push("-c");
            args.push(xc_cmd[i].replace("%f", path));
            Result<String, Error> r = Proc::output("sh", args);
            if !r.is_ok() { msg = name + ": failed"; return; }
            String out = r.take().trim();
            String[] ol = out.split("\n");
            if ol.len == 0 || out.len == 0 { msg = name + ": done"; }
            else { msg = ol[ol.len - 1] + ""; }
            return;
        }
    }
    msg = "no command " + name + " (extensions: " + str(xc_name.len) + " commands)";
}

String snippet_for(String w) {
    for i in 0..xs_pre.len { if xs_pre[i] == w { return xs_body[i] + ""; } }
    if w == "main" { return "void main() {\n    |\n}"; }
    if w == "for" { return "for i in 0..n {\n    |\n}"; }
    if w == "while" { return "while cond {\n    |\n}"; }
    if w == "if" { return "if cond {\n    |\n}"; }
    if w == "ife" { return "if cond {\n    |\n} else {\n    \n}"; }
    if w == "struct" { return "struct Name {\n    int field;\n    |\n}"; }
    if w == "enum" { return "enum class Name { First, Second, | };"; }
    if w == "switch" { return "switch value {\n    |\n}"; }
    if w == "try" { return "try {\n    |\n} catch (e) {\n    \n}"; }
    if w == "jout" { return "jout << |\"\\n\";"; }
    if w == "fn" { return "int name(int a) {\n    |\n}"; }
    if w == "exp" { return "export int name(int a) {\n    |\n}"; }
    return "";
}
// the words that continue w: the words of J2K and of the extensions, then the words of the text
String[] word_cands(String w) {
    String kws = "if else while for in return break continue switch case default struct enum using module import defer try catch throw new delete true false null sizeof export operator String Result Option Error double float bool char void int";
    String[] cands = arr(16);
    String[] kw = kws.split(" ");
    for i in 0..kw.len { if kw[i].starts_with(w) && kw[i].len > w.len { add_cand(cands, kw[i]); } }
    for i in 0..xs_words.len { if xs_words[i].starts_with(w) && xs_words[i].len > w.len { add_cand(cands, xs_words[i]); } }
    for y in 0..lines.len {
        String t = lines[y];
        i64 i = 0;
        while i < t.len {
            if is_word(t[i] & 255) {
                i64 j = i;
                while j < t.len && is_word(t[j] & 255) { j += 1; }
                String x = t.slice(i, j);
                if x.starts_with(w) && x.len > w.len { add_cand(cands, x); }
                i = j;
            } else { i += 1; }
        }
    }
    return cands;
}
bool tab_help() {
    if !ext_j2k && xs_loaded.len == 0 { return false; }
    String l = lines[cy];
    i64 st = cx;
    while st > 0 && is_word(l[st - 1] & 255) { st -= 1; }
    if st == cx { return false; }
    String w = l.slice(st, cx);
    String snip = snippet_for(w);
    String lead = l.slice(0, st).trim();
    if snip.len > 0 && lead.len == 0 {                                        // a snippet is for the start of a line
        begin_edit(0);
        i64 base = 0;
        while base < l.len && l[base] == ' ' { base += 1; }
        String text = snip.replace("\n", "\n" + " ".repeat(base));
        i64 m = 0;
        while m < text.len && text[m] != '|' { m += 1; }
        String before = text.slice(0, m);
        String after = "";
        if m < text.len { after = text.slice(m + 1, text.len); } else { before = text; }
        lines[cy] = l.slice(0, st) + l.slice(cx, l.len);
        cx = st;
        i64 y0 = cy;
        insert_text(before + after);
        String[] bl = before.split("\n");
        cy = y0 + bl.len - 1;
        if bl.len == 1 { cx = st + before.len; } else { cx = bl[bl.len - 1].len; }
        return true;
    }
    if w.len < 2 { return false; }
    // word completion: the words of the J2K language and the words of the text
    String[] cands = word_cands(w);
    if cands.len == 0 { return false; }
    String common = cands[0];
    for i in 1..cands.len {
        i64 n = 0;
        while n < common.len && n < cands[i].len && common[n] == cands[i][n] { n += 1; }
        common = common.slice(0, n);
    }
    if common.len > w.len {
        begin_edit(0);
        lines[cy] = l.slice(0, st) + common + l.slice(cx, l.len);
        cx = st + common.len;
        dirty = true;
        if cands.len > 1 { msg = str(cands.len) + " words: " + cands[0] + " " + cands[1] + " ..."; }
        return true;
    }
    msg = "words: ";
    for i in 0..cands.len { if i < 6 { msg = msg + cands[i] + " "; } }
    return true;
}
void add_cand(String[] c, String x) {
    for i in 0..c.len { if c[i] == x { return; } }
    c.push(x);
}

void insert_text(String t) {
    if sel { delete_selection(); }
    if t == "}" && cx >= tabsize && use_spaces {                  // a closing brace at the start of a line steps back one level
        String before = lines[cy].slice(0, cx);
        if before.trim().len == 0 { lines[cy] = lines[cy].slice(tabsize, lines[cy].len); cx -= tabsize; }
    }
    String[] parts = t.split("\n");
    String tail = lines[cy].slice(cx, lines[cy].len);
    String head = lines[cy].slice(0, cx);
    if parts.len == 1 {
        lines[cy] = head + t + tail;
        cx = head.len + t.len;
    } else {
        lines[cy] = head + parts[0];
        for i in 1..parts.len - 1 { insert_line(cy + i, parts[i]); }
        i64 last = cy + parts.len - 1;
        insert_line(last, parts[parts.len - 1] + tail);
        cy = last;
        cx = parts[parts.len - 1].len;
    }
    dirty = true;
}
