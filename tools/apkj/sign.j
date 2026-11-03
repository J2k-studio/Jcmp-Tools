// ECDSA signing on P-256 (FIPS 186-4), built on the number code of <crypto> (which only checks signatures).
// All numbers are 32-byte big-endian arrays on the outside. Nothing here is constant-time: it signs apks on the
// developer's own machine, not secrets for a network peer.
#import <crypto>

// the curve: the context for ec_mul / ec_add (p, R^2 mod p, n0, limbs) and the numbers n, R^2 mod n
struct P256 {
    int pm[16];
    int prr[16];
    int nm[16];
    int nrr[16];
    int ctx[40];
    int pn0;
    int nn0;
    int n;
}

void p256_init(P256^ c) {
    char buf[48];
    c^.n = 10;
    Crypto::unhex(Crypto::ec_const(256, 0), (char^)@buf);
    Crypto::bn_from_bytes((int^)@c^.pm, 10, (char^)@buf, 32);
    Crypto::unhex(Crypto::ec_const(256, 1), (char^)@buf);
    Crypto::bn_from_bytes((int^)@c^.nm, 10, (char^)@buf, 32);
    c^.pn0 = Crypto::mont_setup((int^)@c^.pm, 10, (int^)@c^.prr);
    c^.nn0 = Crypto::mont_setup((int^)@c^.nm, 10, (int^)@c^.nrr);
    for i in 0..16 { c^.ctx[i] = c^.pm[i]; c^.ctx[16 + i] = c^.prr[i]; }
    c^.ctx[32] = c^.pn0;
    c^.ctx[33] = 10;
}

// k * point, with the point given as affine (x, y) normal-form numbers (limbs); the result as affine bytes. false: infinity.
bool p256_mul(P256^ c, int^ k, int^ gx, int^ gy, char^ xo, char^ yo) {
    int one[16];
    for i in 0..16 { one[i] = 0; }
    one[0] = 1;
    int g[48];
    for i in 0..48 { g[i] = 0; }
    Crypto::mont_mul((int^)@g, gx, (int^)@c^.prr, (int^)@c^.pm, 10, c^.pn0);
    Crypto::mont_mul((int^)@g + 128, gy, (int^)@c^.prr, (int^)@c^.pm, 10, c^.pn0);
    Crypto::mont_mul((int^)@g + 256, (int^)@one, (int^)@c^.prr, (int^)@c^.pm, 10, c^.pn0);
    int r[48];
    Crypto::ec_mul((int^)@r, k, 10, (int^)@g, (int^)@c^.ctx);
    if Crypto::bn_is_zero((int^)@r + 256, 10) { return false; }
    char pm2[48];
    Crypto::unhex(Crypto::ec_const(256, 0), (char^)@pm2);
    pm2[31] = (char)(pm2[31] - 2);
    int zi[16];
    int zi2[16];
    int zi3[16];
    Crypto::mont_pow((int^)@zi, (int^)@r + 256, (char^)@pm2, 32, (int^)@c^.pm, 10, (int^)@c^.prr, c^.pn0);
    Crypto::mont_mul((int^)@zi, (int^)@zi, (int^)@c^.prr, (int^)@c^.pm, 10, c^.pn0);
    Crypto::mont_mul((int^)@zi, (int^)@zi, (int^)@c^.prr, (int^)@c^.pm, 10, c^.pn0);
    Crypto::mont_mul((int^)@zi2, (int^)@zi, (int^)@zi, (int^)@c^.pm, 10, c^.pn0);
    Crypto::mont_mul((int^)@zi3, (int^)@zi2, (int^)@zi, (int^)@c^.pm, 10, c^.pn0);
    int xa[16];
    int ya[16];
    Crypto::mont_mul((int^)@xa, (int^)@r, (int^)@zi2, (int^)@c^.pm, 10, c^.pn0);
    Crypto::mont_mul((int^)@xa, (int^)@xa, (int^)@one, (int^)@c^.pm, 10, c^.pn0);
    Crypto::mont_mul((int^)@ya, (int^)@r + 128, (int^)@zi3, (int^)@c^.pm, 10, c^.pn0);
    Crypto::mont_mul((int^)@ya, (int^)@ya, (int^)@one, (int^)@c^.pm, 10, c^.pn0);
    Crypto::bn_to_bytes((int^)@xa, 10, xo, 32);
    Crypto::bn_to_bytes((int^)@ya, 10, yo, 32);
    return true;
}

