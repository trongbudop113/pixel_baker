import json
import http.server
import sys
import threading
from typing import Optional
import urllib.parse
import urllib.request


SCOPES = ["https://www.googleapis.com/auth/drive"]
REDIRECT_URI = "http://localhost:8765/oauth2callback"


class OAuthCallbackHandler(http.server.BaseHTTPRequestHandler):
    code: Optional[str] = None
    error: Optional[str] = None

    def do_GET(self) -> None:
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)
        OAuthCallbackHandler.code = params.get("code", [None])[0]
        OAuthCallbackHandler.error = params.get("error", [None])[0]
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(
            "OAuth complete. You can close this tab and return to Terminal.".encode(
                "utf-8"
            )
        )

    def log_message(self, format: str, *args: object) -> None:
        return


def main() -> int:
    client_id = input("GOOGLE_DRIVE_OAUTH_CLIENT_ID: ").strip()
    client_secret = input("GOOGLE_DRIVE_OAUTH_CLIENT_SECRET: ").strip()
    if not client_id or not client_secret:
        print("Client id/secret are required.", file=sys.stderr)
        return 1

    params = {
        "client_id": client_id,
        "redirect_uri": REDIRECT_URI,
        "response_type": "code",
        "scope": " ".join(SCOPES),
        "access_type": "offline",
        "prompt": "consent",
    }
    auth_url = "https://accounts.google.com/o/oauth2/v2/auth?" + urllib.parse.urlencode(
        params
    )
    print("\nOpen this URL and approve access:\n")
    print(auth_url)

    server = http.server.HTTPServer(("localhost", 8765), OAuthCallbackHandler)
    thread = threading.Thread(target=server.handle_request, daemon=True)
    thread.start()
    print("\nWaiting for Google OAuth callback on http://localhost:8765 ...")
    thread.join(timeout=180)
    server.server_close()

    if OAuthCallbackHandler.error:
        print(f"Google OAuth error: {OAuthCallbackHandler.error}", file=sys.stderr)
        return 1
    code = (OAuthCallbackHandler.code or "").strip()
    if not code:
        print("Authorization code is required.", file=sys.stderr)
        return 1

    body = urllib.parse.urlencode(
        {
            "code": code,
            "client_id": client_id,
            "client_secret": client_secret,
            "redirect_uri": REDIRECT_URI,
            "grant_type": "authorization_code",
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        "https://oauth2.googleapis.com/token",
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        print(error.read().decode("utf-8"), file=sys.stderr)
        return 1

    refresh_token = payload.get("refresh_token")
    if not refresh_token:
        print(
            "Google did not return a refresh_token. Make sure access_type=offline "
            "and prompt=consent are present, then try again.",
            file=sys.stderr,
        )
        return 1

    print("\nSet this value on Render:")
    print(f"GOOGLE_DRIVE_OAUTH_REFRESH_TOKEN={refresh_token}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
