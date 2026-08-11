#!/usr/bin/env python3
from __future__ import annotations
import os
import re
import subprocess
from pathlib import Path
HOME = Path.home()
FUCKCC = Path(os.environ.get("FUCKCC_HOME", HOME / ".fuckcc"))
APPLE_BIN = FUCKCC / "bin" / "apple_translate"
REGION_LANG = {
    "us-west": ("en", "en", "en", "zh"),
    "us-east": ("en", "en", "en", "zh"),
    "us-central": ("en", "en", "en", "zh"),
    "jp": ("ja", "ja", "ja", "zh"),
    "sg": ("en", "en", "en", "zh"),
    "tw": ("en", "en", "en", "zh"),
    "hk": ("en", "en", "en", "zh"),
    "kr": ("ko", "ko", "ko", "zh"),
    "uk": ("en", "en", "en", "zh"),
    "de": ("de", "de", "de", "zh"),
    "au": ("en", "en", "en", "zh"),
    "ca": ("en", "en", "en", "zh"),
}
REPLY_RULES = {
    "en": (
        "IMPORTANT: Always reply to the user in Simplified Chinese (简体中文). "
        "Keep code identifiers, file paths, and shell commands in English."
    ),
    "ja": (
        "重要: ユーザーへの最終回答は必ず中国語（簡体字）で書いてください。"
        "コード・パス・コマンドは英語のままで構いません。"
    ),
    "ko": (
        "중요: 최종 답변은 반드시 중국어 간체(简体中文)로 작성하세요. "
        "코드/경로/명령어는 영어 유지."
    ),
    "de": (
        "WICHTIG: Antworte dem Nutzer immer auf Vereinfachtem Chinesisch (简体中文). "
        "Code, Pfade und Befehle bleiben auf Englisch."
    ),
    "zh": (
        "重要：请始终使用简体中文回复用户。"
        "代码标识符、路径和命令保持英文。"
    ),
}
def detect_lang(text: str) -> str:
    if not text or not text.strip():
        return "en"
    cjk = sum(1 for c in text if "\u4e00" <= c <= "\u9fff")
    hira = sum(1 for c in text if "\u3040" <= c <= "\u309f")
    kata = sum(1 for c in text if "\u30a0" <= c <= "\u30ff")
    hang = sum(1 for c in text if "\uac00" <= c <= "\ud7af")
    letters = sum(1 for c in text if c.isalpha() or ("\u4e00" <= c <= "\u9fff") or ("\u3040" <= c <= "\ud7af"))
    if letters == 0:
        return "en"
    if hang / max(letters, 1) > 0.15:
        return "ko"
    if (hira + kata) / max(letters, 1) > 0.08:
        return "ja"
    if cjk / max(letters, 1) > 0.2:
        return "zh"
    if re.search(r"[äöüÄÖÜß]", text):
        return "de"
    return "en"
def apple_status(src: str, dst: str) -> str:
    if not APPLE_BIN.is_file():
        return "missing"
    src_a = _apple_code(src)
    dst_a = _apple_code(dst)
    try:
        r = subprocess.run(
            [str(APPLE_BIN), "--status", "--from", src_a, "--to", dst_a],
            capture_output=True,
            text=True,
            timeout=3,
        )
        return (r.stdout or "").strip() or "error"
    except Exception:
        return "error"
def _apple_code(code: str) -> str:
    return {
        "zh": "zh-Hans",
        "en": "en",
        "ja": "ja",
        "ko": "ko",
        "de": "de",
        "fr": "fr",
        "es": "es",
        "pt": "pt-BR",
        "it": "it",
        "ru": "ru",
    }.get(code, code)
def translate_apple(text: str, src: str, dst: str) -> str | None:
    if not APPLE_BIN.is_file() or src == dst:
        return text if src == dst else None
    if apple_status(src, dst) != "installed":
        return None
    try:
        r = subprocess.run(
            [
                str(APPLE_BIN),
                "--from",
                _apple_code(src),
                "--to",
                _apple_code(dst),
                "--strategy",
                "lowLatency",
                text,
            ],
            capture_output=True,
            text=True,
            timeout=12,
        )
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()
    except Exception:
        return None
    return None
def _argos_installed(src: str, dst: str) -> bool:
    try:
        import argostranslate.package as pkg
        return any(p.from_code == src and p.to_code == dst for p in pkg.get_installed_packages())
    except Exception:
        return False
def translate_argos(text: str, src: str, dst: str) -> str | None:
    if src == dst:
        return text
    try:
        import argostranslate.translate as tr
    except Exception:
        return None
    if _argos_installed(src, dst):
        try:
            return (tr.translate(text, src, dst) or "").strip() or None
        except Exception:
            return None
    if src != "en" and dst != "en":
        if _argos_installed(src, "en") and _argos_installed("en", dst):
            try:
                mid = tr.translate(text, src, "en")
                if not mid:
                    return None
                return (tr.translate(mid, "en", dst) or "").strip() or None
            except Exception:
                return None
    if src != "en" and _argos_installed(src, "en") and dst == "en":
        try:
            return (tr.translate(text, src, "en") or "").strip() or None
        except Exception:
            return None
    if src == "en" and _argos_installed("en", dst):
        try:
            return (tr.translate(text, "en", dst) or "").strip() or None
        except Exception:
            return None
    return None
def translate_auto(text: str, dst: str, engine: str = "auto") -> tuple[str, str, str]:
\
\
    src = detect_lang(text)
    if src == dst:
        return text, "passthrough", src
    order = []
    if engine == "auto":
        order = ["apple", "argos"]
    elif engine in ("apple", "argos"):
        order = [engine]
    else:
        order = ["apple", "argos"]
    for eng in order:
        out = None
        if eng == "apple":
            out = translate_apple(text, src, dst)
        elif eng == "argos":
            out = translate_argos(text, src, dst)
        if out:
            return out, eng, src
    return f"[{src}->{dst}] {text}", "fallback", src
def region_target_lang(region_id: str) -> str:
    meta = REGION_LANG.get(region_id) or REGION_LANG["us-west"]
    return meta[0]
def reply_rule_for_surface(surface: str) -> str:
    return REPLY_RULES.get(surface, REPLY_RULES["en"])
