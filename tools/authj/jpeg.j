// jpeg -- reads JPEG pictures (baseline and extended sequential Huffman, 8 bits: grey and YCbCr, any subsampling, restart markers).
//   #import <deflate>   #import <png>   #import "jpeg"
//   bool ok; Image im = Jpeg::decode(Fs::read_bytes("photo.jpg").unwrap(), @ok);   // the same Image as <png>: im.w, im.h, im.px (red, green, blue, alpha)
//   when ok is false, Jpeg::error() tells why (progressive pictures and CMYK are not read)
// The decoder keeps its state in global variables, so one picture is decoded at a time.

String jp_err;
String jp_data;
int jp_pos = 0;
int jp_bits = 0;
int jp_nbits = 0;
bool jp_hit = false;                       // a marker was met inside the data of a scan
int jp_q[256];                             // 4 quantisation tables, 64 values each, in natural order
int jp_zz[64];                             // zigzag position -> natural position
int jp_cnt[136];                           // Huffman tables 0..7 (class * 4 + id): the number of codes of each length 1..16
int jp_sym[2048];
int jp_min[136];
int jp_max[136];
int jp_ptr[136];
double jp_cos[64];
bool jp_init_done = false;

int jp_be16(String s, int at) { return ((s[at] & 255) << 8) | (s[at + 1] & 255); }

void jp_setup() {
    if jp_init_done { return; }
    jp_init_done = true;
    jp_err = "";
    jp_data = "";
    int z[64];
    z[0] = 0; z[1] = 1; z[2] = 8; z[3] = 16; z[4] = 9; z[5] = 2; z[6] = 3; z[7] = 10;
    z[8] = 17; z[9] = 24; z[10] = 32; z[11] = 25; z[12] = 18; z[13] = 11; z[14] = 4; z[15] = 5;
    z[16] = 12; z[17] = 19; z[18] = 26; z[19] = 33; z[20] = 40; z[21] = 48; z[22] = 41; z[23] = 34;
    z[24] = 27; z[25] = 20; z[26] = 13; z[27] = 6; z[28] = 7; z[29] = 14; z[30] = 21; z[31] = 28;
    z[32] = 35; z[33] = 42; z[34] = 49; z[35] = 56; z[36] = 57; z[37] = 50; z[38] = 43; z[39] = 36;
    z[40] = 29; z[41] = 22; z[42] = 15; z[43] = 23; z[44] = 30; z[45] = 37; z[46] = 44; z[47] = 51;
    z[48] = 58; z[49] = 59; z[50] = 52; z[51] = 45; z[52] = 38; z[53] = 31; z[54] = 39; z[55] = 46;
    z[56] = 53; z[57] = 60; z[58] = 61; z[59] = 54; z[60] = 47; z[61] = 55; z[62] = 62; z[63] = 63;
    for i in 0..64 { jp_zz[i] = z[i]; }
    for x in 0..8 {
        for u in 0..8 {
            double cu = 0.5;
            if u == 0 { cu = 0.35355339059327373; }
            jp_cos[x * 8 + u] = cu * Math::cos((double)(2 * x + 1) * (double)u * 3.141592653589793 / 16.0);
        }
    }
}

// one bit of the entropy-coded data (a stuffed FF 00 is a data byte FF; a marker ends the data and gives zeros)
int jp_bit() {
    if jp_nbits == 0 {
        int b = 0;
        if !jp_hit && jp_pos < jp_data.len {
            b = jp_data[jp_pos] & 255;
            jp_pos += 1;
            if b == 255 {
                int nb = 0;
                if jp_pos < jp_data.len { nb = jp_data[jp_pos] & 255; }
                if nb == 0 { jp_pos += 1; } else { jp_hit = true; jp_pos -= 1; b = 0; }
            }
        } else { jp_hit = true; }
        jp_bits = b;
        jp_nbits = 8;
    }
    jp_nbits -= 1;
    return (jp_bits >> jp_nbits) & 1;
}

int jp_receive(int n) {
    int v = 0;
    for i in 0..n { v = (v << 1) | jp_bit(); }
    return v;
}

int jp_extend(int v, int n) {
    if n == 0 { return 0; }
    if v < (1 << (n - 1)) { return v - (1 << n) + 1; }
    return v;
}

