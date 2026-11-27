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
        for m in re.finditer(r'\x1b\[(\d+);1H(.*?)(?=\x1b\[\d+;1H|\x1b\[\?25|$)', got.decode(errors='replace'), re.S):
            text = re.sub(r'\x1b\[[0-9;?]*[A-Za-z]', '', m.group(2))
            state['screen'][int(m.group(1))] = text.replace('\r', '').replace('\n', '')
    def key(k): os.write(fd, k); pump()
    def text(): return '\n'.join(state['screen'].get(i, '') for i in range(1, rows + 1))
    def tap(label):
        for row in sorted(state['screen'], reverse=True):
            m = re.search(r'(?<!\S)' + re.escape(label) + r'(?!\S)', state['screen'][row])
            if m: key(b'\x1b[<0;%d;%dM\x1b[<0;%d;%dm' % (m.start() + 1, row, m.start() + 1, row)); return
        raise SystemExit('no button ' + label + '\n' + text())
    def check(c, what):
        if not c: raise SystemExit('calc screen %dx%d: %s\n%s' % (cols, rows, what, text()))
    def narrow():
        for i, l in state['screen'].items():
            check(len(l) <= cols, 'line %d is %d wide' % (i, len(l)))
            check(i <= rows, 'line %d is below the screen' % i)
    return pid, fd, pump, key, text, tap, check, narrow, state

for cols, rows in ((40, 30), (80, 24), (26, 16)):
    pid, fd, pump, key, text, tap, check, narrow, st = run(cols, rows)
    pump(2)
    for b in ('7', '8', '9', '0', '+', '-', '*', '/', '(', ')', '=', 'C', 'DEL'):
        check(b in text(), 'no button ' + b)
    key(b'12*(3+4)'); check('= 84' in text(), 'no result while typing'); narrow()
    key(b'\r'); check('12*(3+4)' in text() and '84' in text(), 'history')
    key(b'+1'); check('ans+1' in text() and '= 85' in text(), 'an operator continues from the answer')
    key(b'\r')
    for b in ('7', '*', '6'): tap(b)
    check('= 42' in text(), 'tapped keys'); tap('DEL'); tap('5'); check('= 35' in text(), 'DEL and 5')
    tap('='); check('35' in text(), 'tapped =')
    key(b'x=5\r'); key(b'x*x\r'); check('25' in text(), 'a variable')
    key(b'1/0\r'); check('zero' in text(), 'the error is told'); check('1/0' in text(), 'the line stays to be mended')
    key(b'\x7f2'); check('= 0.5' in text(), 'mended'); tap('C'); check('= 0.5' not in text().split('> ')[-1], 'cleared')
    key(b'\x1b[A'); check('x*x' in text().split('> ')[-1], 'Up recalls the last line')
    key(b'\x1b'); key(b'255'); check('0xff' in text(), 'hex of a whole number')
    narrow()
    key(b'\x1b'); key(b'5==5\r'); check('= 1' in text(), '== typed'); check('5==5' in text(), '== kept in the history')
    key(b'7<=3\r'); check('7<=3' in text() and '= 0' in text(), '<= typed')
    os.write(fd, b'\x11'); pump(1)
    _, s = os.waitpid(pid, 0)
    check(os.waitstatus_to_exitcode(s) == 0, 'exit code')
    check(b'\x1b[?1049l' in st['raw'] and b'\x1b[?1000l' in st['raw'], 'the terminal is given back')
print('calc screen: ok')
