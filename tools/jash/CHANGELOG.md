# jash changelog

## 0.1.0
* The settings file of the programs of Jaric, `~/.jash` (`JASH_FILE` names another): first line `[#jash]`, then `[section]` and `key = value` lines. The command: `jash list [SECTION]`, `get SECTION.KEY`, `set SECTION.KEY VALUE`, `unset`, `edit`, `path`, `import` (takes in `$PREFIX/etc/config.local`, `theme.toml` and the `JSH_COLOR_*` of `~/.jshrc`), `reset` (keeps `.jash.old`).
