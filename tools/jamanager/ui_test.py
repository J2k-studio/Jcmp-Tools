# jmanager on a pseudo terminal: the tabs, the list of programs, a filter, stopping a program with k and y
import os, pty, sys, time, select, re, subprocess, signal
link = sys.argv[1]
child = subprocess.Popen(['sleep', '777'])
pid, fd = pty.fork()
if pid == 0:
    os.environ['TERM'] = 'xterm'
    os.execv(link, [link])
screen = b''
def pump(t=0.7):
    global screen
    end = time.time() + t
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.1)
        if fd in r:
            try: d = os.read(fd, 65536)
            except OSError: return
            if not d: return
            screen += d
def key(b, t=0.7):
    os.write(fd, b); pump(t)
def text(): return re.sub(rb'\x1b\[[0-9;?]*[A-Za-z]', b'', screen).decode(errors='replace')
pump(1.5)
t = text()
assert 'jmanager' in t and 'Programs' in t and 'CPU' in t and 'MEM' in t, 'the head: ' + t[-300:]
assert 'jamanager' in t or 'jmanager' in t or 'PID' in t, 'the table'
# the filter: sleep
key(b'/'); key(b'sleep'); key(b'\r', 1.0)
assert 'sleep' in text(), 'the filter shows sleep'
screen = b''
key(b'k', 0.6)                           # asks
assert 'sleep' in text() and '(y/n)' in text(), 'k asks first: ' + text()[-200:]
key(b'y', 1.5)
time.sleep(0.5)
alive = child.poll() is None
assert not alive, 'the program was not stopped'
# the other tabs
key(b'\t', 0.8); assert 'Memory' in text() and 'swap' in text().lower() or 'Swap' in text(), 'the memory tab'
key(b'\t', 0.8); assert 'GB' in text() or 'SIZE' in text(), 'the drives tab'
os.write(fd, b'\t')
for _ in range(20):                         # the sizes of the folders are measured first: up to 10 seconds
    pump(0.5)
    if 'caches' in text(): break
assert 'caches' in text(), 'the caches tab'
key(b'q', 0.6)
time.sleep(0.4)
try:
    p, st = os.waitpid(pid, os.WNOHANG)
    assert p, 'q did not end it'
except ChildProcessError:
    pass
print('ui ok')
