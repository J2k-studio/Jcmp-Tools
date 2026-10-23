import os,pty,time,select,fcntl,termios,struct,re,sys
COLS=30; ROWS=12
pid,fd=pty.fork()
if pid==0:
    fcntl.ioctl(0,termios.TIOCSWINSZ,struct.pack('HHHH',ROWS,COLS,0,0))
    os.environ['TERM']='xterm'; os.environ['HOME']=os.environ['TMPDIR']; os.environ['PATH']='/data/data/com.termux/files/usr/bin'
    os.execv(sys.argv[1],['jsh'])
class Scr:
    def __init__(s): s.g=[[' ']*COLS for _ in range(ROWS)]; s.r=0; s.c=0; s.pend=False
    def put(s,ch):
        if s.pend: s.c=0; s.nl(); s.pend=False
        s.g[s.r][s.c]=ch
        if s.c==COLS-1: s.pend=True
        else: s.c+=1
    def nl(s):
        if s.r==ROWS-1: s.g.pop(0); s.g.append([' ']*COLS)
        else: s.r+=1
    carry=b''
    def feed(s,data):
        data=s.carry+data; s.carry=b''
        k=data.rfind(b'\x1b')
        if k>=0 and not re.match(rb'\x1b(\[[0-9;?]*[A-Za-z]|\][^\x07]*\x07)',data[k:]): s.carry=data[k:]; data=data[:k]
        t=data.decode('utf8','replace'); i=0
        while i<len(t):
            ch=t[i]
            if ch=='\x1b':
                if t[i+1:i+2]=='[':
                    m=re.match(r'\x1b\[([0-9;?]*)([A-Za-z])',t[i:])
                    if m:
                        n=int(m.group(1) or 1) if m.group(1).isdigit() or m.group(1)=='' else 1; f=m.group(2)
                        if f=='A': s.r=max(0,s.r-n); s.pend=False
                        elif f=='B': s.r=min(ROWS-1,s.r+n); s.pend=False
                        elif f=='C': s.c=min(COLS-1,s.c+n); s.pend=False
                        elif f=='D': s.c=max(0,s.c-n); s.pend=False
                        elif f=='J':
                            for k in range(s.c,COLS): s.g[s.r][k]=' '
                            for rr in range(s.r+1,ROWS): s.g[rr]=[' ']*COLS
                        elif f=='K':
                            for k in range(s.c,COLS): s.g[s.r][k]=' '
                        i+=len(m.group(0)); continue
                if t[i+1:i+2]==']':
                    j=t.find('\x07',i); i=j+1 if j>0 else len(t); continue
                i+=2; continue
            if ch=='\r': s.c=0; s.pend=False
            elif ch=='\n': s.nl(); s.pend=False
            elif ch=='\x08': s.c=max(0,s.c-1)
            elif ch>=' ': s.put(ch)
            i+=1
scr=Scr()
def rd(x):
    end=time.time()+x
    while time.time()<end:
        r,_,_=select.select([fd],[],[],0.05)
        if r:
            try: d=os.read(fd,65536)
            except OSError: return
            scr.feed(d)
rd(1)
for ch in b'echo aaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeee':
    os.write(fd,bytes([ch])); rd(0.02)
for _ in range(14):
    os.write(fd,b'\x1b[D'); rd(0.05)
for _ in range(5):
    os.write(fd,b'\x1b[C'); rd(0.05)
rd(0.3)
rows=[''.join(r).rstrip() for r in scr.g]
pr = [k for k, r in enumerate(rows) if r.startswith('jc :')]
ok = len(pr) == 1
if ok:
    pw = rows[pr[0]].index('echo')
    total = pw + 46                       # the text cursor: 55 letters, 14 times left, 5 times right
    ok = scr.r == pr[0] + total // COLS and scr.c == total % COLS and rows[pr[0] + 1].startswith('b') or rows[pr[0] + 1].startswith('a') or rows[pr[0] + 1].startswith('c')
os.write(fd,b'exit\r')
sys.exit(0 if ok else 1)
