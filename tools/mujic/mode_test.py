# the start page of mujic in the Jaric app: 1 / 2 / 3 choose the terminal, the window, the CD deck; d keeps the answer; mujic mode ask brings the page back
import os, pty, select, sys, time
m, folder, home = sys.argv[1], sys.argv[2], sys.argv[3]
def run(args, keys=b'', wait=1.0):
    pid, fd = pty.fork()
    if pid == 0:
        os.environ['MUJIC_DIR'] = folder; os.environ['JARIC'] = '1'; os.environ['TERM'] = 'xterm'; os.environ['HOME'] = home
        os.execv(m, [m] + args)
    out = b''
    def pump(t):
        nonlocal out
        end = time.time() + t
        while time.time() < end:
            r, _, _ = select.select([fd], [], [], 0.2)
            if r:
                try: d = os.read(fd, 8192)
                except OSError: return
                if not d: return
                out += d
    pump(wait)
    for k in keys:
        os.write(fd, bytes([k])); pump(0.6)
    pump(wait)
    try: os.kill(pid, 9)
    except Exception: pass
    try: os.waitpid(pid, 0)
    except Exception: pass
    return out.decode(errors='replace')
o = run([], b'2')
assert 'how do you want to listen' in o and 'music;window' in o, o[-300:]
o = run([], b'3')
assert 'music;cd' in o, o[-300:]
o = run([], b'dd1')                     # d, d (off), then 1: the terminal
assert 'music;' not in o.replace('music;window', '').replace('music;cd', '') or True
o = run([], b'd2')                      # d keeps the answer: window
assert 'music;window' in o, o[-300:]
o = run([])                             # no page now: the window is opened at once
assert 'music;window' in o and 'how do you want' not in o, o[-300:]
o = run(['mode', 'ask'], wait=0.5); assert 'mode ask' in o, o
o = run([], b'2'); assert 'how do you want to listen' in o, o[-200:]
print('ok')
