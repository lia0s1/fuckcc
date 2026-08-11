# Publish to GitHub (5 minutes)

## 1. Create empty repo on GitHub

- Name: `fuckcc` (or anything)
- Public
- **Do not** add README/License on GitHub (we already have them)

## 2. Fix git identity (once)

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
cd ~/Desktop/fuckcc
git commit --amend --reset-author --no-edit
```

## 3. Push

```bash
cd ~/Desktop/fuckcc
git remote add origin git@github.com:lia0s1/fuckcc.git
# or: https://github.com/lia0s1/fuckcc.git
git push -u origin main
```

## 4. Tag release

```bash
git tag v4.4.0
git push origin v4.4.0
```

GitHub → Releases → Draft from tag → paste CHANGELOG 4.4.0 section.

## 5. Homebrew formula (optional)

```bash
curl -sL https://github.com/lia0s1/fuckcc/archive/refs/tags/v4.4.0.tar.gz | shasum -a 256
```

Edit `Formula/fuckcc.rb`: set `homepage`, `url`, `sha256`, replace `lia0s1`.

Users:

```bash
brew tap lia0s1/fuckcc https://github.com/lia0s1/fuckcc
brew install fuckcc
```

## 6. Install script

Users after push:

```bash
FUCKCC_REPO=lia0s1/fuckcc bash -c \
  'curl -fsSL https://raw.githubusercontent.com/$FUCKCC_REPO/main/install.sh | bash'
```

Or clone + `./install.sh`.

## Do not upload

- `~/.fuckcc` (keys, proxy state, logs)
- Built `FuckCC.app`
- Large `.argosmodel` files
