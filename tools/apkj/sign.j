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
    Crypto::unhex(Crypto::ec_const(256, 0), @buf);
    Crypto::bn_from_bytes(@c^.pm, 10, @buf, 32);
    Crypto::unhex(Crypto::ec_const(256, 1), @buf);
    Crypto::bn_from_bytes(@c^.nm, 10, @buf, 32);
    c^.pn0 = Crypto::mont_setup(@c^.pm, 10, @c^.prr);
    c^.nn0 = Crypto::mont_setup(@c^.nm, 10, @c^.nrr);
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
    Crypto::mont_mul(@g, gx, @c^.prr, @c^.pm, 10, c^.pn0);
    Crypto::mont_mul(@g + 128, gy, @c^.prr, @c^.pm, 10, c^.pn0);
    Crypto::mont_mul(@g + 256, @one, @c^.prr, @c^.pm, 10, c^.pn0);
    int r[48];
    Crypto::ec_mul(@r, k, 10, @g, @c^.ctx);
    if Crypto::bn_is_zero(@r + 256, 10) { return false; }
    char pm2[48];
    Crypto::unhex(Crypto::ec_const(256, 0), @pm2);
    pm2[31] = (char)(pm2[31] - 2);
    int zi[16];
    int zi2[16];
    int zi3[16];
    Crypto::mont_pow(@zi, @r + 256, @pm2, 32, @c^.pm, 10, @c^.prr, c^.pn0);
    Crypto::mont_mul(@zi, @zi, @c^.prr, @c^.pm, 10, c^.pn0);
    Crypto::mont_mul(@zi, @zi, @c^.prr, @c^.pm, 10, c^.pn0);
    Crypto::mont_mul(@zi2, @zi, @zi, @c^.pm, 10, c^.pn0);
    Crypto::mont_mul(@zi3, @zi2, @zi, @c^.pm, 10, c^.pn0);
    int xa[16];
    int ya[16];
    Crypto::mont_mul(@xa, @r, @zi2, @c^.pm, 10, c^.pn0);
    Crypto::mont_mul(@xa, @xa, @one, @c^.pm, 10, c^.pn0);
    Crypto::mont_mul(@ya, @r + 128, @zi3, @c^.pm, 10, c^.pn0);
    Crypto::mont_mul(@ya, @ya, @one, @c^.pm, 10, c^.pn0);
    Crypto::bn_to_bytes(@xa, 10, xo, 32);
    Crypto::bn_to_bytes(@ya, 10, yo, 32);
    return true;
}

void p256_base(P256^ c, int^ gx, int^ gy) {
    char buf[48];
    Crypto::unhex(Crypto::ec_const(256, 2), @buf);
    Crypto::bn_from_bytes(gx, 10, @buf, 32);
    Crypto::unhex(Crypto::ec_const(256, 3), @buf);
    Crypto::bn_from_bytes(gy, 10, @buf, 32);
}

// a fresh private key: 32 random bytes, below n and not zero
void p256_new_key(P256^ c, char^ d) {
    int x[16];
    while true {
        Sys::random(d, 32);
        Crypto::bn_from_bytes(@x, 10, d, 32);
        if !Crypto::bn_is_zero(@x, 10) && Crypto::bn_cmp(@x, @c^.nm, 10) < 0 { return; }
    }
}

// the public key (x, y as 32 bytes each) of the private key d
bool p256_public(P256^ c, char^ d, char^ xo, char^ yo) {
    int gx[16];
    int gy[16];
    int k[16];
    p256_base(c, @gx, @gy);
    Crypto::bn_from_bytes(@k, 10, d, 32);
    return p256_mul(c, @k, @gx, @gy, xo, yo);
}

// signs the 32-byte hash e with the private key d; r and s as 32 bytes. k is derived from d and e (sha256, counter),
// so the same message gives the same signature (the dangerous thing in ECDSA is a repeated k for two messages).
void p256_sign(P256^ c, char^ d, char^ hash, char^ rout, char^ sout) {
    int gx[16];
    int gy[16];
    p256_base(c, @gx, @gy);
    char seed[100];
    for i in 0..32 { seed[i] = d[i]; seed[32 + i] = hash[i]; }
    int counter = 0;
    while true {
        seed[64] = (char)counter;
        char kb[32];
        Crypto::sha256(@seed, 65, @kb);
        counter += 1;
        int k[16];
        Crypto::bn_from_bytes(@k, 10, @kb, 32);
        if Crypto::bn_is_zero(@k, 10) || Crypto::bn_cmp(@k, @c^.nm, 10) >= 0 { continue; }
        char xb[32];
        char yb[32];
        if !p256_mul(c, @k, @gx, @gy, @xb, @yb) { continue; }
        int r[16];
        Crypto::bn_from_bytes(@r, 10, @xb, 32);
        if Crypto::bn_cmp(@r, @c^.nm, 10) >= 0 { Crypto::bn_sub(@r, @c^.nm, 10); }
        if Crypto::bn_is_zero(@r, 10) { continue; }
        // s = k^-1 (e + r d) mod n
        int e[16];
        int dd[16];
        Crypto::bn_from_bytes(@e, 10, hash, 32);
        if Crypto::bn_cmp(@e, @c^.nm, 10) >= 0 { Crypto::bn_sub(@e, @c^.nm, 10); }
        Crypto::bn_from_bytes(@dd, 10, d, 32);
        int t[16];
        int u[16];
        Crypto::mont_mul(@t, @r, @c^.nrr, @c^.nm, 10, c^.nn0);      // r in the Montgomery form
        Crypto::mont_mul(@u, @t, @dd, @c^.nm, 10, c^.nn0);          // r d (normal)
        Crypto::fe_add(@u, @u, @e, @c^.nm, 10);
        char n2[48];
        Crypto::unhex(Crypto::ec_const(256, 1), @n2);
        n2[31] = (char)(n2[31] - 2);
        int ki[16];
        Crypto::mont_pow(@ki, @k, @n2, 32, @c^.nm, 10, @c^.nrr, c^.nn0);
        Crypto::mont_mul(@t, @u, @c^.nrr, @c^.nm, 10, c^.nn0);
        int s[16];
        Crypto::mont_mul(@s, @t, @ki, @c^.nm, 10, c^.nn0);
        if Crypto::bn_is_zero(@s, 10) { continue; }
        Crypto::bn_to_bytes(@r, 10, rout, 32);
        Crypto::bn_to_bytes(@s, 10, sout, 32);
        return;
    }
}
