#!/bin/sh
# ascode with a scripted model: the tools, the modes ask / read / auto, the edit that must be unique, help lines of at most 38 characters
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
[ "$(./_out/ascode --version)" = "ascode $(cat VERSION)" ] || { echo "ascode test: --version differs from VERSION"; exit 1; }
long=$(./_out/ascode --help | awk 'length($0) > 38' | wc -l)
[ "$long" = 0 ] || { echo "ascode test: a line of --help is longer than 38 characters"; exit 1; }
A="$PWD/_out/ascode"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
cat > s.txt <<'S'
tool write a.txt | one two\nthree two\n
tool edit a.txt | two | 2
tool edit a.txt | one | 1
tool run echo hi
done
S
# auto: the changes inside the folder are done; "two" is in the file twice, so that edit is refused as a guess
"$A" --model mock:s.txt --mode auto go > out.txt 2>&1 </dev/null
[ "$(cat a.txt)" = "$(printf '1 two\nthree two')" ] || { echo "ascode test: auto changed the file wrongly: $(cat a.txt)"; exit 1; }
grep -q "2 times" out.txt || { echo "ascode test: a second place must be refused"; exit 1; }
grep -q "^hi" out.txt || { echo "ascode test: run gave no output"; exit 1; }
# read: nothing is changed
rm a.txt
"$A" --model mock:s.txt --mode read go > out2.txt 2>&1 </dev/null
[ ! -f a.txt ] || { echo "ascode test: read mode wrote a file"; exit 1; }
grep -q "refused (mode read)" out2.txt || { echo "ascode test: no refusal in read mode"; exit 1; }
# ask: the person says y to the write and n to the next change
printf 'y\nn\nn\nn\n' | "$A" --model mock:s.txt --mode ask go > out3.txt 2>&1
[ -f a.txt ] || { echo "ascode test: ask y did not write"; exit 1; }
[ "$(cat a.txt)" = "$(printf 'one two\nthree two')" ] || { echo "ascode test: ask n changed the file: $(cat a.txt)"; exit 1; }
HOME="$T/nokey" "$A" --mode auto go >/dev/null 2>&1 </dev/null && { echo "ascode test: no key must fail"; exit 1; }
# the model claude against a server on this machine: a tool is asked, done, its result sent back with the answer of the model unchanged
cat > srv.py <<'PY'
import http.server, json, sys
log = open('req.log', 'a')
class H(http.server.BaseHTTPRequestHandler):
    n = 0
    def answer(s, out):
        b = json.dumps(out).encode()
        s.send_response(200); s.send_header('content-type', 'application/json'); s.send_header('content-length', str(len(b))); s.end_headers(); s.wfile.write(b)
    def do_GET(s):
        log.write(json.dumps({'path': s.path, 'headers': {k.lower(): v for k, v in s.headers.items()}}) + '\n'); log.flush()
        s.answer({'data': [{'id': 'vendor/small-model'}, {'id': 'vendor/big-model'}, {'id': 'other/model-z'}]})
    def do_POST(s):
        body = s.rfile.read(int(s.headers['content-length'])).decode()
        if s.path.endswith('/chat/completions'):
            j = json.loads(body)
            log.write(json.dumps({'path': s.path, 'headers': {k.lower(): v for k, v in s.headers.items()}, 'body': j}) + '\n'); log.flush()
            if j['messages'][-1]['role'] == 'user':
                s.answer({'choices': [{'finish_reason': 'tool_calls', 'message': {'role': 'assistant', 'content': None, 'tool_calls': [{'id': 'call_9', 'type': 'function', 'function': {'name': 'write', 'arguments': json.dumps({'path': 'oa.txt', 'content': 'from {"oa"}\n'})}}]}}]})
            else:
                s.answer({'choices': [{'finish_reason': 'stop', 'message': {'role': 'assistant', 'content': 'oa done'}}]})
            return
        log.write(json.dumps({'headers': {k.lower(): v for k, v in s.headers.items()}, 'body': json.loads(body)}) + '\n'); log.flush()
        if '"boom"' in body.split('"messages"')[1]:
            b = b'{"type":"error","error":{"message":"overloaded"}}'
            s.send_response(529); s.send_header('content-length', str(len(b))); s.end_headers(); s.wfile.write(b); return
        H.n += 1
        if H.n == 1:
            out = {'stop_reason': 'tool_use', 'content': [{'type': 'thinking', 'thinking': '', 'signature': 'abc=='},
                   {'type': 'text', 'text': 'I will write it.'}, {'type': 'tool_use', 'id': 'tu_1', 'name': 'write', 'input': {'path': 'made.txt', 'content': 'hi \u0e2a\n"q"\n'}}]}
        else:
            out = {'stop_reason': 'end_turn', 'content': [{'type': 'text', 'text': 'done: made.txt'}]}
        b = json.dumps(out).encode()
        s.send_response(200); s.send_header('content-type', 'application/json'); s.send_header('content-length', str(len(b))); s.end_headers(); s.wfile.write(b)
    def log_message(s, *a): pass
