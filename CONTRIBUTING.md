# Contributing

## Dev setup (macOS)

```bash
git clone <your-fork-url>
cd fuckcc
chmod +x fuckcc install.sh hook/build_hook.sh ui/build_app.sh
./fuckcc install          # optional: install shims on your machine
./fuckcc hide 3
./ui/build_app.sh         # optional: build control panel app
```

## Layout

| Path | Role |
|------|------|
| `fuckcc` | Main CLI |
| `hooks/` | Claude Code UserPromptSubmit hook |
| `lib/` | Translate daemon / setup / upstream resolve |
| `proxy/` | Local reverse proxy for base URL camouflage |
| `ui/` | SwiftUI control panel |
| `hook/` | Optional dyld TZ/locale hook (C) |
| `data/` | Editable probe keyword list |
| `Formula/` | Homebrew formula template |

## Guidelines

- Keep **free local** translation as the default (no paid cloud defaults).  
- Do not add vendor-specific marketing or hard-coded commercial API hosts as defaults.  
- Prefer process-local changes; avoid destructive system-wide edits.  
- Test: `bash -n fuckcc` and a dry `fuckcc probe` / `fuckcc hide status`.  

## Pull requests

- Small, focused PRs  
- Update `CHANGELOG.md` and `VERSION` when user-visible behavior changes  
