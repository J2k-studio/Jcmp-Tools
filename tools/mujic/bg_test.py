# mujic play FILE -b in the background: the (pretend) app gets  audio;play;REALPATH, the prompt is free (the program ends at once);
# mujic pause / resume / stop send their messages; a missing file is an error
import os, pty, select, sys, time
m, folder = sys.argv[1], sys.argv[2]
def run(args, cwd=None):
    pid, fd = pty.fork()
    if pid == 0:
        os.environ['MUJIC_DIR'] = folder; os.environ['JARIC'] = '1'; os.environ['TERM'] = 'xterm'
        if cwd: os.chdir(cwd)
        os.execv(m, [m] + args)
    out = b''; end = time.time() + 8
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.3)
        if r:
            try: d = os.read(fd, 4096)
            except OSError: break
            if not d: break
            out += d
        else:
            try:
                p, st = os.waitpid(pid, os.WNOHANG)
                if p: return os.waitstatus_to_exitcode(st), out.decode(errors='replace')
            except ChildProcessError: break
    try: _, st = os.waitpid(pid, 0)
    except ChildProcessError: st = 0
    return os.waitstatus_to_exitcode(st), out.decode(errors='replace')
d = os.path.join(folder, '..', 'elsewhere'); os.makedirs(d, exist_ok=True)
open(os.path.join(d, 'Blonde.mp3'), 'wb').write(b'ID3')
rc, out = run(['play', 'Blonde.mp3', '-b'], cwd=d)
assert rc == 0, ('rc', rc, out)
assert '\x1b]7777;audio;play;' in out and 'Blonde.mp3' in out, out
assert 'in the background' in out, out
rc, out = run(['pause']); assert rc == 0 and 'audio;pause' in out, out
rc, out = run(['resume']); assert rc == 0 and 'audio;resume' in out, out
rc, out = run(['stop']); assert rc == 0 and 'audio;stop' in out, out
rc, out = run(['play', 'NoSuchSong.mp3', '-b'], cwd=d); assert rc != 0, (rc, out)
print('ok')
