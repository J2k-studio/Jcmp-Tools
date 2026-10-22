// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
// distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
// zipcore: CRC-32, DEFLATE (inflate and a compressor), the ZIP format and its old password (ZipCrypto). Bytes live in a String
// (it may hold any byte); a byte is read as  s[i] & 255.

// the bytes of a file (Fs::read_text stops at a zero byte); "" with ok = false when it cannot be read
String read_bin(String path, bool^ ok) {
    ok[0] = false;
    int fd = Sys::open_read(path.c());
    if fd < 0 { return ""; }
    String r = "";
    char buf[8192];
    int n = Sys::read(fd, @buf, 8192);
    while n > 0 {
        for i in 0..n { r.push(buf[i]); }
        n = Sys::read(fd, @buf, 8192);
    }
    Sys::close(fd);
    ok[0] = n == 0;
    return r;
}

// ---------------------------------------------------------------- CRC-32
int[] crc_tab;
bool crc_ready;
void crc_init() {
    if crc_ready { return; }
    crc_ready = true;
    crc_tab = arr(256);
    for n in 0..256 {
        int c = n;
        for k in 0..8 {
            if (c & 1) != 0 { c = 3988292384 xor (c >> 1); } else { c = c >> 1; }
        }
        crc_tab.push(c);
    }
}
int crc_add(int crc, int b) {
    return crc_tab[(crc xor b) & 255] xor (crc >> 8);
}
int crc32_of(String data, int from, int to) {
    crc_init();
    int c = 4294967295;
    for i in from..to { c = crc_add(c, data[i] & 255); }
    return c xor 4294967295;
}

// ---------------------------------------------------------------- inflate (the method of RFC 1951)
String inf_src;
int inf_pos;
int inf_end;
int inf_buf;
int inf_cnt;
bool inf_bad;
String inf_out;

int inf_bits(int need) {
    int v = inf_buf;
    while inf_cnt < need {
        if inf_pos >= inf_end { inf_bad = true; return 0; }
        v = v | ((inf_src[inf_pos] & 255) << inf_cnt);
        inf_pos += 1;
        inf_cnt += 8;
    }
    inf_buf = v >> need;
    inf_cnt -= need;
    return v & ((1 << need) - 1);
}

// a table of codes: count[len] = how many codes have that length; sym = the symbols in the order of their codes
int[] fix_lcount;
int[] fix_lsym;
int[] fix_dcount;
int[] fix_dsym;

void huff_build(int[] lengths, int n, int[] count, int[] sym) {
    for i in 0..16 { count[i] = 0; }
    for i in 0..n { count[lengths[i]] += 1; }
    int[] offs = arr(16);
    for i in 0..16 { offs.push(0); }
    for i in 1..15 { offs[i + 1] = offs[i] + count[i]; }
    for i in 0..n {
        if lengths[i] != 0 { sym[offs[lengths[i]]] = i; offs[lengths[i]] += 1; }
    }
}

int huff_decode(int[] count, int[] sym) {
    int code = 0;
    int first = 0;
    int index = 0;
    for len in 1..16 {
        code = code | inf_bits(1);
        if inf_bad { return 0 - 1; }
        int c = count[len];
        if code - c < first { return sym[index + (code - first)]; }
        index += c;
        first += c;
        first = first << 1;
        code = code << 1;
    }
    return 0 - 1;
}

