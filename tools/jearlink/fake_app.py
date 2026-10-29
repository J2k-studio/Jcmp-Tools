# a pretend app on a pseudo terminal: answers ESC ] 7777 ; intent ; ... BEL like the Jaric app; prints what it got
import os, pty, sys, base64, select, time
prog, mode = sys.argv[1], sys.argv[2]
args = sys.argv[3:]
pid, fd = pty.fork()
if pid == 0:
    os.execv(prog, [prog] + args)
buf = b""
log = b""
end = time.time() + 15
while time.time() < end:
    r, _, _ = select.select([fd], [], [], 0.3)
    if r:
        try: d = os.read(fd, 4096)
        except OSError: break
        if not d: break
        buf += d; log += d
        while b"\x07" in buf:
            msg, buf = buf.split(b"\x07", 1)
            msg = msg.split(b"\x1b]7777;")[-1].decode()
            if msg.startswith("intent;apps"):
                lines = "Camera\tcom.cam\nJaric\tcom.jaric.app\n"
                os.write(fd, b"\x1b]7777;intent-apps;" + base64.b64encode(lines.encode()) + b"\x07")
            elif msg.startswith("intent;"):
                if mode == "error": os.write(fd, b"\x1b]7777;intent-error;no such app\x07")
                else: os.write(fd, b"\x1b]7777;intent-ok\x07")
            os.write(1, ("GOT " + msg + "\n").encode())
    else:
        try:
            p, st = os.waitpid(pid, os.WNOHANG)
            if p: break
        except ChildProcessError: break
try: _, st = os.waitpid(pid, 0)
except ChildProcessError: st = 0
sys.stdout.write(log.decode(errors="replace").replace("\x1b", "<ESC>").replace("\x07", "<BEL>").replace("\r", ""))
sys.exit(os.waitstatus_to_exitcode(st))
