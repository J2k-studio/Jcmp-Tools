import sys
import os,time,pty,select
t=os.environ.get('TMPDIR','/tmp')+'/pf'; os.makedirs(t+'/etc',exist_ok=True); h=os.environ.get('TMPDIR','/tmp')+'/hm'; os.makedirs(h,exist_ok=True)
for f in (t+'/etc/config.local',t+'/etc/theme.toml',h+'/.jshrc'):
    if os.path.exists(f): os.remove(f)
pid,fd=pty.fork()
if pid==0:
    os.environ['PREFIX']=t; os.environ['HOME']=h; os.environ['TERM']='xterm'
    os.execv(sys.argv[1],['jsh'])
out=b''
def rd(x=0.4):
    global out
    end=time.time()+x
    while time.time()<end:
        r,_,_=select.select([fd],[],[],0.1)
        if r:
            try: out+=os.read(fd,65536)
            except OSError: return
rd(1)
os.write(fd,b'jaric setting\r'); rd(0.8)
os.write(fd,b'\x1b[C'); rd(0.3)            # theme -> soft
os.write(fd,b'\x1b[B\x1b[C'); rd(0.3)      # font 12
os.write(fd,b'\x1b[B\x1b[C'); rd(0.3)      # background white (first name)
os.write(fd,b'\x1b[B\x1b[B\x1b[B\x1b[C'); rd(0.3)   # topbar shown (sel 5)
os.write(fd,b'\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[C'); rd(0.4) # prompt sel 10 mark white->grey ? (sel 10)
os.write(fd,b'q'); rd(0.8)
ok=b'7777;reload' in out
c=open(t+'/etc/config.local').read(); th=open(t+'/etc/theme.toml').read(); rc=open(h+'/.jshrc').read()
ok=ok and 'theme = soft' in c and 'font = 12' in c and 'topbar = shown' in c and 'background = "#ffffff"' in th and 'export JSH_COLOR_MARK=white' in rc
import sys
os.write(fd,b'exit\r')
sys.exit(0 if ok else 1)