int[] len_base;
int[] len_extra;
int[] dist_base;
int[] dist_extra;
bool inf_ready;
void inf_tables() {
    if inf_ready { return; }
    inf_ready = true;
    len_base = arr(29);
    len_extra = arr(29);
    int[] lb = arr(29);
    String ls = "3 4 5 6 7 8 9 10 11 13 15 17 19 23 27 31 35 43 51 59 67 83 99 115 131 163 195 227 258";
    String[] lp = ls.split(" ");
    for i in 0..29 { len_base.push(lp[i].to_int()); }
    String es = "0 0 0 0 0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 0";
    String[] ep = es.split(" ");
    for i in 0..29 { len_extra.push(ep[i].to_int()); }
    dist_base = arr(30);
    dist_extra = arr(30);
    String ds = "1 2 3 4 5 7 9 13 17 25 33 49 65 97 129 193 257 385 513 769 1025 1537 2049 3073 4097 6145 8193 12289 16385 24577";
    String[] dp = ds.split(" ");
    for i in 0..30 { dist_base.push(dp[i].to_int()); }
    String xs = "0 0 0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10 11 11 12 12 13 13";
    String[] xp = xs.split(" ");
    for i in 0..30 { dist_extra.push(xp[i].to_int()); }
    // the fixed codes
    int[] l = arr(288);
    for i in 0..288 {
        if i < 144 { l.push(8); } else if i < 256 { l.push(9); } else if i < 280 { l.push(7); } else { l.push(8); }
    }
    fix_lcount = arr(16);
    for i in 0..16 { fix_lcount.push(0); }
    fix_lsym = arr(288);
    for i in 0..288 { fix_lsym.push(0); }
    huff_build(l, 288, fix_lcount, fix_lsym);
    int[] d = arr(30);
    for i in 0..30 { d.push(5); }
    fix_dcount = arr(16);
    for i in 0..16 { fix_dcount.push(0); }
    fix_dsym = arr(30);
    for i in 0..30 { fix_dsym.push(0); }
    huff_build(d, 30, fix_dcount, fix_dsym);
}

bool inf_codes(int[] lc, int[] ls, int[] dc, int[] ds) {
    while true {
        int sym = huff_decode(lc, ls);
        if sym < 0 { return false; }
        if sym < 256 { inf_out.push((char)sym); }
        else if sym == 256 { return true; }
        else {
            sym -= 257;
            if sym >= 29 { return false; }
            int len = len_base[sym] + inf_bits(len_extra[sym]);
            int ds2 = huff_decode(dc, ds);
            if ds2 < 0 || ds2 >= 30 { return false; }
            int dist = dist_base[ds2] + inf_bits(dist_extra[ds2]);
            if inf_bad || dist > inf_out.len { return false; }
            for k in 0..len { inf_out.push(inf_out[inf_out.len - dist]); }
        }
    }
    return true;
}

// the bytes of src[from, to) are a raw deflate stream; the result is the data, or ok = false
String inflate_raw(String src, int from, int to, bool^ ok) {
    inf_tables();
    inf_src = src;
    inf_pos = from;
    inf_end = to;
    inf_buf = 0;
    inf_cnt = 0;
    inf_bad = false;
    inf_out = "";
    ok[0] = false;
    bool last = false;
    while !last {
        last = inf_bits(1) == 1;
        int type = inf_bits(2);
        if inf_bad { return ""; }
        if type == 0 {
            inf_buf = 0;
            inf_cnt = 0;
            if inf_pos + 4 > inf_end { return ""; }
            int n = (inf_src[inf_pos] & 255) | ((inf_src[inf_pos + 1] & 255) << 8);
            inf_pos += 4;
            if inf_pos + n > inf_end { return ""; }
            for i in 0..n { inf_out.push(inf_src[inf_pos + i]); }
            inf_pos += n;
        } else if type == 1 {
            if !inf_codes(fix_lcount, fix_lsym, fix_dcount, fix_dsym) { return ""; }
        } else if type == 2 {
            int nlen = inf_bits(5) + 257;
            int ndist = inf_bits(5) + 1;
            int ncode = inf_bits(4) + 4;
            if inf_bad || nlen > 286 || ndist > 30 { return ""; }
            int[] order = arr(19);
            String os = "16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15";
            String[] op = os.split(" ");
            for i in 0..19 { order.push(op[i].to_int()); }
            int[] lengths = arr(320);
            for i in 0..320 { lengths.push(0); }
            for i in 0..ncode { lengths[order[i]] = inf_bits(3); }
            int[] cc = arr(16);
            for i in 0..16 { cc.push(0); }
            int[] cs = arr(19);
            for i in 0..19 { cs.push(0); }
            huff_build(lengths, 19, cc, cs);
            int[] ll = arr(320);
            for i in 0..320 { ll.push(0); }
            int idx = 0;
            while idx < nlen + ndist {
                int sym = huff_decode(cc, cs);
                if sym < 0 { return ""; }
                if sym < 16 { ll[idx] = sym; idx += 1; }
                else {
                    int prev = 0;
                    int rep = 0;
                    if sym == 16 {
                        if idx == 0 { return ""; }
                        prev = ll[idx - 1];
                        rep = 3 + inf_bits(2);
                    } else if sym == 17 { rep = 3 + inf_bits(3); }
                    else { rep = 11 + inf_bits(7); }
                    if idx + rep > nlen + ndist { return ""; }
                    for i in 0..rep { ll[idx] = prev; idx += 1; }
                }
            }
            int[] lc = arr(16);
            for i in 0..16 { lc.push(0); }
            int[] lsym = arr(288);
            for i in 0..288 { lsym.push(0); }
            huff_build(ll, nlen, lc, lsym);
            int[] dl = arr(30);
            for i in 0..30 { dl.push(ll[nlen + i]); }
            int[] dc = arr(16);
            for i in 0..16 { dc.push(0); }
            int[] dsym = arr(30);
            for i in 0..30 { dsym.push(0); }
            huff_build(dl, ndist, dc, dsym);
            if !inf_codes(lc, lsym, dc, dsym) { return ""; }
        } else { return ""; }
        if inf_bad { return ""; }
    }
    ok[0] = true;
    return inf_out;
}