srv = http.server.HTTPServer(('127.0.0.1', 0), H)
open('port', 'w').write(str(srv.server_port)); srv.serve_forever()
PY
python3 srv.py & SRV=$!; trap 'kill $SRV 2>/dev/null; rm -rf "$T"' EXIT
for i in 1 2 3 4 5 6 7 8 9 10; do [ -s port ] && break; sleep 0.3; done
ASCODE_API_URL="http://127.0.0.1:$(cat port)/v1/messages" ANTHROPIC_API_KEY=test-key-123 "$A" --mode auto "write a file" > out4.txt 2>&1 </dev/null || { echo "ascode test: claude: $(cat out4.txt)"; exit 1; }
grep -q "done: made.txt" out4.txt || { echo "ascode test: claude answer: $(cat out4.txt)"; exit 1; }
grep -q "test-key-123" out4.txt && { echo "ascode test: the key was printed"; exit 1; }
python3 - <<'PY' || { echo "ascode test: the requests"; exit 1; }
import json
r = [json.loads(l) for l in open('req.log')]
a, b = r[0], r[1]
assert a['headers']['x-api-key'] == 'test-key-123' and a['headers']['anthropic-version'] and 'server-side-fallback' in a['headers']['anthropic-beta']
assert a['body']['model'] == 'claude-opus-5-5' and a['body']['fallbacks'] == 'default' and a['body']['max_tokens'] == 16000
assert [t['name'] for t in a['body']['tools']] == ['read', 'list', 'search', 'write', 'edit', 'run']
m = b['body']['messages']
assert [x['role'] for x in m] == ['user', 'assistant', 'user'], m
assert m[1]['content'][0] == {'type': 'thinking', 'thinking': '', 'signature': 'abc=='}, m[1]
assert m[1]['content'][2]['input'] == {'path': 'made.txt', 'content': 'hi \u0e2a\n"q"\n'}, m[1]
assert m[2]['content'][0]['tool_use_id'] == 'tu_1' and m[2]['content'][0]['content'] == 'wrote made.txt' and 'is_error' not in m[2]['content'][0], m[2]
assert open('made.txt', encoding='utf-8').read() == 'hi \u0e2a\n"q"\n'
PY
# the session: no key yet (it is asked, not shown, saved for the person only), a talk of several turns, commands, an error that leaves no trace
: > req.log
ASCODE_API_URL="http://127.0.0.1:$(cat port)/v1/messages" A="$A" python3 - <<'PY' || { echo "ascode test: the session"; exit 1; }
import os, pty, select, time, json, stat, fcntl, termios, struct
home = os.path.abspath('h2'); os.mkdir(home)
pid, fd = pty.fork()
if pid == 0:
    env = dict(os.environ, HOME=home); env.pop('ANTHROPIC_API_KEY', None)
    os.execve(os.environ['A'], ['ascode'], env)
fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', 30, 40, 0, 0))
out = b''
def want(text, t=10):
    global out
    end = time.time() + t
    while text.encode() not in out:
        r, _, _ = select.select([fd], [], [], max(0, end - time.time()))
        if not r: raise SystemExit('no %r in %r' % (text, out[-600:]))
        out += os.read(fd, 4096)
    seen = out; out = out.split(text.encode(), 1)[1]; return seen
def send(t): time.sleep(0.2); os.write(fd, t.encode() + b'\r')
want('who answers'); want('(Enter: claude): '); send('1')
want('API key'); want('key: ')
send(''); want('nothing came'); want('key: ')                       # an Enter by mistake does not leave
send('\x1b[200~ sk-ant-pasted-777 \x1b[201~')
first = want('> ')
assert b'pasted-777' not in first, 'the key was shown'
assert b'*****' in first, 'nothing shows that the key arrived'
assert b'claude-opus-5-5' in first and b'/help' in first, first
k = home + '/.config/ascode/key'
assert open(k).read() == 'sk-ant-pasted-777\n' and stat.S_IMODE(os.stat(k).st_mode) == 0o600, oct(os.stat(k).st_mode)
send('hello'); want('done: made.txt'); want('> ')
send('boom'); want('529'); want('> ')
send('again'); want('done: made.txt'); want('> ')
send('/help'); h = want('/exit'); want('> ')
assert all(len(l) <= 40 for l in h.decode(errors='replace').split('\r\n')), h
send('/model claude-haiku-5-5'); want('claude-haiku-5-5'); want('> ')
send('small'); want('done: made.txt'); want('> ')
send('/mode read'); want('mode: read'); want('> ')
send('/nothing'); want('/help'); want('> ')
send('/exit')
_, st = os.waitpid(pid, 0)
assert os.waitstatus_to_exitcode(st) == 0
r = [json.loads(l)['body'] for l in open('req.log')]
texts = lambda b: [m['content'] for m in b['messages'] if m['role'] == 'user' and isinstance(m['content'], str)]
assert texts(r[-2]) == ['hello', 'again'], texts(r[-2])
assert texts(r[-1]) == ['small'] and r[-1]['model'] == 'claude-haiku-5-5', r[-1]
PY
# q leaves the question of the key; nothing is saved
HOME="$T/h3" A="$A" python3 - <<'PY' || { echo "ascode test: leaving the question of the key"; exit 1; }
import os, pty, time
pid, fd = pty.fork()
if pid == 0:
    env = dict(os.environ); env.pop('ANTHROPIC_API_KEY', None)
    os.execve(os.environ['A'], ['ascode', 'claude'], env)          # a provider named: straight to its key
out = b''
while b'key: ' not in out: out += os.read(fd, 4096)
time.sleep(0.2); os.write(fd, b'q\r')
while True:
    try: c = os.read(fd, 4096)
    except OSError: break
    if not c: break
    out += c
assert os.waitpid(pid, 0)[1] != 0 and not os.path.exists(os.environ['HOME'] + '/.config/ascode/key'), out
assert all(len(l) <= 40 for l in out.decode().split('\r\n')), out
PY
# a piped talk ends at the end of the input
printf '/exit\n' | HOME="$T/h2" "$A" > out5.txt 2>&1 || { echo "ascode test: piped: $(cat out5.txt)"; exit 1; }
printf '' | HOME="$T/h2" timeout 10 "$A" > out5.txt 2>&1 || { echo "ascode test: the end of the input"; exit 1; }
# another provider (chat completions): chosen in the setup, its models listed, a tool done, the result sent back
: > req.log
OA="http://127.0.0.1:$(cat port)/v1" A="$A" python3 - <<'PY' || { echo "ascode test: another provider"; exit 1; }
import os, pty, select, time, json
home = os.path.abspath('h4'); os.mkdir(home)
pid, fd = pty.fork()
if pid == 0:
    env = dict(os.environ, HOME=home); env.pop('ANTHROPIC_API_KEY', None); env.pop('ASCODE_API_KEY', None)
    os.execve(os.environ['A'], ['ascode', '--mode', 'auto'], env)
