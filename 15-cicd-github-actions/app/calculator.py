"""Small calculator API, with no third-party runtime dependencies."""
import json
import math
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse


def calculate(operation, a, b):
    a, b = float(a), float(b)
    if not math.isfinite(a) or not math.isfinite(b):
        raise ValueError("Operands must be finite")
    if operation == "add":
        result = a + b
    elif operation == "subtract":
        result = a - b
    elif operation == "multiply":
        result = a * b
    elif operation == "divide":
        if b == 0:
            raise ValueError("Cannot divide by zero")
        result = a / b
    else:
        raise ValueError("Unknown operation")
    if not math.isfinite(result):
        raise ValueError("Result must be finite")
    return result


def response(path):
    parsed = urlparse(path)
    if parsed.path == "/health":
        return 200, {"status": "ok"}
    if parsed.path == "/":
        return 200, {"app": "DevOps calculator", "example": "/calculate?op=add&a=2&b=3"}
    if parsed.path != "/calculate":
        return 404, {"error": "Not found"}
    try:
        args = parse_qs(parsed.query)
        return 200, {"result": calculate(args["op"][0], args["a"][0], args["b"][0])}
    except (KeyError, ValueError, OverflowError) as error:
        return 400, {"error": str(error)}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        status, body = response(self.path)
        data = json.dumps(body, allow_nan=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    # Container demo must listen on its network interface, not only loopback.
    ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()  # nosec B104
