#!/usr/bin/env python3
\
\
\
\
from __future__ import annotations
import json
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from translate_core import translate_auto
HOST = os.environ.get("FUCKCC_TRANSLATE_HOST", "127.0.0.1")
PORT = int(os.environ.get("FUCKCC_TRANSLATE_PORT", "19284"))
HOME = Path.home()
STATE = Path(os.environ.get("FUCKCC_HOME", HOME / ".fuckcc")) / "translate_daemon.state.json"
_ready = False
def warm():
    global _ready
    try:
        import argostranslate.translate as tr
        from translate_core import _argos_installed
        if _argos_installed("zh", "en"):
            tr.translate("暖机", "zh", "en")
    except Exception:
        pass
    _ready = True
class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write("[translate-daemon] " + (fmt % args) + "\n")
    def _json(self, code: int, obj: dict):
        b = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("content-type", "application/json; charset=utf-8")
        self.send_header("content-length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)
    def do_GET(self):
        if self.path.startswith("/health"):
            self._json(200, {"ok": True, "ready": _ready, "pid": os.getpid(), "multi": True})
            return
        self._json(404, {"error": "not found"})
    def do_POST(self):
        if not self.path.startswith("/translate"):
            self._json(404, {"error": "not found"})
            return
        n = int(self.headers.get("content-length") or 0)
        raw = self.rfile.read(n) if n else b"{}"
        try:
            data = json.loads(raw.decode("utf-8"))
        except Exception:
            self._json(400, {"error": "bad json"})
            return
        text = data.get("text") or ""
        to = (data.get("to") or "en").split("-")[0]
        engine = data.get("engine") or "auto"
        if not text:
            self._json(400, {"error": "empty text"})
            return
        try:
            t0 = time.perf_counter()
            out, eng, src = translate_auto(text, to, engine=engine)
            ms = (time.perf_counter() - t0) * 1000
            self._json(
                200,
                {
                    "text": out,
                    "engine": eng,
                    "from": src,
                    "to": to,
                    "ms": round(ms, 1),
                },
            )
        except Exception as e:
            self._json(500, {"error": str(e)})
def main() -> int:
    print("[translate-daemon] warming…", flush=True)
    t0 = time.time()
    warm()
    print(f"[translate-daemon] ready {(time.time()-t0)*1000:.0f}ms", flush=True)
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps({"pid": os.getpid(), "host": HOST, "port": PORT}, indent=2))
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"[translate-daemon] http://{HOST}:{PORT}", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        try:
            STATE.unlink()
        except Exception:
            pass
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
