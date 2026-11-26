# a small web server for the tests of jget: POST gives back the body, GET /r redirects to /echo, GET /nf is a 404, HEAD answers like GET without the body
import http.server, sys
class H(http.server.BaseHTTPRequestHandler):
    def reply(self, code, body, head_only=False, extra=None):
        self.send_response(code)
        for k, v in (extra or {}).items(): self.send_header(k, v)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        if not head_only: self.wfile.write(body)
    def do_POST(self):
        n = int(self.headers.get('Content-Length', 0)); b = self.rfile.read(n)
        self.reply(200, b'POST:' + b, extra={'X-Got': self.headers.get('X-Test', '-'), 'X-Auth': self.headers.get('Authorization', '-'), 'X-Type': self.headers.get('Content-Type', '-')})
    def do_GET(self, head_only=False):
        if self.path == '/r': self.send_response(302); self.send_header('Location', '/echo'); self.send_header('Content-Length', '0'); self.end_headers(); return
        self.reply(404 if self.path == '/nf' else 200, b'GET ' + self.path.encode(), head_only, {'X-Auth': self.headers.get('Authorization', '-')})
    def do_HEAD(self): self.do_GET(True)
    def log_message(self, *a): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