// the next symbol of the Huffman table t
int jp_huff(int t) {
    int code = 0;
    for l in 1..17 {
        code = (code << 1) | jp_bit();
        int mx = jp_max[t * 17 + l];
        if mx >= 0 && code <= mx && code >= jp_min[t * 17 + l] {
            return jp_sym[t * 256 + jp_ptr[t * 17 + l] + code - jp_min[t * 17 + l]];
        }
    }
    jp_err = "bad Huffman code";
    return 0 - 1;
}

// the table t is ready: the first and the last code of each length
void jp_build(int t) {
    int code = 0;
    int k = 0;
    for l in 1..17 {
        int n = jp_cnt[t * 17 + l];
        jp_ptr[t * 17 + l] = k;
        jp_min[t * 17 + l] = code;
        if n > 0 { jp_max[t * 17 + l] = code + n - 1; } else { jp_max[t * 17 + l] = 0 - 1; }
        code = (code + n) << 1;
        k += n;
    }
}

// the block of the component with the quantisation table q: decoded, de-quantised and inverse transformed into the plane at (px, py)
bool jp_block(char^ plane, int stride, int px, int py, int dct, int act, int q, int^ pred) {
    double blk[64];
    for i in 0..64 { blk[i] = 0.0; }
    int s = jp_huff(dct);
    if s < 0 { return false; }
    int diff = jp_extend(jp_receive(s), s);
    pred[0] = pred[0] + diff;
    blk[0] = (double)(pred[0] * jp_q[q * 64]);
    int k = 1;
    while k < 64 {
        int rs = jp_huff(act);
        if rs < 0 { return false; }
        int r = rs >> 4;
        int sz = rs & 15;
        if sz == 0 {
            if r == 15 { k += 16; continue; }
            break;
        }
        k += r;
        if k > 63 { jp_err = "bad block"; return false; }
        int v = jp_extend(jp_receive(sz), sz);
        int nat = jp_zz[k];
        blk[nat] = (double)(v * jp_q[q * 64 + nat]);
        k += 1;
    }
    // rows then columns: out[x][y] = sum over u, v of c(x, u) c(y, v) blk[v][u]
    double tmp[64];
    for v in 0..8 {
        for x in 0..8 {
            double sum = 0.0;
            for u in 0..8 { sum += jp_cos[x * 8 + u] * blk[v * 8 + u]; }
            tmp[v * 8 + x] = sum;
        }
    }
    for x in 0..8 {
        for y in 0..8 {
            double sum = 0.0;
            for v in 0..8 { sum += jp_cos[y * 8 + v] * tmp[v * 8 + x]; }
            int val = (int)(sum + 128.5);
            if sum + 128.5 < 0.0 { val = 0; }
            if val > 255 { val = 255; }
            plane[(py + y) * stride + px + x] = (char)val;
        }
    }
    return true;
}

// a part of the picture at the place (x, y) of the full size: the plane has fewer dots when it is subsampled, so the value is
// the linear mix of the 4 nearest dots (the centre of a dot of the plane is between the dots of the picture)
double jp_samp(char^ pl, int stride, int pw, int ph, int x, int y, int sh, int sv, int hmax, int vmax) {
    if sh == hmax && sv == vmax { return (double)(pl[y * stride + x] & 255); }
    double fx = ((double)x + 0.5) * (double)sh / (double)hmax - 0.5;
    double fy = ((double)y + 0.5) * (double)sv / (double)vmax - 0.5;
    if fx < 0.0 { fx = 0.0; }
    if fy < 0.0 { fy = 0.0; }
    int x0 = (int)fx; int y0 = (int)fy;
    double tx = fx - (double)x0; double ty = fy - (double)y0;
    int x1 = x0 + 1; int y1 = y0 + 1;
    if x1 > pw - 1 { x1 = pw - 1; }
    if y1 > ph - 1 { y1 = ph - 1; }
    double a = (double)(pl[y0 * stride + x0] & 255);
    double b = (double)(pl[y0 * stride + x1] & 255);
    double c = (double)(pl[y1 * stride + x0] & 255);
    double d = (double)(pl[y1 * stride + x1] & 255);
    return (a * (1.0 - tx) + b * tx) * (1.0 - ty) + (c * (1.0 - tx) + d * tx) * ty;
}

struct Jpeg {
    static String error() { return jp_err; }

