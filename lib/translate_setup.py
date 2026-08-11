#!/usr/bin/env python3
from __future__ import annotations
import json
import subprocess
import sys
import urllib.request
from pathlib import Path
FUCKCC = Path.home() / ".fuckcc"
MODELS = FUCKCC / "models"
APPLE = FUCKCC / "bin" / "apple_translate"
INDEX_URL = "https://raw.githubusercontent.com/argosopentech/argospm-index/main/index.json"
WANTED = {
    ("zh", "en"),
    ("en", "zh"),
    ("en", "ja"),
    ("ja", "en"),
    ("en", "de"),
    ("de", "en"),
    ("en", "ko"),
    ("ko", "en"),
    ("en", "es"),
    ("es", "en"),
    ("en", "fr"),
    ("fr", "en"),
    ("en", "pt"),
    ("pt", "en"),
    ("en", "ru"),
    ("ru", "en"),
    ("en", "it"),
    ("it", "en"),
}
def download(url: str, dest: Path) -> bool:
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        r = subprocess.run(
            ["curl", "-fsSL", "--max-time", "300", "-o", str(dest), url],
            capture_output=True,
            text=True,
        )
        return r.returncode == 0 and dest.exists() and dest.stat().st_size > 1000
    except Exception:
        return False
def main() -> int:
    print("=== Apple on-device ===")
    if APPLE.is_file():
        for src, dst in [("zh-Hans", "en"), ("en", "ja"), ("en", "de"), ("en", "ko")]:
            r = subprocess.run(
                [str(APPLE), "--status", "--from", src, "--to", dst],
                capture_output=True,
                text=True,
            )
            print(f"  {src}->{dst}: {(r.stdout or '').strip()}")
        print("  安装语言包: 系统设置 → 通用 → 语言与地区 → 翻译语言")
    else:
        print("  apple_translate 未编译（可选）")
    print("\n=== Argos offline packages ===")
    try:
        import argostranslate.package as pkg
    except Exception as e:
        print("  请先: pip3 install --user argostranslate")
        print(" ", e)
        return 1
    idx_path = MODELS / "argos-index.json"
    print("  fetching package index…")
    if not download(INDEX_URL, idx_path):
        print("  index download failed")
        return 1
    index = json.loads(idx_path.read_text(encoding="utf-8"))
    links = {}
    for item in index:
        fr, to = item.get("from_code"), item.get("to_code")
        ls = item.get("links") or []
        if fr and to and ls:
            links[(fr, to)] = ls[0]
    installed = {(p.from_code, p.to_code) for p in pkg.get_installed_packages()}
    print("  already:", sorted(installed))
    for pair in sorted(WANTED):
        if pair in installed:
            continue
        url = links.get(pair)
        if not url:
            print(f"  skip {pair}: not in index")
            continue
        dest = MODELS / f"translate-{pair[0]}_{pair[1]}.argosmodel"
        print(f"  download {pair} …")
        if not download(url, dest):
            print(f"  FAIL download {pair}")
            continue
        try:
            pkg.install_from_path(str(dest))
            print(f"  OK {pair}")
        except Exception as e:
            print(f"  FAIL install {pair}: {e}")
    installed = {(p.from_code, p.to_code) for p in pkg.get_installed_packages()}
    print("  installed now:", sorted(installed))
    try:
        import argostranslate.translate as tr
        if ("zh", "en") in installed:
            print("  sample zh->en:", tr.translate("帮我写个排序", "zh", "en"))
    except Exception as e:
        print("  smoke fail", e)
    print("\nDone. Restart translate-daemon: fuckcc translate-daemon-start")
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
