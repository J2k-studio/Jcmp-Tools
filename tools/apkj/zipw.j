// zipw.j -- a writer of zip files (the part of apkj that packs the apk): stored or deflated entries, CRC-32, the central directory.
//   zip_begin();  zip_add("AndroidManifest.xml", data, false);  zip_add("classes.dex", dex, true);  String z = zip_end();
// The bytes of a file live in a String (it may hold any byte; read one as  s[i] & 255).
#import <deflate>

String zip_out;
String[] zip_names;
int[] zip_off;
int[] zip_crc;
int[] zip_size;
int[] zip_csize;
int[] zip_method;

void zip_put16(String s, int v) {
    s.push((char)(v & 255));
    s.push((char)((v >> 8) & 255));
}

void zip_put32(String s, int v) {
    s.push((char)(v & 255));
    s.push((char)((v >> 8) & 255));
    s.push((char)((v >> 16) & 255));
    s.push((char)((v >> 24) & 255));
}

void zip_begin() {
    zip_out = "";
    zip_names = arr(16);
    zip_off = arr(16);
    zip_crc = arr(16);
    zip_size = arr(16);
    zip_csize = arr(16);
    zip_method = arr(16);
}

// one file; deflated only when that makes it smaller
void zip_add(String name, String data, bool deflate) {
    int crc = Crc32::of(data);
    String body = data + "";
    int method = 0;
    if deflate && data.len > 64 {
        String c = Deflate::compress(data);
        if c.len < data.len { body = c; method = 8; }
    }
    zip_names.push(name + "");
    zip_off.push(zip_out.len);
    zip_crc.push(crc);
    zip_size.push(data.len);
    zip_csize.push(body.len);
    zip_method.push(method);
    zip_put32(zip_out, 67324752);               // 0x04034b50: a local file header
    zip_put16(zip_out, 20);                     // version needed
    zip_put16(zip_out, 2048);                   // flags: the names are UTF-8
    zip_put16(zip_out, method);
    zip_put16(zip_out, 0);                      // time 00:00
    zip_put16(zip_out, 33);                     // date 1980-01-01
    zip_put32(zip_out, crc);
    zip_put32(zip_out, body.len);
    zip_put32(zip_out, data.len);
    zip_put16(zip_out, name.len);
    zip_put16(zip_out, 0);                      // no extra field
    zip_out.append(name);
    zip_out.append(body);
}

// the central directory and the end record; gives the whole file
String zip_end() {
    int start = zip_out.len;
    for i in 0..zip_names.len {
        zip_put32(zip_out, 33639248);           // 0x02014b50: a central directory header
        zip_put16(zip_out, 20);                 // made by
        zip_put16(zip_out, 20);                 // version needed
        zip_put16(zip_out, 2048);
        zip_put16(zip_out, zip_method[i]);
        zip_put16(zip_out, 0);
        zip_put16(zip_out, 33);
        zip_put32(zip_out, zip_crc[i]);
        zip_put32(zip_out, zip_csize[i]);
        zip_put32(zip_out, zip_size[i]);
        zip_put16(zip_out, zip_names[i].len);
        zip_put16(zip_out, 0);                  // extra
        zip_put16(zip_out, 0);                  // comment
        zip_put16(zip_out, 0);                  // disk
        zip_put16(zip_out, 0);                  // internal attributes
        zip_put32(zip_out, 0);                  // external attributes
        zip_put32(zip_out, zip_off[i]);
        zip_out.append(zip_names[i]);
    }
    int size = zip_out.len - start;
    zip_put32(zip_out, 101010256);              // 0x06054b50: the end record
    zip_put16(zip_out, 0);
    zip_put16(zip_out, 0);
    zip_put16(zip_out, zip_names.len);
    zip_put16(zip_out, zip_names.len);
    zip_put32(zip_out, size);
    zip_put32(zip_out, start);
    zip_put16(zip_out, 0);
    return zip_out + "";
}
