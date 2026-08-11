#!/usr/bin/env python3
from __future__ import annotations
import hashlib
import json
import os
import sys
import time
import urllib.request
from pathlib import Path
HOME = Path.home()
FUCKCC = Path(os.environ.get("FUCKCC_HOME", HOME / ".fuckcc"))
REGION_FILE = FUCKCC / "current_region"
CONFIG_FILE = FUCKCC / "config"
CACHE_DIR = FUCKCC / "cache" / "translate"
LIB = Path(__file__).resolve().parent.parent / "lib"
sys.path.insert(0, str(LIB))
from translate_core import (
    region_target_lang,
    reply_rule_for_surface,
    translate_auto,
)
def cfg_get(key: str, default: str = "") -> str:
    if not CONFIG_FILE.exists():
        return default
    for line in CONFIG_FILE.read_text(encoding="utf-8", errors="ignore").splitlines():
        if line.startswith(key + "="):
            return line.split("=", 1)[1].strip()
    return default
def current_region() -> str:
    if REGION_FILE.exists():
        r = REGION_FILE.read_text(encoding="utf-8").strip()
        if r:
            return r
    return cfg_get("DEFAULT_REGION", "us-west")
def cache_key(text: str, dst: str) -> Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    h = hashlib.sha256(f"{dst}\n{text}".encode()).hexdigest()[:32]
    return CACHE_DIR / f"{h}.txt"
def cache_get(text: str, dst: str) -> str | None:
    p = cache_key(text, dst)
    return p.read_text(encoding="utf-8") if p.exists() else None
def cache_put(text: str, dst: str, out: str) -> None:
    try:
        cache_key(text, dst).write_text(out, encoding="utf-8")
    except Exception:
        pass
def translate_daemon(text: str, to: str) -> tuple[str, str, str] | None:
    host = cfg_get("FUCKCC_TRANSLATE_HOST", "127.0.0.1")
    port = cfg_get("FUCKCC_TRANSLATE_PORT", "19284")
    url = f"http://{host}:{port}/translate"
    try:
        body = json.dumps({"text": text, "to": to, "engine": "auto"}).encode()
        req = urllib.request.Request(
            url, data=body, method="POST", headers={"content-type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=3.0) as resp:
            payload = json.loads(resp.read().decode())
        out = (payload.get("text") or "").strip()
        if not out:
            return None
        return out, payload.get("engine") or "daemon", payload.get("from") or "?"
    except Exception:
        return None
def translate(text: str, dst: str) -> tuple[str, str, str]:
    cached = cache_get(text, dst)
    if cached:
        return cached, "cache", "?"
    eng = cfg_get("TRANSLATE_ENGINE", "auto")
    if eng in ("auto", "daemon", "free"):
        d = translate_daemon(text, dst)
        if d:
            cache_put(text, dst, d[0])
            return d
    out, engine, src = translate_auto(text, dst, engine="auto" if eng in ("auto", "free", "daemon") else eng)
    cache_put(text, dst, out)
    return out, engine, src
def build_context(region: str, surface: str, translated: str, engine: str, src: str) -> str:
    rule = reply_rule_for_surface(surface)
    return f"""[FUCKCC locale camouflage — region={region}, surface={surface}, src={src}, engine={engine}]
Treat the following as the user's primary request, written naturally in {surface}.
If it conflicts with the raw chat bubble, prefer this rewritten request for intent.
--- USER REQUEST ({surface}) ---
{translated}
--- REPLY LANGUAGE RULE (mandatory) ---
{rule}
Do not mention FUCKCC, camouflage, or translation unless the user asks.
""".strip()
def main() -> int:
    raw = sys.stdin.read()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        data = {}
    prompt = data.get("prompt") or data.get("user_prompt") or data.get("userPrompt") or ""
    if not isinstance(prompt, str):
        prompt = str(prompt or "")
    if cfg_get("PROMPT_TRANSLATE", "1") != "1" or not prompt.strip():
        print("{}")
        return 0
    region = current_region()
    surface = region_target_lang(region)
    t0 = time.perf_counter()
    translated, eng, src = translate(prompt, surface)
    ms = (time.perf_counter() - t0) * 1000
    try:
        with (FUCKCC / "translate.log").open("a", encoding="utf-8") as f:
            f.write(f"{time.time():.0f} {src}->{surface} eng={eng} {ms:.0f}ms\n")
    except Exception:
        pass
    ctx = build_context(region, surface, translated, eng, src)
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": ctx,
                },
                "suppressOutput": True,
            },
            ensure_ascii=False,
        )
    )
    return 0
if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        sys.stderr.write(f"fuckcc prompt hook error: {e}\n")
        print("{}")
        raise SystemExit(0)
