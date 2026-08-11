#!/usr/bin/env bash
set -euo pipefail
REPO_SLUG="${FUCKCC_REPO:-}"
BRANCH="${FUCKCC_BRANCH:-main}"
PREFIX="${FUCKCC_PREFIX:-$HOME/.local/share/fuckcc}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || true)"
install_from_dir() {
  local src="$1"
  mkdir -p "$(dirname "$PREFIX")"
  rsync -a --delete --exclude '.git' --exclude '*.argosmodel' --exclude '__pycache__' \
    "$src"/ "$PREFIX"/ 2>/dev/null || {
    rm -rf "$PREFIX"
    mkdir -p "$PREFIX"
    cp -R "$src"/. "$PREFIX"/
    rm -rf "$PREFIX/.git" 2>/dev/null || true
  }
  chmod +x "$PREFIX/fuckcc" "$PREFIX/install.sh" "$PREFIX/hook/build_hook.sh" "$PREFIX/ui/build_app.sh" 2>/dev/null || true
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$PREFIX/fuckcc" "$HOME/.local/bin/fuckcc"
  echo "[install] prefix=$PREFIX"
  "$PREFIX/fuckcc" install || true
  "$PREFIX/fuckcc" hide 3 || true
  "$PREFIX/fuckcc" translate-setup || true
  "$PREFIX/fuckcc" translate-daemon-start || true
  echo
  echo "Done. Open a new terminal, then:"
  echo "  fuckcc use us-west"
  echo "  fuckcc mode bypass"
  echo "  cd /path/to/project && claude"
  echo "Optional UI: fuckcc ui   (or ./ui/build_app.sh)"
}
if [[ -n "${SCRIPT_DIR:-}" && -x "${SCRIPT_DIR}/fuckcc" && -f "${SCRIPT_DIR}/regions.json" ]]; then
  echo "[install] using local tree: $SCRIPT_DIR"
  install_from_dir "$SCRIPT_DIR"
  exit 0
fi
if [[ -z "$REPO_SLUG" ]]; then
  echo "Set FUCKCC_REPO=owner/name  or run ./install.sh from a git clone." >&2
  echo "Example:" >&2
  echo "  FUCKCC_REPO=lia0s1/fuckcc bash install.sh" >&2
  exit 1
fi
if ! command -v git >/dev/null; then
  echo "git is required" >&2
  exit 1
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "[install] cloning https://github.com/${REPO_SLUG}.git ($BRANCH)"
git clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO_SLUG}.git" "$TMP/repo"
install_from_dir "$TMP/repo"
