# the calculator on a screen: driven through a pseudo terminal; the screen is rebuilt from the cursor moves the program writes
import os, pty, select, time, fcntl, termios, struct, re, sys

J = sys.argv[1]

def run(cols, rows):
    pid, fd = pty.fork()
    if pid == 0:
        os.execv(J, ['calc'])
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', rows, cols, 0, 0))
    state = {'screen': {}, 'raw': b''}
    def pump(t=0.5):
        got = b''
        end = time.time() + t
        while time.time() < end:
            r, _, _ = select.select([fd], [], [], max(0, end - time.time()))
            if not r: break
            try: c = os.read(fd, 65536)
            except OSError: break
            if not c: break
            got += c; end = time.time() + 0.15
        state['raw'] += got
        frame = got.decode(errors='replace').split('\x1b[?25l')[-1]
        for m in re.finditer(r'\x1b\[(\d+);1H(.*?)(?=\x1b\[\d+;\d+H|$)', frame, re.S):
            state['screen'][int(m.group(1))] = re.sub(r'\x1b\[[0-9;?]*[A-Za-z]', '', m.group(2)).replace('\r', '').replace('\n', '')
    def key(k): os.write(fd, k); pump()
    def text(): return '\n'.join(state['screen'].get(i, '') for i in range(1, rows + 1))
    def now(): return text().split('> ')[-1]          # the line being typed and its result
    def check(c, what):
        if not c: raise SystemExit('calc screen %dx%d: %s\n%s' % (cols, rows, what, text()))
    def narrow():
        for i, l in state['screen'].items():
            check(len(l) <= cols, 'line %d is %d wide' % (i, len(l)))
            check(i <= rows, 'line %d is below the screen' % i)
    return pid, fd, pump, key, text, now, check, narrow, state

for cols, rows in ((40, 30), (80, 24), (26, 14)):
    pid, fd, pump, key, text, now, check, narrow, st = run(cols, rows)
    pump(2)
    check('DEL' not in text() and ' 7 ' not in text(), 'there are no keys to tap')
    check(b'\x1b[?1000h' not in st['raw'], 'the mouse is not taken (a tap opens the keyboard)')
    key(b'12*(3+4)'); check('= 84' in now(), 'the result while typing'); narrow()
    key(b'\r'); check('12*(3+4)' in text() and '84' in text(), 'history')
    key(b'+1'); check('ans+1' in now() and '= 85' in now(), 'an operator goes on from the answer')
    key(b'\x1b'); key(b'255')
    for w in ('dec 255', 'hex 0xff', 'bin', '1111_1111', 'oct 0o377', 'sci 2.55e+2'): check(w in now(), 'bases: ' + w)
    narrow()
    key(b'\x1b'); key(b'0xffff_ffff_ffff'); narrow(); check('hex 0xffffffffffff' in now(), 'a long number')
    key(b'\x1b'); key(b'1.5e10'); check('sci 1.5e+10' in now() and 'hex' not in now(), 'a number with a point')
    # the cursor: left, right, home, end, delete
    key(b'\x1b'); key(b'12+3'); key(b'\x1b[D\x1b[D'); key(b'0'); check('120+3' in now(), 'Left and type')
    key(b'\x1b[H'); key(b'9'); check('9120+3' in now(), 'Home'); key(b'\x1b[3~'); check('920+3' in now(), 'Delete')
    key(b'\x1b[F'); key(b'\x7f'); check('920+' in now(), 'End and Backspace')
    key(b'\x1b'); key(b'x=5\r'); key(b'x*x\r'); check('25' in text(), 'a variable')
    key(b'5==5\r'); check('5==5' in text(), '== typed')
    key(b'1/0\r'); check('zero' in text(), 'the error is told'); check('1/0' in now(), 'the line stays to be mended')
    key(b'\x7f2\r'); check('0.5' in text(), 'mended')
    key(b'\x1b[A'); check('1/2' in now(), 'Up recalls the last line'); key(b'\x1b')
    key(b'deg\r'); check('deg' in text().split('\n')[0], 'degrees shown'); key(b'sin(90)'); check('= 1' in now(), 'sin in degrees')
    key(b'\x1b'); key(b'rad\r'); check('rad' in text().split('\n')[0], 'radians again')
    key(b'help\r'); h = text(); check('nand' in h or 'sqrt' in h, 'help'); narrow(); key(b'q'); check('> ' in text(), 'back from help')
    key(b'clear\r'); check('12*(3+4)' not in text(), 'clear')
    narrow()
    os.write(fd, b'\x11'); pump(1)
    _, s = os.waitpid(pid, 0)
    check(os.waitstatus_to_exitcode(s) == 0, 'exit code')
    check(b'\x1b[?1049l' in st['raw'], 'the terminal is given back')
pid, fd, pump, key, text, now, check, narrow, st = run(40, 24)
pump(2); os.write(fd, b'quit\r'); pump(1); assert os.waitpid(pid, 0)[1] == 0, 'quit leaves'
print('calc screen: ok')
