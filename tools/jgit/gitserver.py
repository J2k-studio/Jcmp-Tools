# a git server for the tests: the smart http protocol through `git http-backend` (a CGI program); receive-pack wants the password "tok"
import http.server, subprocess, sys, os
root, portfile = sys.argv[1], sys.argv[2]
class H(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.0'
    def do(self):
        path, _, query = self.path.partition('?')
        n = int(self.headers.get('Content-Length') or 0)
        body = self.rfile.read(n) if n else b''
        if 'git-receive-pack' in (path + query):
            import base64
            want = 'Basic ' + base64.b64encode(b'jgit:tok').decode()
            if self.headers.get('Authorization') != want:
                self.send_response(401); self.send_header('WWW-Authenticate', 'Basic realm="git"'); self.send_header('Content-Length', '0'); self.end_headers(); return
        env = dict(os.environ, GIT_PROJECT_ROOT=root, GIT_HTTP_EXPORT_ALL='1', REQUEST_METHOD=self.command, PATH_INFO=path, QUERY_STRING=query,
                   CONTENT_TYPE=self.headers.get('Content-Type', ''), CONTENT_LENGTH=str(len(body)), REMOTE_USER='tester', REMOTE_ADDR='127.0.0.1')
        p = subprocess.run(['git', 'http-backend'], input=body, env=env, capture_output=True)
        out = p.stdout
        head, _, rest = out.partition(b'\r\n\r\n')
        if not _: head, _, rest = out.partition(b'\n\n')
        status = 200
        hdrs = []
        for l in head.replace(b'\r\n', b'\n').split(b'\n'):
            if l.lower().startswith(b'status:'): status = int(l.split()[1])
            elif l: hdrs.append(l.decode().split(': ', 1))
        self.send_response(status)
        for k, v in hdrs: self.send_header(k, v)
        self.send_header('Content-Length', str(len(rest)))
        self.end_headers()
        self.wfile.write(rest)
    do_GET = do
    do_POST = do
    def log_message(self, *a): pass
s = http.server.ThreadingHTTPServer(('127.0.0.1', 0), H)
open(portfile, 'w').write(str(s.server_address[1]))
s.serve_forever()