// ---------------------------------------------------------------- deflate (a compressor: LZ77 with a hash chain, the fixed codes)
String def_out;
int def_buf;
int def_cnt;
void def_put(int value, int nbits) {                  // bits go from the low end
    def_buf = def_buf | (value << def_cnt);
    def_cnt += nbits;
    while def_cnt >= 8 {
        def_out.push((char)(def_buf & 255));
        def_buf = def_buf >> 8;
        def_cnt -= 8;
    }
}
int rev_bits(int code, int n) {
    int r = 0;
    for i in 0..n { r = (r << 1) | ((code >> i) & 1); }
    return r;
}
void def_lit(int sym) {                               // the fixed code of a literal or length symbol (0 .. 287): the code goes from its high bit
    if sym < 144 { def_put(rev_bits(48 + sym, 8), 8); }
    else if sym < 256 { def_put(rev_bits(400 + sym - 144, 9), 9); }
    else if sym < 280 { def_put(rev_bits(sym - 256, 7), 7); }
    else { def_put(rev_bits(192 + sym - 280, 8), 8); }
}

String deflate_raw(String data) {
    inf_tables();
    def_out = "";
    def_buf = 0;
    def_cnt = 0;
    int n = data.len;
    def_put(1, 1);                                    // the last block
    def_put(1, 2);                                    // fixed codes
    int[] head = arr(65536);
    for i in 0..65536 { head.push(0 - 1); }
    int[] prev = arr(32768);
    for i in 0..32768 { prev.push(0 - 1); }
    int i = 0;
    while i < n {
        int best = 0;
        int bdist = 0;
        if i + 2 < n {
            int h = (((data[i] & 255) << 8) xor ((data[i + 1] & 255) << 4) xor (data[i + 2] & 255)) & 65535;
            int cand = head[h];
            int tries = 0;
            while cand >= 0 && i - cand <= 32768 && tries < 48 {
                int m = 0;
                while m < 258 && i + m < n && data[cand + m] == data[i + m] { m += 1; }
                if m > best { best = m; bdist = i - cand; if m == 258 { break; } }
                cand = prev[cand & 32767];
                tries += 1;
            }
            prev[i & 32767] = head[h];
            head[h] = i;
        }
        if best >= 3 {
            int ls = 28;
            while len_base[ls] > best { ls -= 1; }
            def_lit(257 + ls);
            def_put(best - len_base[ls], len_extra[ls]);
            int ds = 29;
            while dist_base[ds] > bdist { ds -= 1; }
            def_put(rev_bits(ds, 5), 5);
            def_put(bdist - dist_base[ds], dist_extra[ds]);
            for k in 1..best {                         // the places inside the match go into the chain too
                int p = i + k;
                if p + 2 < n {
                    int h2 = (((data[p] & 255) << 8) xor ((data[p + 1] & 255) << 4) xor (data[p + 2] & 255)) & 65535;
                    prev[p & 32767] = head[h2];
                    head[h2] = p;
                }
            }
            i += best;
        } else {
            def_lit(data[i] & 255);
            i += 1;
        }
    }
    def_lit(256);
    if def_cnt > 0 { def_out.push((char)(def_buf & 255)); }
    return def_out;
}

