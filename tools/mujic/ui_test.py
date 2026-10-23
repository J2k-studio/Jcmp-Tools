import os,pty,time,select,sys,re,struct,fcntl,termios
os.environ['MUJIC_DIR']=sys.argv[2]; os.environ['JARIC']='1'; os.environ['TERM']='xterm'
pid,fd=pty.fork()
if pid==0:
    fcntl.ioctl(0,termios.TIOCSWINSZ,struct.pack('HHHH',28,70,0,0))
    os.execv(sys.argv[1],['mujic'])
out=b''
def rd(t=0.5):
    global out
    end=time.time()+t
    while time.time()<end:
        r,_,_=select.select([fd],[],[],0.05)
        if r:
            try: d=os.read(fd,65536)
            except OSError: return
            out+=d
def send(b,t=0.5): os.write(fd,b); rd(t)
ok=True
def check(name,cond):
    global ok
    if not cond: print('FAIL:',name); ok=False
rd(1)
check('screen drawn', b'mujic 0.3' in out and '╭'.encode() in out)
send(b'\r',0.8)                                   # Enter on an empty box: play the song under the cursor
check('Enter plays', b'7777;audio;play;' in out and b'Song One' in out)
send(b'/',0.5)
check('slash menu', b'/play' in out and b'/pause' in out)
send(b'pa',0.4); send(b'\r',0.6)                  # /pa -> the first match, /pause
check('/pause runs', b'audio;pause' in out)
send(b'two\r',0.9)                                # plain words: one song matches, it plays
check('words play a song', out.count(b'7777;audio;play;')>=2 and b'Song Two' in out)
send(b'\x1b]7777;pos;21000;1;200000\x07',0.6)
send(b'\t',0.6)                                   # Tab: the lyrics
txt=out.decode('utf8','replace')
check('lyrics shown', 'strangers' in txt)
send(b'/volume 50\r',0.6)
check('/volume', b'audio;volume;50' in out)
send(b'/play\r',0.7)                              # the picker
check('picker opens', 'Choose a song' in out.decode('utf8','replace'))
send(b'one',0.5)
send(b'\r',0.8)
check('picker plays', out.rindex(b'Song One')>out.rindex(b'Song Two') if b'Song One' in out else False)
send(b'\x1b',0.8)                                 # Esc on an empty box: leave
check('Esc leaves', b'?1049l' in out)
check('sound stopped', b'audio;stop' in out)
try:
    os.waitpid(pid,0)
except Exception: pass
sys.exit(0 if ok else 1)
