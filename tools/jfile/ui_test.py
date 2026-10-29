# jfile on a pseudo terminal: keys go in, the screen text and the files are checked
import os, pty, sys, time, select, re, shutil
jfile, work = sys.argv[1], sys.argv[2]
os.makedirs(work + '/Download/sub', exist_ok=True)
open(work + '/Download/hello.txt', 'w').write('hello jfile\nline two\n')
open(work + '/Download/zz.bin', 'wb').write(b'\0' * 2048)
pid, fd = pty.fork()
if pid == 0:
    os.environ['TERM'] = 'xterm'
    os.execv(jfile, [jfile, work + '/Download'])
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
def key(b, t=0.5):
    os.write(fd, b); pump(t)
pump(1.0)
txt = re.sub(rb'\x1b\[[0-9;?]*[A-Za-z]', b'', screen).decode(errors='replace')
assert 'jfile' in txt and 'hello.txt' in txt and 'sub/' in txt, 'the list is not on the screen: ' + txt[-300:]
assert '2.0 KB' in txt, 'the size of zz.bin (2.0 KB)'
# n: a new folder
key(b'n'); key(b'made'); key(b'\r')
assert os.path.isdir(work + '/Download/made'), 'n did not make a folder'
# go to hello.txt, mark it, copy, enter the folder "made", paste
screen = b''
pump(0.3)
key(b'j')                        # the cursor stayed on sub/ (the folders come first: made, sub), one down is hello.txt
names = sorted(os.listdir(work + '/Download'))
key(b' ')                        # marks the file under the cursor (hello.txt is the first file)
key(b'c')
key(b'k'); key(b'k'); key(b'k')
key(b'\r', 0.6)                  # into "made"
key(b'v', 0.6)
assert os.path.exists(work + '/Download/made/hello.txt'), 'v did not paste the copy: ' + str(os.listdir(work + '/Download/made'))
assert os.path.exists(work + '/Download/hello.txt'), 'a copy must keep the original'
# t on the text file shows it
key(b't', 0.8)
txt = re.sub(rb'\x1b\[[0-9;?]*[A-Za-z]', b'', screen).decode(errors='replace')
assert 'hello jfile' in txt, 'the text viewer shows the file'
key(b'q', 0.5)
# d with y deletes the file in "made"
key(b'd', 0.4); key(b'y', 0.6)
assert not os.path.exists(work + '/Download/made/hello.txt'), 'd + y did not delete'
key(b'q', 0.5)
pump(0.5)
try:
    p, st = os.waitpid(pid, os.WNOHANG)
    if not p:
        time.sleep(0.5); p, st = os.waitpid(pid, os.WNOHANG)
    assert p, 'q did not end jfile'
except ChildProcessError:
    pass
print('ui ok')

# the places: a new place made with n, kept in ~/.jfile_places, there again in the next start; a missing standard folder is made when asked
import shutil
home2 = work + '/home2'; sd = work + '/sd'
os.makedirs(home2, exist_ok=True); os.makedirs(sd, exist_ok=True)
def start():
    pid, fd = pty.fork()
    if pid == 0:
        os.environ['TERM'] = 'xterm'; os.environ['HOME'] = home2; os.environ['JFILE_STORAGE'] = sd
        os.execv(jfile, [jfile])
    return pid, fd
pid, fd = start(); screen = b''
pump(1.2)
assert 'places' in re.sub(rb'\x1b\[[0-9;?]*[A-Za-z]', b'', screen).decode(errors='replace'), 'the places screen'
key(b'n'); key(b'Projects'); key(b'\r', 0.8)
assert os.path.isdir(sd + '/Projects'), 'n made no folder in the storage'
assert 'Projects' in open(home2 + '/.jfile_places').read(), 'the place is not kept'
key(b'q', 0.5)
pid, fd = start(); screen = b''
pump(1.2)
assert 'Projects' in re.sub(rb'\x1b\[[0-9;?]*[A-Za-z]', b'', screen).decode(errors='replace'), 'the place is there in the next start'
# Documents is not there yet: Enter asks, y makes it
key(b'j'); key(b'j', 0.4)
key(b'\r', 0.6); key(b'y', 0.9)
assert os.path.isdir(sd + '/Documents'), 'a missing standard folder was not made'
key(b'q', 0.4); key(b'q', 0.4)
print('places ok')
