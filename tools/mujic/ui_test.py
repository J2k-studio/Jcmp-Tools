import os,pty,time,select,sys,re,struct,fcntl,termios
os.environ['MUJIC_DIR']=sys.argv[2]; os.environ['JARIC']='1'; os.environ['TERM']='xterm'
pid,fd=pty.fork()
if pid==0:
    fcntl.ioctl(0,termios.TIOCSWINSZ,struct.pack('HHHH',24,60,0,0))
    os.execv(sys.argv[1],['mujic'])
fcntl.ioctl(fd,termios.TIOCSWINSZ,struct.pack('HHHH',24,60,0,0))
out=b''
def rd(t=0.6):
    global out
    end=time.time()+t
    while time.time()<end:
        r,_,_=select.select([fd],[],[],0.1)
        if r:
            try: d=os.read(fd,65536)
            except OSError: return
            out+=d
rd(1)
os.write(fd,b'\x1b[B'); rd(0.4)       # down
os.write(fd,b'\r'); rd(0.8)           # enter -> play
ok=b'7777;audio;play;' in out
os.write(fd,b'\x1b]7777;pos;21000;1;200000\x07'); rd(0.8)
txt=out.decode('utf8','replace')
ok=ok and 'strangers' in txt and '00:2' in txt and '03:20' in txt
os.write(fd,b' '); rd(0.4); ok=ok and b'audio;pause' in out
os.write(fd,b'\x1b[C'); rd(0.4); ok=ok and b'audio;seek;' in out
os.write(fd,b'q'); rd(0.8)
ok=ok and b'audio;stop' in out and b'?1049l' in out
os.waitpid(pid,0)
sys.exit(0 if ok else 1)
