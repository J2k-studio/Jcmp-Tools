# a pretend Jaric app for the tests of cam: runs `cam ARGS` on a pseudo terminal, answers ESC ] 7777 ; camera ; ... BEL like the app does
import os, pty, sys, time, select, re
mode = sys.argv[1]          # scan | scan-none | photo | photo-auto | photo-quit | no-answer
cam = sys.argv[2]
work = sys.argv[3]
args = sys.argv[4:]
jpeg = os.path.join(work, 'qr_frame.jpg')       # what the "camera" sees
pid, fd = pty.fork()
if pid == 0:
    os.environ['TMPDIR'] = work
    os.environ['PATH'] = work + '/bin:' + os.environ.get('PATH', '')
    os.environ['CAM_DIR'] = work + '/dcim/'
    os.execv(cam, [cam] + args)
buf = b''
out = b''
t0 = time.time()
shots = 0
def say(msg): os.write(fd, b'\x1b]7777;' + msg.encode() + b'\x07')
done = False
while time.time() - t0 < 30 and not done:
    r, _, _ = select.select([fd], [], [], 0.2)
    if fd in r:
        try: d = os.read(fd, 4096)
        except OSError: d = b''
        buf += d
        while True:
            m = re.search(rb'\x1b\]7777;camera;([^\x07]*)\x07', buf)
            if not m: break
            cmd = m.group(1).decode(); buf = buf[:m.start()] + buf[m.end():]
            if cmd.startswith('open'):
                if mode == 'no-answer': continue
                say('camera-ready;back;1920;1080')
                if mode == 'photo':
                    # the owner touches the round button after a moment
                    path = cmd.split(';')[2]
                    time.sleep(0.5)
                    open(path, 'wb').write(open(jpeg, 'rb').read()); say('camera-shot;%s;1234' % path)
                if mode == 'photo-quit':
                    time.sleep(0.5); os.write(fd, b'\x1b')
            elif cmd.startswith('shot;'):
                path = cmd[5:]
                shots += 1
                src = jpeg if (mode in ('scan', 'ui-use', 'ui-add') and shots >= 3) or mode == 'photo-auto' else os.path.join(work, 'blank.jpg')
                open(path, 'wb').write(open(src, 'rb').read()); say('camera-shot;%s;1234' % path)
            elif cmd.startswith('result;'):
                b64 = cmd[7:]
                if mode == 'ui-use': say('camera-action;use;' + b64)
                if mode == 'ui-add': say('camera-action;add;' + b64)
            elif cmd == 'close':
                pass
        out += buf if False else b''
    # the program ended?
    p, status = os.waitpid(pid, os.WNOHANG)
    if p:
        done = True
        # drain
        try:
            while True:
                r, _, _ = select.select([fd], [], [], 0.2)
                if not r: break
                d = os.read(fd, 4096)
                if not d: break
                buf += d
        except OSError: pass
        sys.stdout.write(re.sub(rb'\x1b\][^\x07]*\x07', b'', buf).decode(errors='replace').replace('\r', ''))
        sys.exit(os.waitstatus_to_exitcode(status))
try: os.kill(pid, 9)
except Exception: pass
print('TIMEOUT'); sys.exit(99)
