# the grey text follows the history of the sessions before (~/.jsh_history), the same folder, the words after the words, $NAME
import os, pty, time, select, sys, fcntl, termios, struct, tempfile, shutil
jsh = sys.argv[1]
home = tempfile.mkdtemp()
os.makedirs(home + '/A'); os.makedirs(home + '/B')
GREY = b'\x1b[38;2;110;110;110m'
def session(script, tail=None):
    pid, fd = pty.fork()
    if pid == 0:
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', 12, 100, 0, 0))
        os.environ['TERM'] = 'xterm'; os.environ['HOME'] = home; os.environ['PATH'] = '/data/data/com.termux/files/usr/bin'
        os.execv(jsh, ['jsh'])
    def rd(t=0.5):
        out = b''; end = time.time() + t
        while time.time() < end:
            if select.select([fd], [], [], 0.1)[0]:
                try: out += os.read(fd, 8192)
                except OSError: break
        return out
    rd(1.5)
    seen = []
    for step in script:
        os.write(fd, step); o = rd()
        seen.append(o)
    os.write(fd, b'\x15exit\r'); rd(0.4)
    try: os.waitpid(pid, 0)
    except ChildProcessError: pass
    return seen
def grey(o):
    g = o.rfind(GREY)
    if g < 0: return b''
    end = o.find(b'\x1b[0m', g)
    return o[g + len(GREY):end]
ok = True
def check(name, cond):
    global ok
    if not cond: print('FAIL', name); ok = False
# session 1: the lines that make the history (A and B are folders)
session([b'cd ' + (home + '/A').encode() + b'\r', b'echo alpha-here\r', b'cd ' + (home + '/B').encode() + b'\r', b'echo beta-here\r',
         b'echo beta-here\r', b'git status\r', b'git status\r', b'git commit -m fix\r', b'true && git push origin main\r', b'export MYVAR_LONGNAME=1\r'])
check('the file of the history', os.path.exists(home + '/.jsh_history'))
# session 2: a new shell reads the history of the first one
s = session([b'git s', b'\x15git ', b'\x15x && git pu', b'\x15echo $HO', b'\x15cd ' + (home + '/A').encode() + b'\r', b'echo ', b'\x15echo beta-', b'\x15echo '])
check('a line of the history after a new start (git s -> tatus)', grey(s[0]) == b'tatus')
check('the word that usually follows (git + space -> status)', grey(s[1]) == b'status')
check('a new command after && (git pu -> sh)', grey(s[2]) == b'sh')
check('the name of a variable ($HO -> ME)', grey(s[3]) == b'ME')
check('the same folder first (echo + space in A -> alpha-here)', grey(s[5]).startswith(b'alpha-here'))
check('another folder: the newest line (echo beta- -> here)', grey(s[6]) == b'here')
shutil.rmtree(home, ignore_errors=True)
print('ghost2 ok' if ok else 'ghost2 FAILED')
sys.exit(0 if ok else 1)
