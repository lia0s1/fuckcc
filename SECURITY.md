# Security

## What this project does

`fuckcc` modifies the **Claude Code CLI process environment** (timezone, locale, optional local reverse proxy, prompt hooks). It is intended for privacy / anti-fingerprinting experiments on machines **you control**.

## What it does *not* do

- Does not change macOS system timezone by default  
- Does not bypass account billing, IP geolocation, or payment checks  
- Does not require or ship API keys  

## Reporting issues

If you find a vulnerability in the installers, proxy, or hook path:

1. Open a private security advisory on GitHub if available, or  
2. File an issue **without** pasting secrets, tokens, or personal paths  

## Safe publishing checklist

Before push / release:

- [ ] No `ANTHROPIC_*` keys or tokens in the tree  
- [ ] No machine-specific paths hardcoded as the only option  
- [ ] No built `FuckCC.app` / large `.argosmodel` binaries committed  
- [ ] `~/.fuckcc` state is gitignored and not copied into the repo  
