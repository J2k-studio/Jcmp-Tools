[
 {
  "name": "ca-certificates",
  "version": "1:2026.10.20-1",
  "arch": "aarch64",
  "url": "https://github.com/J2k-studio/Jcmp-pkg/releases/download/pkg-dropbear/ca-certificates-1.2026.10.20-1-aarch64.tar.gz",
  "sha256": "b0e7182f5882c4e8455ce6651e67bb6cebf3d8b4a29129f4ad3950cbf92c63c8",
  "size": 115900,
  "unpacked": 200116,
  "depends": [],
  "bin": []
 },
 {
  "name": "dropbear",
  "version": "2026.94",
  "arch": "aarch64",
  "url": "https://github.com/J2k-studio/Jcmp-pkg/releases/download/pkg-dropbear/dropbear-2026.94-aarch64.tar.gz",
  "sha256": "6aadf725e9710a356da3b608ca3f94c2964f4d78da0f9eec3cc07198a41440b0",
  "size": 182682,
  "unpacked": 691830,
  "depends": [
   "termux-auth",
   "zlib"
  ],
  "bin": [
   "bin/dbclient",
   "bin/dropbear",
   "bin/dropbearconvert",
   "bin/dropbearkey",
   "bin/dropbearmulti",
   "bin/scp",
   "bin/ssh"
  ]
 },
 {
  "name": "openssl",
  "version": "1:3.6.5",
  "arch": "aarch64",
  "url": "https://github.com/J2k-studio/Jcmp-pkg/releases/download/pkg-dropbear/openssl-1.3.6.5-aarch64.tar.gz",
  "sha256": "919230d72fe10bd681bcf219f5d6f42d517f642f1b0c1680622542fcc5cee6a7",
  "size": 3186267,
  "unpacked": 14393768,
  "depends": [
   "ca-certificates",
   "zlib"
  ],
  "bin": []
 },
 {
  "name": "termux-auth",
  "version": "1.5.0-1",
  "arch": "aarch64",
  "url": "https://github.com/J2k-studio/Jcmp-pkg/releases/download/pkg-dropbear/termux-auth-1.5.0-1-aarch64.tar.gz",
  "sha256": "dbb25cb717c613836e0ced839a8961614cb71e3d64846b71922aa9a8f1910c12",
  "size": 7625,
  "unpacked": 24074,
  "depends": [
   "openssl"
  ],
  "bin": [
   "bin/passwd",
   "bin/pwlogin"
  ]
 },
 {
  "name": "zlib",
  "version": "1.3.2",
  "arch": "aarch64",
  "url": "https://github.com/J2k-studio/Jcmp-pkg/releases/download/pkg-dropbear/zlib-1.3.2-aarch64.tar.gz",
  "sha256": "b64565a12b636e003a9aea74c3ac2dc931831b997addf530450d326ba0ca6fc1",
  "size": 74943,
  "unpacked": 343338,
  "depends": [],
  "bin": []
 }
]