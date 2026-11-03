// axml.j -- the binary AndroidManifest.xml (Android's compiled XML: a string pool, the resource ids of the android: attribute names, and the elements).
//   axml_begin();
//   axml_open("manifest");  axml_a_plain("package", "com.example.app");  axml_a_int("versionCode", 100);  axml_a_str("versionName", "0.1.0");  axml_commit();
//     axml_open("uses-sdk");  axml_a_int("minSdkVersion", 29);  axml_commit();  axml_close("uses-sdk");
//   axml_close("manifest");
//   String xml = axml_end();
// The attributes of an element are sorted by resource id when it is committed (Android looks them up by binary search).

String[] ax_pool;                 // the strings; the first ones are the names of the android: attributes
int[] ax_pool_id;                 // the resource id of a name (the entry of the resource map), 0 for the others
int ax_nres;                      // how many names have a resource id: they come first in the pool
String ax_body;                   // the chunks of the namespace and of the elements
int ax_ns_prefix;                 // the pool index of "android"
int ax_ns_uri;                    // and of its uri
// the element that is being built
String ax_tag;
int[] ax_t_name;                  // the attributes: pool index of the name, 0 + 1 when it belongs to android:
int[] ax_t_ns;                    // 1: android:, 0: no namespace
int[] ax_t_id;                    // resource id (to sort)
int[] ax_t_type;                  // 3 string, 16 decimal, 17 hex, 18 boolean, 1 reference
int[] ax_t_data;                  // the value, or the pool index of a string
int ax_t_n;

void ax_put16(String s, int v) {
    s.push((char)(v & 255));
    s.push((char)((v >> 8) & 255));
}

void ax_put32(String s, int v) {
    s.push((char)(v & 255));
    s.push((char)((v >> 8) & 255));
    s.push((char)((v >> 16) & 255));
    s.push((char)((v >> 24) & 255));
}

// the pool index of a string that is not a name with an id (made when it is new)
int ax_str(String t) {
    for i in ax_nres..ax_pool.len { if ax_pool[i] == t { return i; } }
    ax_pool.push(t + "");
    ax_pool_id.push(0);
    return ax_pool.len - 1;
}

int ax_name_idx(String t) {
    for i in 0..ax_nres { if ax_pool[i] == t { return i; } }
    return -1;
}

void ax_res(String name, int id) {
    ax_pool.push(name + "");
    ax_pool_id.push(id);
    ax_nres += 1;
}

void axml_begin() {
    ax_pool = arr(64);
    ax_pool_id = arr(64);
    ax_nres = 0;
    ax_body = "";
    ax_t_name = arr(16); ax_t_ns = arr(16); ax_t_id = arr(16); ax_t_type = arr(16); ax_t_data = arr(16);
    // the names of android: attributes that a manifest of ours uses, with their resource ids
    ax_res("theme", 16842752);                 // 0x01010000
    ax_res("label", 16842753);                 // 0x01010001
    ax_res("icon", 16842754);                  // 0x01010002
    ax_res("name", 16842755);                  // 0x01010003
    ax_res("exported", 16842768);              // 0x01010010
    ax_res("screenOrientation", 16842782);     // 0x0101001e
    ax_res("configChanges", 16842783);         // 0x0101001f
    ax_res("value", 16842788);                 // 0x01010024
    ax_res("allowBackup", 16843392);           // 0x01010280
    ax_res("versionCode", 16843291);           // 0x0101021b
    ax_res("versionName", 16843292);           // 0x0101021c
    ax_res("minSdkVersion", 16843276);         // 0x0101020c
    ax_res("targetSdkVersion", 16843376);      // 0x01010270
    ax_res("hasCode", 16842764);               // 0x0101000c
    ax_res("largeHeap", 16843610);             // 0x0101035a
    ax_res("requestLegacyExternalStorage", 16844291);   // 0x01010603
    ax_res("usesCleartextTraffic", 16844012);  // 0x010104ec
    ax_ns_prefix = ax_str("android");
    ax_ns_uri = ax_str("http://schemas.android.com/apk/res/android");
    // the start of the namespace
    ax_put16(ax_body, 256); ax_put16(ax_body, 16); ax_put32(ax_body, 24); ax_put32(ax_body, 1); ax_put32(ax_body, -1);
    ax_put32(ax_body, ax_ns_prefix); ax_put32(ax_body, ax_ns_uri);
    ax_t_n = 0;
}

void axml_open(String tag) {
    ax_tag = tag + "";
    ax_t_n = 0;
    ax_t_name.clear(); ax_t_ns.clear(); ax_t_id.clear(); ax_t_type.clear(); ax_t_data.clear();
}

void ax_add(String name, bool android, int type, int data) {
    int idx = ax_name_idx(name);
    int id = 0;
    if android {
        if idx < 0 { cerr << "axml: the attribute " << name << " has no resource id (add it to axml_begin)\n"; return; }
        id = ax_pool_id[idx];
    } else {
        idx = ax_str(name);
    }
    ax_t_name.push(idx);
    if android { ax_t_ns.push(1); } else { ax_t_ns.push(0); }
    ax_t_id.push(id);
    ax_t_type.push(type);
    ax_t_data.push(data);
    ax_t_n += 1;
}

