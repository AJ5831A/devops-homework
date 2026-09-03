from http.server import BaseHTTPRequestHandler, HTTPServer


class HelloHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b'<h1>Hello World from Python</h1>')


if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 5000), HelloHandler)
    print('Python app listening on port 5000')
    server.serve_forever()
