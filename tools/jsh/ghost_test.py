# the grey text comes from the tree of the history: the newest line that continues the typed letters
import os,pty,time,select,sys,fcntl,termios,struct
pid,fd=pty.fork()
if pid==0:
    fcntl.ioctl(0,termios.TIOCSWINSZ,struct.pack('HHHH',12,80,0,0))
    os.environ['TERM']='xterm'; os.environ['HOME']=os.environ['TMPDIR']; os.environ['PATH']='/data/data/com.termux/files/usr/bin'
    os.execv(sys.argv[1],['jsh'])
def rd(t=0.6):
    out=b''; end=time.time()+t
    while time.time()<end:
        if select.select([fd],[],[],0.1)[0]:
            try: out+=os.read(fd,4096)
            except OSError: break
    return out
rd(1.5)
for l in (b'echo hello one\r', b'echo help two\r', b'echo hello three\r'): os.write(fd,l); rd()
os.write(fd,b'echo hel'); o=rd()
GREY=b'\x1b[38;2;110;110;110m'
ok = GREY+b'lo three' in o                      # newest of the lines that start with  echo hel
os.write(fd,b'\x15echo help'); o=rd()
ok = ok and GREY+b' two' in o                   # only one line continues  echo help
os.write(fd,b'\x15'); os.write(fd,b'\x15'+b'echo '+b'x'*150+b'\r'); rd()   # a long line, then its first letters: the guess must not wrap
os.write(fd,b'echo xx'); o=rd()
g=o.rfind(GREY); ok = ok and g>=0 and o[g:].count(b'x')<80      # the grey run is shorter than a row
os.write(fd,b'\x15exit\r')
sys.exit(0 if ok else 1)
