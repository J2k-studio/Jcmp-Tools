# index.json

```json
{
  "format": 1,
  "packages": [
    {
      "name": "git",
      "version": "2.47.0",
      "arch": "aarch64",
      "url": "https://github.com/J2k-studio/Jcmp-pkg/releases/download/git-2.47.0/git-2.47.0-aarch64.tar.gz",
      "sha256": "<64 hex>",
      "size": 12345678,
      "unpacked": 45678901,
      "depends": ["zlib", "openssl"],
      "bin": ["bin/git"]
    }
  ]
}
```

* `jc install NAME`: pick the entries of NAME for this `arch`, install `depends` first, show `size`/`unpacked`, download, compare sha256 (a mismatch deletes the file and stops), unpack into `~/.jaric/pkg/NAME/VERSION`, link every `bin` entry into the Jaric `bin` folder.
* `jc remove NAME` removes the links and the folder. `jc list` shows what is installed.
* The archive has a top folder `usr/` laid out like the Jaric prefix (`bin lib etc share`).
