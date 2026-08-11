#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UI="$ROOT/ui"
OUT_DIR="${1:-$HOME/.fuckcc}"
APP="$OUT_DIR/FuckCC.app"
BIN="$APP/Contents/MacOS/FuckCC"
RES="$APP/Contents/Resources"
ICON_SRC="/Applications/Claude.app/Contents/Resources/electron.icns"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$RES"
cp "$ROOT/regions.json" "$RES/regions.json"
if [[ -f "$ICON_SRC" ]]; then
  cp "$ICON_SRC" "$RES/AppIcon.icns"
  echo "[build] icon from Claude.app"
else
  echo "[build] WARNING: Claude.app icon not found at $ICON_SRC"
fi
echo "[build] compiling…"
xcrun swiftc -O \
  -target arm64-apple-macos26.0 \
  -parse-as-library \
  -sdk "$(xcrun --show-sdk-path)" \
  -framework SwiftUI -framework AppKit \
  -o "$BIN" \
  "$UI/FuckCCApp.swift"
cat >"$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>fuckcc</string>
  <key>CFBundleDisplayName</key><string>fuckcc</string>
  <key>CFBundleIdentifier</key><string>local.fuckcc.control</string>
  <key>CFBundleVersion</key><string>4.4.2</string>
  <key>CFBundleShortVersionString</key><string>4.4.2</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>FuckCC</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>26.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSUIElement</key><false/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST
chmod +x "$BIN"
DESKTOP_APP="$HOME/Desktop/FuckCC.app"
rm -rf "$DESKTOP_APP"
cp -R "$APP" "$DESKTOP_APP"
codesign --force --deep --sign - "$APP" 2>/dev/null || true
codesign --force --deep --sign - "$DESKTOP_APP" 2>/dev/null || true
echo "[build] $APP"
echo "[build] $DESKTOP_APP"
echo "open: open \"$DESKTOP_APP\""
