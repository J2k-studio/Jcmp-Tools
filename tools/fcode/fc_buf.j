// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// fcode: several files. The file that is shown lives in the names the rest of the editor uses (lines, cy, cx ...); the others rest here.

struct Buffer {
    String[] lines;
    i64 cy;
    i64 cx;
    i64 top;
    i64 left;
    bool sel;
    i64 ay;
    i64 ax;
    bool dirty;
    String path;
    String[] undo_text;
    i64[] undo_cy;
    i64[] undo_cx;
    String[] redo_text;
    i64[] redo_cy;
    i64[] redo_cx;
    i64 last_kind;
    i64 last_edit_ms;
}

Buffer[] bufs;           // the slot of the file that is shown is empty until another one is shown
i64 cur_buf;

// the state of the shown file goes into its slot
void buffer_store() {
    bufs[cur_buf].lines = lines;
    bufs[cur_buf].cy = cy; bufs[cur_buf].cx = cx; bufs[cur_buf].top = top; bufs[cur_buf].left = left;
    bufs[cur_buf].sel = sel; bufs[cur_buf].ay = ay; bufs[cur_buf].ax = ax;
    bufs[cur_buf].dirty = dirty;
    bufs[cur_buf].path = path;
    bufs[cur_buf].undo_text = undo_text; bufs[cur_buf].undo_cy = undo_cy; bufs[cur_buf].undo_cx = undo_cx;
    bufs[cur_buf].redo_text = redo_text; bufs[cur_buf].redo_cy = redo_cy; bufs[cur_buf].redo_cx = redo_cx;
    bufs[cur_buf].last_kind = last_kind; bufs[cur_buf].last_edit_ms = last_edit_ms;
}

// the file of slot n is shown: what belongs to the view only (the popup, the errors of a build) starts anew
void buffer_fetch(i64 n) {
    cur_buf = n;
    lines = bufs[n].lines;
    cy = bufs[n].cy; cx = bufs[n].cx; top = bufs[n].top; left = bufs[n].left;
    sel = bufs[n].sel; ay = bufs[n].ay; ax = bufs[n].ax;
    dirty = bufs[n].dirty;
    path = bufs[n].path + "";
    undo_text = bufs[n].undo_text; undo_cy = bufs[n].undo_cy; undo_cx = bufs[n].undo_cx;
    redo_text = bufs[n].redo_text; redo_cy = bufs[n].redo_cy; redo_cx = bufs[n].redo_cx;
    last_kind = bufs[n].last_kind; last_edit_ms = bufs[n].last_edit_ms;
    pop_on = false;
    free_scroll = false;
    err_line = arr(1);
    err_msg = arr(1);
}

void buffer_switch(i64 n) {
    if n == cur_buf || n < 0 || n >= bufs.len { return; }
    buffer_store();
    buffer_fetch(n);
}

// the next file (step 1) or the one before (step -1), round the list
void buffer_step(i64 step) {
    if bufs.len < 2 { msg = "only one file is open"; return; }
    buffer_switch((cur_buf + step + bufs.len) % bufs.len);
    msg = path + " (" + stg(cur_buf + 1) + " of " + stg(bufs.len) + ")";
}

// the first file: it is the shown one
void buffer_first(String p) {
    bufs = arr(8);
    Buffer b;
    bufs.push(b);
    cur_buf = 0;
    path = p + "";
    load(path);
}

// shows the file p: the one that is open already, or a new slot; its number
i64 buffer_open(String p) {
    for i in 0..bufs.len {
        bool same = false;
        if i == cur_buf { same = path == p; } else { same = bufs[i].path == p; }
        if same { buffer_switch(i); return i; }
    }
    buffer_store();
    Buffer b;
    bufs.push(b);
    cur_buf = bufs.len - 1;
    cy = 0; cx = 0; top = 0; left = 0; sel = false; ay = 0; ax = 0; dirty = false;
    undo_text = arr(16); undo_cy = arr(16); undo_cx = arr(16);
    redo_text = arr(8); redo_cy = arr(8); redo_cx = arr(8);
    last_kind = 0; last_edit_ms = 0;
    pop_on = false;
    path = p + "";
    load(path);
    return cur_buf;
}

// has any open file changes that are not saved
bool any_dirty() {
    if dirty { return true; }
    for i in 0..bufs.len { if i != cur_buf && bufs[i].dirty { return true; } }
    return false;
}
