// DER (ASN.1) writer, the X.509 certificate of a P-256 key, and the PKCS#7 signature block of an apk (v1 signing).
#import <crypto>
#import <data>
#import "sign"

String d_hex(String h) {
    char buf[128];
    int n = Crypto::unhex(h, (char^)@buf);
    String r = "";
    for i in 0..n { r.push(buf[i]); }
    return r;
}
String d_tlv(int tag, String c) {
    String r = "";
    r.push((char)tag);
    int n = c.len;
    if n < 128 { r.push((char)n); }
    else if n < 256 { r.push((char)0x81); r.push((char)n); }
    else { r.push((char)0x82); r.push((char)(n >> 8)); r.push((char)(n & 255)); }
    r.append(c);
    return r;
}
String d_seq(String c) { return d_tlv(0x30, c); }
String d_set(String c) { return d_tlv(0x31, c); }
String d_oid(String hex) { return d_tlv(6, d_hex(hex)); }
// an unsigned big-endian number (32 bytes) as an INTEGER: leading zeros dropped, one 0 added when the top bit is set
String d_uint(char^ b, int n) {
    int i = 0;
    while i < n - 1 && b[i] == 0 { i += 1; }
    String c = "";
    if (b[i] & 128) != 0 { c.push((char)0); }
    while i < n { c.push(b[i]); i += 1; }
    return d_tlv(2, c);
}
String d_bits(String c) {
    String r = "";
    r.push((char)0);
    r.append(c);
    return d_tlv(3, r);
}
String d_sig(char^ r, char^ s) { return d_seq(d_uint(r, 32) + d_uint(s, 32)); }
String d_name() { return d_seq(d_set(d_seq(d_oid("550403") + d_tlv(0x0c, "apkj")))); }
String d_algo_sha256_ecdsa() { return d_seq(d_oid("2a8648ce3d040302")); }

String sha256_of(String s) {
    char h[32];
    Crypto::sha256(s.c(), s.len, (char^)@h);
    String r = "";
    for i in 0..32 { r.push(h[i]); }
    return r;
}

// the self-signed certificate (DER) of the key d
String x509_make(P256^ c, char^ d, char^ serial8) {
    char qx[32];
    char qy[32];
    p256_public(c, d, (char^)@qx, (char^)@qy);
    String point = "";
    point.push((char)4);
    for i in 0..32 { point.push(qx[i]); }
    for i in 0..32 { point.push(qy[i]); }
    String spki = d_seq(d_seq(d_oid("2a8648ce3d0201") + d_oid("2a8648ce3d030107")) + d_bits(point));
    char sn[8];
    for i in 0..8 { sn[i] = serial8[i]; }
    sn[0] = (char)(sn[0] & 0x7f);
    if sn[0] == 0 { sn[0] = (char)1; }
    String validity = d_seq(d_tlv(0x17, "250101000000Z") + d_tlv(0x18, "20750101000000Z"));
    String tbs = d_seq(d_tlv(0xa0, d_tlv(2, d_hex("02"))) + d_uint((char^)@sn, 8) + d_algo_sha256_ecdsa()
                       + d_name() + validity + d_name() + spki);
    char h[32];
    Crypto::sha256(tbs.c(), tbs.len, (char^)@h);
    char r[32];
    char s[32];
    p256_sign(c, d, (char^)@h, (char^)@r, (char^)@s);
    return d_seq(tbs + d_algo_sha256_ecdsa() + d_bits(d_sig((char^)@r, (char^)@s)));
}

// the serial number of a certificate made by x509_make (the INTEGER after the version)
int der_content(String s, int p) {
    int l = s[p + 1] & 255;
    if l == 0x81 { return p + 3; }
    if l == 0x82 { return p + 4; }
    return p + 2;
}
String x509_serial_der(String cert) {
    int q = der_content(cert, 0);             // into the certificate
    q = der_content(cert, q);                 // into the tbs part
    q += 5;                                   // the version  a0 03 02 01 02
    int n = cert[q + 1] & 255;
    return cert.slice(q, q + 2 + n) + "";
}

// the PKCS#7 SignedData (detached) of the signature file `sf`, made with the key d and its certificate
String pkcs7_make(P256^ c, char^ d, String cert, String sf) {
    char h[32];
    Crypto::sha256(sf.c(), sf.len, (char^)@h);
    char r[32];
    char s[32];
    p256_sign(c, d, (char^)@h, (char^)@r, (char^)@s);
    String sig = d_sig((char^)@r, (char^)@s);
    // the issuer is the name of the certificate, which is the same name
    String signer = d_seq(d_tlv(2, d_hex("01")) + d_seq(d_name() + x509_serial_der(cert)) + d_seq(d_oid("608648016503040201"))
                          + d_algo_sha256_ecdsa() + d_tlv(4, sig));
    String signed_data = d_seq(d_tlv(2, d_hex("01")) + d_set(d_seq(d_oid("608648016503040201"))) + d_seq(d_oid("2a864886f70d010701"))
                               + d_tlv(0xa0, cert) + d_set(signer));
    return d_seq(d_oid("2a864886f70d010702") + d_tlv(0xa0, signed_data));
}

// ---- the files of the v1 (JAR) signature
// a manifest line of at most 72 bytes: longer ones continue on the next line after a space
String jar_line(String key, String value) {
    String line = key + ": " + value;
    String r = "";
    int p = 0;
    int room = 70;
    while p < line.len {
        int e = p + room;
        if e > line.len { e = line.len; }
        r.append(line.slice(p, e));
        r.append("\r\n");
        p = e;
        if p < line.len { r.append(" "); }
        room = 69;
    }
    return r;
}
String jar_section(String name, String digest64) {
    return jar_line("Name", name) + jar_line("SHA-256-Digest", digest64) + "\r\n";
}
