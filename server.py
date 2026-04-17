import http.server
import os
import socketserver

PORT = int(os.environ.get("PORT", 8080))

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Redirect root to starvolt.html
        if self.path == "/":
            self.path = "/starvolt.html"
        return super().do_GET()

    def log_message(self, format, *args):
        pass  # silence logs

os.chdir(os.path.dirname(os.path.abspath(__file__)))

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving on port {PORT}", flush=True)
    httpd.serve_forever()
