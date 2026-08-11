#!/usr/bin/env python3
from __future__ import annotations
import json
import os
import sys
from pathlib import Path
HOME = Path.home()
def is_local(url: str) -> bool:
    u = (url or "").lower()
    return "127.0.0.1" in u or "localhost" in u
def main() -> int:
    candidates = []
    for k in ("FUCKCC_UPSTREAM",):
        v = os.environ.get(k)
        if v:
            candidates.append(v)
    v = os.environ.get("ANTHROPIC_BASE_URL")
    if v and not is_local(v):
        candidates.append(v)
    sp = HOME / ".claude" / "settings.json"
    if sp.exists():
        try:
            env = (json.loads(sp.read_text(encoding="utf-8")).get("env") or {})
            b = env.get("ANTHROPIC_BASE_URL") or ""
            if b and not is_local(b):
                candidates.append(b)
        except Exception:
            pass
    cfg = Path(os.environ.get("FUCKCC_HOME", HOME / ".fuckcc")) / "config"
    if cfg.exists():
        for line in cfg.read_text(encoding="utf-8", errors="ignore").splitlines():
            if line.startswith("FUCKCC_UPSTREAM="):
                candidates.append(line.split("=", 1)[1].strip())
    candidates.append("https://api.anthropic.com")
    for c in candidates:
        c = (c or "").strip().rstrip("/")
        if c and not is_local(c):
            print(c)
            return 0
    print("https://api.anthropic.com")
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
