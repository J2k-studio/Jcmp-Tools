# a small web server for the test of curl: /hello, /file.bin, /echo (method, body and the header X-Test), /redir -> /hello
import http.server, sys
class H(http.server.BaseHTTPRequestHandler):
    def reply(self, code, body, ctype='text/plain', extra=None):
        self.send_response(code); self.send_header('Content-Type', ctype); self.send_header('Content-Length', str(len(body)))
        for k, v in (extra or {}).items(): self.send_header(k, v)
        self.end_headers(); self.wfile.write(body)
    def do_GET(self):
        if self.path == '/hello': self.reply(200, b'hello world\n')
        elif self.path == '/file.bin': self.reply(200, bytes(range(256)) * 20, 'application/octet-stream')
        elif self.path == '/redir': self.reply(302, b'', extra={'Location': '/hello'})
        elif self.path.startswith('/echo'): self.reply(200, ('GET %s %s\n' % (self.path, self.headers.get('X-Test', ''))).encode())
        else: self.reply(404, b'no\n')
    def do_POST(self):
        n = int(self.headers.get('Content-Length') or 0)
        body = self.rfile.read(n).decode()
        self.reply(200, ('POST %s %s %s\n' % (body, self.headers.get('X-Test', ''), self.headers.get('Content-Type', ''))).encode())
    def log_message(self, *a): pass
s = http.server.ThreadingHTTPServer(('127.0.0.1', 0), H)
open(sys.argv[1], 'w').write(str(s.server_address[1]))
s.serve_forever()
