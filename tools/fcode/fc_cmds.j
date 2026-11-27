// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: the editing commands (a part of fcode.jk, imported in the order of the old file)

// ---------------------------------------------------------------- the commands
void move_to(i64 y, i64 x, bool extend) {
    if extend { if !sel { sel = true; ay = cy; ax = cx; } }
    else { sel = false; }
    cy = y;
    cx = x;
}


void find_next(String what, i64 from_y, i64 from_x) {
    if what.len == 0 { return; }
    for step in 0..lines.len + 1 {
        i64 y = (from_y + step) % lines.len;
        i64 start = 0;
        if step == 0 { start = from_x; }
        String l = lines[y];
        for x in start..l.len + 1 {
            bool fits = x + what.len <= l.len;
            bool same = false;
            if fits {
                String piece = l.slice(x, x + what.len);
                same = piece == what;
            }
            if same && !is_cont(l, x) {
                move_to(y, x, false);
                msg = "found: " + what;
                return;
            }
        }
    }
    msg = "not found: " + what;
}

void newline() {
    if sel { delete_selection(); }
    String l = lines[cy];
    i64 ind = 0;
    while ind < l.len && l[ind] == ' ' && ind < cx { ind += 1; }
    String head = l.slice(0, cx);
    String tail = l.slice(cx, l.len);
    bool between = autopair && head.len > 0 && tail.len > 0 && head[head.len - 1] == '{' && tail[0] == '}';
    if !autoindent { ind = 0; }
    String head_trim = head.trim();
    if autoindent && head_trim.len > 0 && head[head.len - 1] == '{' { ind += tabsize; }
    lines[cy] = head;
    if between {                                                  // {|} : the closing brace goes to a line of its own, the cursor to an indented empty line
        i64 base = ind - tabsize;
        if base < 0 { base = 0; }
        insert_line(cy + 1, " ".repeat(base) + tail);
        insert_line(cy + 1, " ".repeat(ind));
        cy += 1;
        cx = ind;
        dirty = true;
        return;
    }
    insert_line(cy + 1, " ".repeat(ind) + tail);
    cy += 1;
    cx = ind;
    dirty = true;
}
