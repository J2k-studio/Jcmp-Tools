# less on a pseudo terminal: a long file, a search, the end, leaving
import os, pty, sys, time, select, re
jbox = sys.argv[1]; work = sys.argv[2]
path = work + '/long.txt'
open(path, 'w').write(''.join('line %d %s\n' % (i, 'needle' if i == 150 else 'plain') for i in range(1, 301)))
link = work + '/less'
if not os.path.exists(link): os.symlink(jbox, link)
pid, fd = pty.fork()
if pid == 0:
    os.environ['TERM'] = 'xterm'
    os.execv(link, [link, path])
screen = b''
def pump(t=0.6):
    global screen
    end = time.time() + t
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.1)
        if fd in r:
            try: d = os.read(fd, 65536)
            except OSError: return
            if not d: return
            screen += d
def key(b, t=0.6): os.write(fd, b); pump(t)
def text(): return re.sub(rb'\x1b\[[0-9;?]*[A-Za-z]', b'', screen).decode(errors='replace')
pump(1.0)
assert 'line 1 ' in text() and '%' in text(), 'the first page'
screen = b''
key(b'/'); key(b'needle'); key(b'\r', 0.8)
assert 'line 150 needle' in text(), 'the search shows the line'
assert b'\x1b[7mneedle' in screen, 'the match is marked'
screen = b''
key(b'G', 0.6); assert 'line 300' in text(), 'G goes to the end'
screen = b''
key(b'g', 0.6); assert 'line 1 ' in text(), 'g goes to the top'
key(b'h', 0.6); assert 'jbox pager' in text(), 'h shows the help'
key(b'q', 0.5); key(b'q', 0.8)
time.sleep(0.3)
try:
    p, st = os.waitpid(pid, os.WNOHANG)
    assert p, 'q did not end less'
except ChildProcessError:
    pass
print('pager ok')
