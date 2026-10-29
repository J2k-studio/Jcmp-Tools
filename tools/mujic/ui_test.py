import os,pty,time,select,sys,re,struct,fcntl,termios
os.environ['MUJIC_DIR']=sys.argv[2]; os.environ['JARIC']='1'; os.environ['TERM']='xterm'
pid,fd=pty.fork()
if pid==0:
    fcntl.ioctl(0,termios.TIOCSWINSZ,struct.pack('HHHH',28,70,0,0))
    os.execv(sys.argv[1],['mujic','-t'])
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
# the small terminal: /dir picks a folder and plays a song from it by path, !command shows its output, Tab goes to the output
os.makedirs(sys.argv[2]+'/sub',exist_ok=True); open(sys.argv[2]+'/sub/Deep Song.mp3','w').write('ID3')
send(b'/dir\r',0.8)
check('/dir lists folders', 'sub/' in out.decode('utf8','replace') and 'Song One' in out.decode('utf8','replace'))
send(b'sub',0.4); send(b'\r',0.8)                 # the folder opens, the picker shows its song
check('/dir enters a folder', 'Deep Song' in out.decode('utf8','replace'))
n=out.count(b'7777;audio;play;')
send(b'\r',0.8)
check('/dir plays a song of a folder', out.count(b'7777;audio;play;')>n and b'sub/Deep Song.mp3' in out)
send(b'!echo hello-from-shell\r',1.5)
check('!command shows its output', 'hello-from-shell' in out.decode('utf8','replace'))
send(b'/pwd\r',0.6)
check('/pwd', sys.argv[2].encode() in out)
send(b'\x1b]7777;media;pause\x07',1.0)               # the button of the notification
check('media pause button', out.count(b'audio;pause')+out.count(b'audio;resume')>=2)
# /scan puts the songs it finds into the list at once; /remove takes one out (the file stays)
import struct
sd=sys.argv[2]+'/../scanui'; os.makedirs(sd,exist_ok=True)
data=b'\0'*(16000*80)
open(sd+'/Scanned Tune.wav','wb').write(b'RIFF'+struct.pack('<I',36+len(data))+b'WAVEfmt '+struct.pack('<IHHIIHH',16,1,1,8000,16000,2,16)+b'data'+struct.pack('<I',len(data))+data)
send(('/scan -s 60 '+sd+'\r').encode(),1.5)
txt=out.decode('utf8','replace')
check('/scan puts the song in the list', 'Scanned Tune' in txt and 'new in the list' in txt)
send(b'/remove scanned\r',0.8)
check('/remove takes it out and the file stays', 'removed Scanned Tune from the list' in out.decode('utf8','replace') and os.path.exists(sd+'/Scanned Tune.wav'))
send(b'\x1b',0.8)                                 # Esc on an empty box: leave
check('Esc leaves', b'?1049l' in out)
check('sound stopped', b'audio;stop' in out)
try:
    os.waitpid(pid,0)
except Exception: pass
sys.exit(0 if ok else 1)
