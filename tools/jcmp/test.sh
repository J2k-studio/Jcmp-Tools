#!/bin/sh
# installs the files of dist/ in a temporary folder the way jget does (the program, and the folder Library next to it) and compiles a program
set -eu
cd "$(dirname "$0")"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cp dist/jcmp "$T/jcmp"; chmod +x "$T/jcmp"
( cd "$T" && tar xf "$OLDPWD/dist/jcmp-files.tar" )
printf 'void main() { cout << "hello from the tool\\n"; }\n' > "$T/h.jk"
( cd "$T" && ./jcmp h.jk -o h && [ "$(./h)" = "hello from the tool" ] ) || { echo "jcmp tool test: failed"; exit 1; }
echo "jcmp tool test: ok"