void axml_a_str(String name, String value) { ax_add(name, true, 3, ax_str(value)); }
void axml_a_int(String name, int value) { ax_add(name, true, 16, value); }
void axml_a_hex(String name, int value) { ax_add(name, true, 17, value); }
void axml_a_bool(String name, bool value) { if value { ax_add(name, true, 18, -1); } else { ax_add(name, true, 18, 0); } }
void axml_a_ref(String name, int id) { ax_add(name, true, 1, id); }
void axml_a_plain(String name, String value) { ax_add(name, false, 3, ax_str(value)); }

// write the start of the element, the attributes sorted: those without a namespace first, then by resource id
void axml_commit() {
    int n = ax_t_n;
    int[] order = arr(n + 1);
    for i in 0..n { order.push(i); }
    for i in 1..n {                                  // an insertion sort on (namespace, id)
        int x = order[i];
        int j = i - 1;
        while j >= 0 && (ax_t_ns[order[j]] > ax_t_ns[x] || (ax_t_ns[order[j]] == ax_t_ns[x] && ax_t_id[order[j]] > ax_t_id[x])) {
            order[j + 1] = order[j];
            j -= 1;
        }
        order[j + 1] = x;
    }
    int name = ax_str(ax_tag);
    ax_put16(ax_body, 258); ax_put16(ax_body, 16); ax_put32(ax_body, 36 + 20 * n); ax_put32(ax_body, 1); ax_put32(ax_body, -1);
    ax_put32(ax_body, -1);                                 // no namespace on the element
    ax_put32(ax_body, name);
    ax_put16(ax_body, 20); ax_put16(ax_body, 20); ax_put16(ax_body, n); ax_put16(ax_body, 0); ax_put16(ax_body, 0); ax_put16(ax_body, 0);
    for k in 0..n {
        int i = order[k];
        if ax_t_ns[i] == 1 { ax_put32(ax_body, ax_ns_uri); } else { ax_put32(ax_body, -1); }
        ax_put32(ax_body, ax_t_name[i]);
        if ax_t_type[i] == 3 { ax_put32(ax_body, ax_t_data[i]); } else { ax_put32(ax_body, -1); }
        ax_put16(ax_body, 8); ax_body.push((char)0); ax_body.push((char)ax_t_type[i]);
        ax_put32(ax_body, ax_t_data[i]);
    }
    ax_t_n = 0;
}

void axml_close(String tag) {
    int name = ax_str(tag);
    ax_put16(ax_body, 259); ax_put16(ax_body, 16); ax_put32(ax_body, 24); ax_put32(ax_body, 1); ax_put32(ax_body, -1);
    ax_put32(ax_body, -1);
    ax_put32(ax_body, name);
}

// one string of the pool in UTF-16 (the text is UTF-8; characters up to 3 bytes)
int ax_utf16(String t, String out) {
    int n = 0;
    int i = 0;
    while i < t.len {
        int c = t[i] & 255;
        int cp = c;
        int extra = 0;
        if c >= 224 { cp = c & 15; extra = 2; } else if c >= 192 { cp = c & 31; extra = 1; }
        for q in 0..extra { i += 1; if i < t.len { cp = (cp << 6) | (t[i] & 63); } }
        i += 1;
        ax_put16(out, cp);
        n += 1;
    }
    return n;
}

String axml_end() {
    // the end of the namespace
    ax_put16(ax_body, 257); ax_put16(ax_body, 16); ax_put32(ax_body, 24); ax_put32(ax_body, 1); ax_put32(ax_body, -1);
    ax_put32(ax_body, ax_ns_prefix); ax_put32(ax_body, ax_ns_uri);
    // the string pool (UTF-16)
    String data = "";
    int[] offs = arr(ax_pool.len + 1);
    for i in 0..ax_pool.len {
        offs.push(data.len);
        String chars = "";
        int cn = ax_utf16(ax_pool[i], chars);
        ax_put16(data, cn);
        data.append(chars);
        ax_put16(data, 0);
    }
    while data.len % 4 != 0 { data.push((char)0); }
    int count = ax_pool.len;
    int strings_start = 28 + 4 * count;
    String pool = "";
    ax_put16(pool, 1); ax_put16(pool, 28); ax_put32(pool, strings_start + data.len);
    ax_put32(pool, count); ax_put32(pool, 0); ax_put32(pool, 0);           // string count, style count, flags (UTF-16)
    ax_put32(pool, strings_start); ax_put32(pool, 0);
    for i in 0..count { ax_put32(pool, offs[i]); }
    pool.append(data);
    // the resource map
    String map = "";
    ax_put16(map, 384); ax_put16(map, 8); ax_put32(map, 8 + 4 * ax_nres);
    for i in 0..ax_nres { ax_put32(map, ax_pool_id[i]); }
    // the file
    String out = "";
    int total = 8 + pool.len + map.len + ax_body.len;
    ax_put16(out, 3); ax_put16(out, 8); ax_put32(out, total);
    out.append(pool);
    out.append(map);
    out.append(ax_body);
    return out;
}
