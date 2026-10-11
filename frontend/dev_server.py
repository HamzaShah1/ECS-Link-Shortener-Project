
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError
import json

API_ORIGIN = "https://hamza-aws-project.com"
DASHBOARD_ORIGIN = "https://dashboard.hamza-aws-project.com"


class Handler(SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/shorten":
            self.send_error(404)
            return

        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)

        try:
            request = Request(
                API_ORIGIN + "/shorten",
                data=body,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urlopen(request, timeout=15) as response:
                self.respond(response.status, response.read())
        except HTTPError as error:
            self.respond(error.code, error.read())
        except (URLError, TimeoutError) as error:
            self.respond(502, json.dumps({"error": str(error)}).encode())

    def do_GET(self):
        if self.path.startswith(("/summary", "/top", "/recent", "/url/")):
            try:
                request = Request(DASHBOARD_ORIGIN + self.path)
                with urlopen(request, timeout=15) as response:
                    self.respond(response.status, response.read())
            except HTTPError as error:
                self.respond(error.code, error.read())
            except (URLError, TimeoutError) as error:
                self.respond(502, json.dumps({"error": str(error)}).encode())
            return

        super().do_GET()

    def respond(self, status, body):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


ThreadingHTTPServer(("127.0.0.1", 3001), Handler).serve_forever()