// ---------------------------------------------------------------- ZipCrypto (the old password of ZIP; not strong, but every unzip knows it)
int zk0;
int zk1;
int zk2;
void zc_update(int b) {
    zk0 = crc_tab[(zk0 xor b) & 255] xor (zk0 >> 8);
    zk1 = ((zk1 + (zk0 & 255)) * 134775813 + 1) & 4294967295;
    zk2 = crc_tab[(zk2 xor (zk1 >> 24)) & 255] xor (zk2 >> 8);
}
void zc_start(String password) {
    crc_init();
    zk0 = 305419896;
    zk1 = 591751049;
    zk2 = 878082192;
    for i in 0..password.len { zc_update(password[i] & 255); }
}
int zc_byte() {
    int t = (zk2 | 2) & 65535;
    return ((t * (t xor 1)) >> 8) & 255;
}
String zc_decrypt(String data, int from, int to) {
    String r = "";
    for i in from..to {
        int c = (data[i] & 255) xor zc_byte();
        zc_update(c);
        r.push((char)c);
    }
    return r;
}
String zc_encrypt(String data) {
    String r = "";
    for i in 0..data.len {
        int p = data[i] & 255;
        int c = p xor zc_byte();
        zc_update(p);
        r.push((char)c);
    }
    return r;
}

// ---------------------------------------------------------------- the ZIP format
int le16(String s, int at) { return (s[at] & 255) | ((s[at + 1] & 255) << 8); }
int le32(String s, int at) { return le16(s, at) | (le16(s, at + 2) << 16); }
void put16(String s, int v) { s.push((char)(v & 255)); s.push((char)((v >> 8) & 255)); }
void put32(String s, int v) { put16(s, v & 65535); put16(s, (v >> 16) & 65535); }

// one entry of the central directory
String[] zn_name;
int[] zn_method;
int[] zn_flags;
int[] zn_crc;
int[] zn_csize;
int[] zn_usize;
int[] zn_offset;
int[] zn_time;

// reads the list of entries of a zip file (its bytes in z); false when it is not a zip
bool zip_list(String z) {
    zn_name = arr(8); zn_method = arr(8); zn_flags = arr(8); zn_crc = arr(8); zn_csize = arr(8); zn_usize = arr(8); zn_offset = arr(8); zn_time = arr(8);
    int at = z.len - 22;
    while at >= 0 && at >= z.len - 65557 {
        if le32(z, at) == 101010256 { break; }
        at -= 1;
    }
    if at < 0 || le32(z, at) != 101010256 { return false; }
    int count = le16(z, at + 10);
    int p = le32(z, at + 16);
    for i in 0..count {
        if p + 46 > z.len || le32(z, p) != 33639248 { return false; }
        int nlen = le16(z, p + 28);
        int xlen = le16(z, p + 30);
        int clen = le16(z, p + 32);
        zn_flags.push(le16(z, p + 8));
        zn_method.push(le16(z, p + 10));
        zn_time.push(le32(z, p + 12));
        zn_crc.push(le32(z, p + 16));
        zn_csize.push(le32(z, p + 20));
        zn_usize.push(le32(z, p + 24));
        zn_offset.push(le32(z, p + 42));
        zn_name.push(z.slice(p + 46, p + 46 + nlen));
        p += 46 + nlen + xlen + clen;
    }
    return true;
}

// the start of the data of entry i (after its local header)
int zip_data_at(String z, int i) {
    int p = zn_offset[i];
    if p + 30 > z.len || le32(z, p) != 67324752 { return 0 - 1; }
    return p + 30 + le16(z, p + 26) + le16(z, p + 28);
}