void p256_base(P256^ c, int^ gx, int^ gy) {
    char buf[48];
    Crypto::unhex(Crypto::ec_const(256, 2), (char^)@buf);
    Crypto::bn_from_bytes(gx, 10, (char^)@buf, 32);
    Crypto::unhex(Crypto::ec_const(256, 3), (char^)@buf);
    Crypto::bn_from_bytes(gy, 10, (char^)@buf, 32);
}

// a fresh private key: 32 random bytes, below n and not zero
void p256_new_key(P256^ c, char^ d) {
    int x[16];
    while true {
        Sys::random(d, 32);
        Crypto::bn_from_bytes((int^)@x, 10, d, 32);
        if !Crypto::bn_is_zero((int^)@x, 10) && Crypto::bn_cmp((int^)@x, (int^)@c^.nm, 10) < 0 { return; }
    }
}

// the public key (x, y as 32 bytes each) of the private key d
bool p256_public(P256^ c, char^ d, char^ xo, char^ yo) {
    int gx[16];
    int gy[16];
    int k[16];
    p256_base(c, (int^)@gx, (int^)@gy);
    Crypto::bn_from_bytes((int^)@k, 10, d, 32);
    return p256_mul(c, (int^)@k, (int^)@gx, (int^)@gy, xo, yo);
}

// signs the 32-byte hash e with the private key d; r and s as 32 bytes. k is derived from d and e (sha256, counter),
// so the same message gives the same signature (the dangerous thing in ECDSA is a repeated k for two messages).
void p256_sign(P256^ c, char^ d, char^ hash, char^ rout, char^ sout) {
    int gx[16];
    int gy[16];
    p256_base(c, (int^)@gx, (int^)@gy);
    char seed[100];
    for i in 0..32 { seed[i] = d[i]; seed[32 + i] = hash[i]; }
    int counter = 0;
    while true {
        seed[64] = (char)counter;
        char kb[32];
        Crypto::sha256((char^)@seed, 65, (char^)@kb);
        counter += 1;
        int k[16];
        Crypto::bn_from_bytes((int^)@k, 10, (char^)@kb, 32);
        if Crypto::bn_is_zero((int^)@k, 10) || Crypto::bn_cmp((int^)@k, (int^)@c^.nm, 10) >= 0 { continue; }
        char xb[32];
        char yb[32];
        if !p256_mul(c, (int^)@k, (int^)@gx, (int^)@gy, (char^)@xb, (char^)@yb) { continue; }
        int r[16];
        Crypto::bn_from_bytes((int^)@r, 10, (char^)@xb, 32);
        if Crypto::bn_cmp((int^)@r, (int^)@c^.nm, 10) >= 0 { Crypto::bn_sub((int^)@r, (int^)@c^.nm, 10); }
        if Crypto::bn_is_zero((int^)@r, 10) { continue; }
        // s = k^-1 (e + r d) mod n
        int e[16];
        int dd[16];
        Crypto::bn_from_bytes((int^)@e, 10, hash, 32);
        if Crypto::bn_cmp((int^)@e, (int^)@c^.nm, 10) >= 0 { Crypto::bn_sub((int^)@e, (int^)@c^.nm, 10); }
        Crypto::bn_from_bytes((int^)@dd, 10, d, 32);
        int t[16];
        int u[16];
        Crypto::mont_mul((int^)@t, (int^)@r, (int^)@c^.nrr, (int^)@c^.nm, 10, c^.nn0);      // r in the Montgomery form
        Crypto::mont_mul((int^)@u, (int^)@t, (int^)@dd, (int^)@c^.nm, 10, c^.nn0);          // r d (normal)
        Crypto::fe_add((int^)@u, (int^)@u, (int^)@e, (int^)@c^.nm, 10);
        char n2[48];
        Crypto::unhex(Crypto::ec_const(256, 1), (char^)@n2);
        n2[31] = (char)(n2[31] - 2);
        int ki[16];
        Crypto::mont_pow((int^)@ki, (int^)@k, (char^)@n2, 32, (int^)@c^.nm, 10, (int^)@c^.nrr, c^.nn0);
        Crypto::mont_mul((int^)@t, (int^)@u, (int^)@c^.nrr, (int^)@c^.nm, 10, c^.nn0);
        int s[16];
        Crypto::mont_mul((int^)@s, (int^)@t, (int^)@ki, (int^)@c^.nm, 10, c^.nn0);
        if Crypto::bn_is_zero((int^)@s, 10) { continue; }
        Crypto::bn_to_bytes((int^)@r, 10, rout, 32);
        Crypto::bn_to_bytes((int^)@s, 10, sout, 32);
        return;
    }
}
