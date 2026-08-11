#!/usr/bin/env python3
from __future__ import annotations
import json
import os
import sqlite3
import sys
from pathlib import Path

HOME = Path.home()


def is_local(url: str) -> bool:
    u = (url or "").lower().strip()
    if not u:
        return True
    return (
        "127.0.0.1" in u
        or "localhost" in u
        or u.startswith("http://[::1]")
        or ":19283" in u
    )


def clean(url: str) -> str:
    return (url or "").strip().rstrip("/")


def from_cc_switch() -> str:
    db = HOME / ".cc-switch" / "cc-switch.db"
    if not db.exists():
        return ""
    try:
        con = sqlite3.connect(str(db))
        cur = con.cursor()
        cur.execute(
            "SELECT settings_config FROM providers "
            "WHERE app_type=? AND is_current=1 LIMIT 1",
            ("claude",),
        )
        row = cur.fetchone()
        con.close()
        if not row:
            return ""
        data = json.loads(row[0])
        env = data.get("env") if isinstance(data.get("env"), dict) else data
        if not isinstance(env, dict):
            return ""
        b = clean(env.get("ANTHROPIC_BASE_URL") or "")
        if b and not is_local(b):
            return b
    except Exception:
        return ""
    return ""


def from_settings() -> str:
    sp = HOME / ".claude" / "settings.json"
    if not sp.exists():
        return ""
    try:
        env = json.loads(sp.read_text(encoding="utf-8")).get("env") or {}
        b = clean(env.get("ANTHROPIC_BASE_URL") or "")
        if b and not is_local(b):
            return b
    except Exception:
        return ""
    return ""


def from_config() -> str:
    cfg = Path(os.environ.get("FUCKCC_HOME", HOME / ".fuckcc")) / "config"
    if not cfg.exists():
        return ""
    for line in cfg.read_text(encoding="utf-8", errors="ignore").splitlines():
        if line.startswith("FUCKCC_UPSTREAM="):
            b = clean(line.split("=", 1)[1])
            if b and not is_local(b):
                return b
    return ""


def main() -> int:
    # Priority for CC Switch users:
    # 1) explicit process env FUCKCC_UPSTREAM
    # 2) CC Switch current provider (source of truth when routing)
    # 3) ~/.fuckcc/config FUCKCC_UPSTREAM
    # 4) settings.json non-local BASE_URL
    # 5) shell ANTHROPIC_BASE_URL (often stale)
    # 6) anthropic official
    candidates = []
    env_up = clean(os.environ.get("FUCKCC_UPSTREAM") or "")
    if env_up and not is_local(env_up):
        candidates.append(env_up)
    cs = from_cc_switch()
    if cs:
        candidates.append(cs)
    cfg = from_config()
    if cfg:
        candidates.append(cfg)
    st = from_settings()
    if st:
        candidates.append(st)
    shell = clean(os.environ.get("ANTHROPIC_BASE_URL") or "")
    if shell and not is_local(shell):
        candidates.append(shell)
    candidates.append("https://api.anthropic.com")
    for c in candidates:
        c = clean(c)
        if c and not is_local(c):
            print(c)
            return 0
    print("https://api.anthropic.com")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