// extracts entry i: err = "" when it worked, "password" when a password is needed or wrong, or a text
String zip_err;
String zip_extract(String z, int i, String password) {
    zip_err = "";
    int at = zip_data_at(z, i);
    if at < 0 || at + zn_csize[i] > z.len { zip_err = "damaged"; return ""; }
    int end = at + zn_csize[i];
    String raw = "";
    bool encrypted = (zn_flags[i] & 1) != 0;
    if encrypted {
        if password.len == 0 { zip_err = "password"; return ""; }
        zc_start(password);
        String dec = zc_decrypt(z, at, end);
        int check = zn_crc[i] >> 24;
        if (zn_flags[i] & 8) != 0 { check = (zn_time[i] >> 8) & 255; }
        if (dec[11] & 255) != check { zip_err = "password"; return ""; }
        raw = dec.slice(12, dec.len);
    } else { raw = z.slice(at, end); }
    String data = "";
    if zn_method[i] == 0 { data = raw; }
    else if zn_method[i] == 8 {
        bool ok = false;
        data = inflate_raw(raw, 0, raw.len, @ok);
        if !ok { zip_err = "damaged"; return ""; }
    } else { zip_err = "method " + str(zn_method[i]) + " is not supported"; return ""; }
    if crc32_of(data, 0, data.len) != zn_crc[i] { zip_err = "the check sum is wrong (a wrong password or a damaged file)"; return ""; }
    return data;
}

// the writer: add entries, then finish
String zw_out;
String zw_dir;
int zw_count;
void zw_start() { zw_out = ""; zw_dir = ""; zw_count = 0; }
void zw_add(String name, String data, bool isdir, String password) {
    crc_init();
    int crc = 0;
    String body = data;
    int method = 0;
    if !isdir {
        crc = crc32_of(data, 0, data.len);
        if data.len > 16 {
            String d = deflate_raw(data);
            if d.len < data.len { body = d; method = 8; }
        }
    }
    int flags = 2048;                                  // the names are UTF-8
    if password.len > 0 && !isdir {
        flags = flags | 1;
        zc_start(password);
        String head = "";
        int seed = Time::now_ms();
        for k in 0..11 { seed = (seed * 1103515245 + 12345) & 2147483647; head.push((char)((seed >> 16) & 255)); }
        head.push((char)(crc >> 24));
        body = zc_encrypt(head + body);
    }
    int off = zw_out.len;
    put32(zw_out, 67324752); put16(zw_out, 20); put16(zw_out, flags); put16(zw_out, method);
    put16(zw_out, 0); put16(zw_out, 33);               // the time 00:00 and the date 1980-01-01
    put32(zw_out, crc); put32(zw_out, body.len); put32(zw_out, data.len);
    put16(zw_out, name.len); put16(zw_out, 0);
    zw_out.append(name);
    zw_out.append(body);
    put32(zw_dir, 33639248); put16(zw_dir, 788); put16(zw_dir, 20); put16(zw_dir, flags); put16(zw_dir, method);
    put16(zw_dir, 0); put16(zw_dir, 33);
    put32(zw_dir, crc); put32(zw_dir, body.len); put32(zw_dir, data.len);
    put16(zw_dir, name.len); put16(zw_dir, 0); put16(zw_dir, 0); put16(zw_dir, 0); put16(zw_dir, 0);
    int attr = 2175008768;                             // -rw-r--r--
    if isdir { attr = 1106051072 + 16; }               // drwxr-xr-x
    put32(zw_dir, attr);
    put32(zw_dir, off);
    zw_dir.append(name);
    zw_count += 1;
}
String zw_finish() {
    int start = zw_out.len;
    zw_out.append(zw_dir);
    put32(zw_out, 101010256); put16(zw_out, 0); put16(zw_out, 0); put16(zw_out, zw_count); put16(zw_out, zw_count);
    put32(zw_out, zw_dir.len); put32(zw_out, start); put16(zw_out, 0);
    return zw_out;
}
