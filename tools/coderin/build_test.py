# the menu bar (F10) and the keys F9 / F11 of coderin with the scheme devcpp: compile, compile and run, the log of errors, the examples
import os, pty, select, sys, time
ed, work = sys.argv[1], sys.argv[2]
def session(fname, keys, wait=2.5):
    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(work)
        os.environ['HOME'] = work; os.environ['TERM'] = 'xterm'
        os.execv(ed, ['coderin', fname])
    import fcntl, termios, struct
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', 30, 90, 0, 0))
    out = b''
    def pump(t):
        nonlocal out
        end = time.time() + t
        while time.time() < end:
            r, _, _ = select.select([fd], [], [], 0.2)
            if r:
                try: d = os.read(fd, 65536)
                except OSError: return
                if not d: return
                out += d
    pump(0.8)
    for k, w in keys:
        os.write(fd, k); pump(w)
    try: os.kill(pid, 9)
    except Exception: pass
    try: os.waitpid(pid, 0)
    except Exception: pass
    return out.decode(errors='replace')
os.makedirs(work + '/.config/coderin', exist_ok=True)
open(work + '/.config/coderin/settings', 'w').write('colorscheme = devcpp\n')
open(work + '/good.jk', 'w').write('#import <stdlib>\n\nvoid main() {\n    cout << "hi5 from the log\\n";\n}\n')
open(work + '/bad.jk', 'w').write('#import <stdlib>\n\nvoid main() {\n    cout << ;\n}\n')
F11 = b'\x1b[23~'; F9 = b'\x1b[20~'; F10 = b'\x1b[21~'
o = session('good.jk', [(F11, 5.0)])
assert 'Output of' in o and 'hi5 from the log' in o and '[exit 0]' in o, o[-600:]
o = session('bad.jk', [(F9, 4.0)])
assert 'Compile Log' in o and 'error' in o, o[-600:]
o = session('good.jk', [(F10, 0.6)])
assert 'Examples' in o and 'Quit' in o and ' File ' in o, o[-500:]
# the menu with a key: Down to Examples, Enter: the prompt of the example appears
o = session('good.jk', [(F10, 0.4), (b'\x1b[B', 0.3), (b'\r', 0.6)])
assert 'example:' in o, o[-500:]
# no setting at all: in the Jaric app (JARIC set) the look is Dev-C++; jaric settings (coderin = dark) changes it; the settings of coderin come first
os.remove(work + '/.config/coderin/settings')
def with_env(extra, fname='good.jk'):
    os.environ.update(extra)
    try: return session(fname, [(b'', 0.5)])
    finally:
        for k in extra: os.environ.pop(k, None)
o = with_env({'JARIC': '1'})
assert ' File ' in o and 'Search' in o, o[-300:]
os.makedirs(work + '/.config/jaric', exist_ok=True)
open(work + '/.config/jaric/settings', 'w').write('coderin = dark\n')
o = with_env({'JARIC': '1'})
assert ' File ' not in o, o[-300:]
open(work + '/.config/coderin/settings', 'w').write('colorscheme = devcpp\n')
o = with_env({'JARIC': '1'})
assert ' File ' in o, o[-300:]
print('ok')
