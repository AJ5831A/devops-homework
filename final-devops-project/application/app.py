"""Small stateless HTTP service for the final DevOps lab (Python standard library)."""
import hashlib
import hmac
import json
import os
import resource
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

START = time.monotonic()
LOCK = threading.Lock()
REQUESTS = 0


def response(path, headers=None):
    """Return status, content type and body; kept separate for deterministic tests."""
    global REQUESTS
    headers = headers or {}
    with LOCK:
        REQUESTS += 1
        count = REQUESTS
    try:
        url = urlsplit(path)
    except ValueError:
        return 400, 'application/json', json.dumps({'error': 'invalid request path'})
    if url.path == '/healthz':
        return 200, 'application/json', json.dumps({'status': 'ok'})
    if url.path == '/readyz':
        ready = bool(os.getenv('API_TOKEN'))
        return (200 if ready else 503), 'application/json', json.dumps({'ready': ready})
    if url.path == '/metrics':
        usage = resource.getrusage(resource.RUSAGE_SELF)
        # Linux reports KiB; macOS reports bytes. Containers run on Linux.
        import sys
        rss = usage.ru_maxrss * (1 if sys.platform == 'darwin' else 1024)
        return 200, 'text/plain; version=0.0.4', (
            '# HELP demo_requests_total HTTP requests including probes and scrapes.\n'
            '# TYPE demo_requests_total counter\n'
            f'demo_requests_total {count}\n'
            '# TYPE process_cpu_seconds_total counter\n'
            f'process_cpu_seconds_total {usage.ru_utime + usage.ru_stime}\n'
            '# HELP demo_peak_resident_memory_bytes Peak resident memory, not current RSS.\n'
            '# TYPE demo_peak_resident_memory_bytes gauge\n'
            f'demo_peak_resident_memory_bytes {rss}\n'
            '# TYPE demo_uptime_seconds gauge\n'
            f'demo_uptime_seconds {time.monotonic() - START}\n')
    if url.path == '/api/info':
        token = os.getenv('API_TOKEN', '')
        if not token or not hmac.compare_digest(headers.get('Authorization', '').encode('utf-8'), ('Bearer ' + token).encode('utf-8')):
            return 401, 'application/json', json.dumps({'error': 'unauthorized'})
        return 200, 'application/json', json.dumps({'app': 'devops-demo', 'version': os.getenv('APP_VERSION', 'local')})
    if url.path == '/work':
        try:
            rounds = int(parse_qs(url.query).get('rounds', ['10000'])[0])
            if not 1 <= rounds <= 100000:
                raise ValueError
        except ValueError:
            return 400, 'application/json', json.dumps({'error': 'rounds must be 1..100000'})
        digest = hashlib.pbkdf2_hmac('sha256', b'devops-lab', b'load-demo', rounds).hex()
        return 200, 'application/json', json.dumps({'rounds': rounds, 'digest': digest})
    if url.path == '/':
        import html
        message = html.escape(os.getenv('APP_MESSAGE', 'Hello from Aryan\u2019s DevOps final project'))
        return 200, 'text/html; charset=utf-8', f'<!doctype html><html><title>DevOps Demo</title><h1>{message}</h1><p>Health: <a href="/healthz">/healthz</a> | Metrics: <a href="/metrics">/metrics</a></p></html>'
    return 404, 'application/json', json.dumps({'error': 'not found'})


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        started = time.monotonic()
        request_id = str(uuid.uuid4())
        status, mime, body = response(self.path, self.headers)
        content = body.encode()
        self.send_response(status)
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(len(content)))
        self.send_header('X-Request-ID', request_id)
        self.end_headers()
        self.wfile.write(content)
        print(json.dumps({'request_id': request_id, 'path': self.path.split('?', 1)[0],
                          'status': status, 'duration_ms': round((time.monotonic()-started)*1000, 3)}), flush=True)

    def log_message(self, *_):
        pass  # structured log above deliberately excludes auth headers


if __name__ == '__main__':
    ThreadingHTTPServer(('0.0.0.0', int(os.getenv('PORT', '8080'))), Handler).serve_forever()