out = b''
def want(text, t=10):
    global out
    end = time.time() + t
    while text.encode() not in out:
        r, _, _ = select.select([fd], [], [], max(0, end - time.time()))
        if not r: raise SystemExit('no %r in %r' % (text, out[-700:]))
        try: out += os.read(fd, 4096)
        except OSError: raise SystemExit('ascode ended while waiting for %r: %r' % (text, out[-700:]))
    seen = out.split(text.encode(), 1)[0] + text.encode(); out = out.split(text.encode(), 1)[1]; return seen
def send(t): time.sleep(0.2); os.write(fd, t.encode() + b'\r')
menu = want('(Enter: claude): '); assert b'openrouter' in menu and b'custom' in menu, menu
send('custom'); want('address: '); send(os.environ['OA']); want('key: '); send('oa-secret-5')
listed = want('q leaves): '); assert b'vendor/small-model' in listed and b'oa-secret-5' not in listed, listed
send('vendor'); some = want('q leaves): '); assert b'other/model-z' not in some, some
send('2'); want('> ')
send('write a file'); want('oa done'); want('> ')
send('/config'); c = want('> '); assert b'custom' in c and b'oa-secret-5' not in c and b'key      set' in c, c
send('/models other'); m = want('> '); assert b'other/model-z' in m and b'vendor/big-model' not in m, m
send('/max 900'); want('900'); want('> ')
send('/note always short'); want('> ')
send('again'); want('oa done'); want('> ')
send('/help'); h = want('/exit'); assert all(len(l) <= 40 for l in h.decode(errors='replace').split('\r\n')), h
want('> '); send('/exit')
assert os.waitpid(pid, 0)[1] == 0
r = [json.loads(l) for l in open('req.log')]
gets = [x for x in r if x['path'] == '/v1/models']
assert gets and gets[0]['headers']['authorization'] == 'Bearer oa-secret-5', gets
posts = [x for x in r if x['path'] == '/v1/chat/completions']
first, second = posts[0]['body'], posts[1]['body']
assert posts[0]['headers']['authorization'] == 'Bearer oa-secret-5'
assert first['model'] == 'vendor/small-model' and 'max_tokens' not in first, first['model']
assert [t['type'] for t in first['tools']] == ['function'] * 6 and [t['function']['name'] for t in first['tools']] == ['read', 'list', 'search', 'write', 'edit', 'run'], first['tools']
assert first['tools'][3]['function']['parameters']['required'] == ['path', 'content']
assert [m['role'] for m in first['messages']] == ['system', 'user']
m = second['messages']
assert [x['role'] for x in m] == ['system', 'user', 'assistant', 'tool'], m
assert m[2]['tool_calls'][0]['id'] == 'call_9' and m[3] == {'role': 'tool', 'tool_call_id': 'call_9', 'content': 'wrote oa.txt'}, m
assert open('oa.txt').read() == 'from {"oa"}\n'
last = posts[-1]['body']
assert last['max_tokens'] == 900 and 'always short' in last['messages'][0]['content'], last['messages'][0]
cfg = open(home + '/.config/ascode/config').read()
assert 'provider = custom' in cfg and 'model.custom = vendor/small-model' in cfg and 'oa-secret' not in cfg, cfg
assert open(home + '/.config/ascode/key.custom').read() == 'oa-secret-5\n'
PY
HOME="$T/h4" "$A" --mode auto "one task" > out6.txt 2>&1 </dev/null && grep -q "oa done" out6.txt || { echo "ascode test: one task with the saved provider: $(cat out6.txt)"; exit 1; }
out=$(HOME="$T/h5" ASCODE_API_KEY=zz "$A" --provider custom --url http://example.invalid/v1 --model m "x" 2>&1 </dev/null) && { echo "ascode test: a key over http must be refused"; exit 1; }
echo "$out" | grep -q "only sent over https" || { echo "ascode test: the refusal: $out"; exit 1; }
HOME="$T/h4" "$A" config > out7.txt 2>&1; grep -q "provider custom" out7.txt && ! grep -q "oa-secret" out7.txt || { echo "ascode test: config: $(cat out7.txt)"; exit 1; }
echo "ascode test: ok"