    static Image decode(String data, bool^ ok) {
        Image im;
        ok[0] = false;
        im.w = 0; im.h = 0; im.px = "";
        jp_setup();
        jp_err = "";
        jp_data = data;
        jp_pos = 0; jp_bits = 0; jp_nbits = 0; jp_hit = false;
        if data.len < 4 || (data[0] & 255) != 255 || (data[1] & 255) != 216 { jp_err = "not a JPEG file"; return im; }
        for i in 0..256 { jp_q[i] = 1; }
        for i in 0..136 { jp_cnt[i] = 0; jp_max[i] = 0 - 1; jp_min[i] = 0; jp_ptr[i] = 0; }
        int w = 0; int h = 0; int nc = 0;
        int cid[4]; int ch[4]; int cv[4]; int cq[4];
        int cdc[4]; int cac[4];
        int hmax = 1; int vmax = 1;
        int restart = 0;
        String plane0 = ""; String plane1 = ""; String plane2 = "";
        int stride[4];
        int mcux = 0; int mcuy = 0;
        bool got_scan = false;
        int pos = 2;
        while pos + 4 <= data.len && !got_scan {
            if (data[pos] & 255) != 255 { pos += 1; continue; }
            int m = data[pos + 1] & 255;
            if m == 255 { pos += 1; continue; }
            if m == 0 || m == 1 || (m >= 208 && m <= 215) { pos += 2; continue; }
            if m == 216 { pos += 2; continue; }
            if m == 217 { break; }
            int len = jp_be16(data, pos + 2);
            int seg = pos + 4;
            int end = pos + 2 + len;
            if end > data.len { jp_err = "the file is cut"; return im; }
            if m == 192 || m == 193 {
                if (data[seg] & 255) != 8 { jp_err = "only 8 bits for each part are read"; return im; }
                h = jp_be16(data, seg + 1);
                w = jp_be16(data, seg + 3);
                nc = data[seg + 5] & 255;
                if nc != 1 && nc != 3 { jp_err = "only grey and 3-part pictures are read"; return im; }
                for c in 0..nc {
                    int at = seg + 6 + c * 3;
                    cid[c] = data[at] & 255;
                    ch[c] = (data[at + 1] & 255) >> 4;
                    cv[c] = data[at + 1] & 15;
                    cq[c] = data[at + 2] & 3;
                    if ch[c] > hmax { hmax = ch[c]; }
                    if cv[c] > vmax { vmax = cv[c]; }
                    if ch[c] < 1 || cv[c] < 1 || ch[c] > 4 || cv[c] > 4 { jp_err = "bad sampling"; return im; }
                }
            } else if m == 194 { jp_err = "progressive JPEG is not read yet (save it as a baseline JPEG or PNG)"; return im; }
            else if (m >= 195 && m <= 207 && m != 196 && m != 200 && m != 204) { jp_err = "this kind of JPEG (arithmetic or lossless) is not read"; return im; }
            else if m == 196 {
                int at = seg;
                while at < end {
                    int tc = data[at] & 255;
                    int t = ((tc >> 4) & 1) * 4 + (tc & 3);
                    at += 1;
                    int total = 0;
                    for l in 1..17 { jp_cnt[t * 17 + l] = data[at + l - 1] & 255; total += jp_cnt[t * 17 + l]; }
                    at += 16;
                    if total > 256 { jp_err = "bad Huffman table"; return im; }
                    for i in 0..total { jp_sym[t * 256 + i] = data[at + i] & 255; }
                    at += total;
                    jp_build(t);
                }
            } else if m == 219 {
                int at = seg;
                while at < end {
                    int pq = (data[at] & 255) >> 4;
                    int tq = data[at] & 3;
                    at += 1;
                    for i in 0..64 {
                        int v = 0;
                        if pq == 0 { v = data[at] & 255; at += 1; } else { v = jp_be16(data, at); at += 2; }
                        jp_q[tq * 64 + jp_zz[i]] = v;
                    }
                }
            } else if m == 221 {
                restart = jp_be16(data, seg);
            } else if m == 218 {
                if w == 0 || h == 0 { jp_err = "a scan before the frame"; return im; }
                int ns = data[seg] & 255;
                if ns != nc { jp_err = "only pictures in one scan are read"; return im; }
                for s in 0..ns {
                    int id = data[seg + 1 + s * 2] & 255;
                    int tt = data[seg + 2 + s * 2] & 255;
                    for c in 0..nc { if cid[c] == id { cdc[c] = tt >> 4; cac[c] = tt & 3; } }
                }
                mcux = (w + 8 * hmax - 1) / (8 * hmax);
                mcuy = (h + 8 * vmax - 1) / (8 * vmax);
                for c in 0..nc { stride[c] = mcux * ch[c] * 8; }
                int planes[4];
                int psize[4];
                int ptotal = 0;
                for c in 0..nc { psize[c] = stride[c] * mcuy * cv[c] * 8; ptotal += psize[c] + 16; }
                char^ pbuf = (char^)alloc(ptotal);                       // all the planes in one block: it is freed when this block ends
                int pat = 0;
                for c in 0..nc {
                    planes[c] = (int)pbuf + pat;
                    for i in 0..psize[c] { pbuf[pat + i] = (char)128; }
                    pat += psize[c] + 16;
                }
                jp_pos = end; jp_nbits = 0; jp_hit = false;
                int pred[4];
                for c in 0..4 { pred[c] = 0; }
                int total_mcu = mcux * mcuy;
                int mi = 0;
                while mi < total_mcu {
                    if restart > 0 && mi > 0 && mi % restart == 0 {
                        // the data of one restart interval ends on a byte; the marker FF Dn follows
                        jp_nbits = 0; jp_hit = false;
                        while jp_pos + 1 < data.len && !((data[jp_pos] & 255) == 255 && (data[jp_pos + 1] & 255) >= 208 && (data[jp_pos + 1] & 255) <= 215) { jp_pos += 1; }
                        jp_pos += 2;
                        for c in 0..4 { pred[c] = 0; }
                    }
                    int mx = mi % mcux;
                    int my = mi / mcux;
                    for c in 0..nc {
                        for bv in 0..cv[c] {
                            for bh in 0..ch[c] {
                                int px = (mx * ch[c] + bh) * 8;
                                int py = (my * cv[c] + bv) * 8;
                                int pr[1];
                                pr[0] = pred[c];
                                char^ pl = (char^)planes[c];
                                if !jp_block(pl, stride[c], px, py, cdc[c], 4 + cac[c], cq[c], @pr) { if jp_err == "" { jp_err = "bad data"; } return im; }
                                pred[c] = pr[0];
                            }
                        }
                    }
                    mi += 1;
                }
                got_scan = true;
                // to red, green, blue, alpha
                String px = "";
                for i in 0..(w * h * 4) { px.push((char)255); }
                for y in 0..h {
                    for x in 0..w {
                        int o = (y * w + x) * 4;
                        char^ p0 = (char^)planes[0];
                        double yy = jp_samp(p0, stride[0], (w * ch[0] + hmax - 1) / hmax, (h * cv[0] + vmax - 1) / vmax, x, y, ch[0], cv[0], hmax, vmax);
                        if nc == 1 {
                            int g = (int)yy;
                            px[o] = (char)g; px[o + 1] = (char)g; px[o + 2] = (char)g;
                        } else {
                            char^ p1 = (char^)planes[1];
                            char^ p2 = (char^)planes[2];
                            double cb = jp_samp(p1, stride[1], (w * ch[1] + hmax - 1) / hmax, (h * cv[1] + vmax - 1) / vmax, x, y, ch[1], cv[1], hmax, vmax) - 128.0;
                            double cr = jp_samp(p2, stride[2], (w * ch[2] + hmax - 1) / hmax, (h * cv[2] + vmax - 1) / vmax, x, y, ch[2], cv[2], hmax, vmax) - 128.0;
                            int r = (int)(yy + 1.402 * cr + 0.5);
                            int g = (int)(yy - 0.344136 * cb - 0.714136 * cr + 0.5);
                            int b = (int)(yy + 1.772 * cb + 0.5);
                            if r < 0 { r = 0; } if r > 255 { r = 255; }
                            if g < 0 { g = 0; } if g > 255 { g = 255; }
                            if b < 0 { b = 0; } if b > 255 { b = 255; }
                            px[o] = (char)r; px[o + 1] = (char)g; px[o + 2] = (char)b;
                        }
                    }
                }
                im.w = w; im.h = h; im.px = px;
                ok[0] = true;
                return im;
            }
            pos = end;
        }
        if jp_err == "" { jp_err = "no picture data in the file"; }
        return im;
    }
}
