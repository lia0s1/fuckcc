#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$ROOT/libfuckcc_tz.dylib}"
clang -dynamiclib -O2 -arch arm64 -arch x86_64 \
  -install_name "@rpath/libfuckcc_tz.dylib" \
  -o "$OUT" \
  "$ROOT/tz_override.c"
echo "built: $OUT"
file "$OUT"
