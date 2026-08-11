<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-black?style=for-the-badge" alt="macOS" />
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="MIT" />
  <img src="https://img.shields.io/badge/version-4.4.1-orange?style=for-the-badge" alt="version" />
</p>

<h1 align="center">fuckcc</h1>

<p align="center">
  <b>🇨🇳 中文</b> · <a href="#-english">🇬🇧 English</a> · <a href="#-日本語">🇯🇵 日本語</a> · <a href="#-한국어">🇰🇷 한국어</a>
</p>

---

## 🇨🇳 中文

### 这是什么

**fuckcc** 是 macOS 上给 **Claude Code** 用的**进程级环境配置工具**：

- 只影响 Claude 进程（时区 / 语言环境等），**不改系统时区**
- 安装一次后，终端直接 `claude` 即可，**不必每次打开 App**
- 支持本地免费提示词翻译（任意语言 → 所选地区语言，并要求用中文回答）
- 支持启动模式（含 `--dangerously-skip-permissions`）
- 可选图形界面（选目录、地区、模式、翻译开关、使用说明）

> 仅在你有权使用的机器上使用，请遵守相关服务条款与当地法律。

### 安装

```bash
git clone https://github.com/lia0s1/fuckcc.git
cd fuckcc
./install.sh
```

新开终端：

```bash
fuckcc use us-west
fuckcc mode bypass
fuckcc hide 3
cd 你的项目目录
claude
```

一键安装：

```bash
FUCKCC_REPO=lia0s1/fuckcc bash -c \
  'curl -fsSL https://raw.githubusercontent.com/$FUCKCC_REPO/main/install.sh | bash'
```

Homebrew（可选）：

```bash
brew tap lia0s1/fuckcc https://github.com/lia0s1/fuckcc
brew install fuckcc
fuckcc install && fuckcc hide 3
```

### 常用命令

| 命令 | 作用 |
|------|------|
| `fuckcc install` | 安装包装，让 `claude` 自动走伪装环境 |
| `fuckcc use us-west` | 选择地区配置 |
| `fuckcc mode bypass` | 启动参数含 `--dangerously-skip-permissions` |
| `fuckcc hide 3` | 最深环境配置 |
| `fuckcc translate on/off` | 开关提示词翻译 |
| `fuckcc lang zh/en/ja/ko/de` | App 界面语言 |
| `fuckcc ui` | 打开图形界面 |
| `fuckcc status` / `probe` | 查看状态 / 环境探测 |

### 图形界面

```bash
./ui/build_app.sh
open ~/Desktop/FuckCC.app
# 或
fuckcc ui
```

界面内可设置：地区、启动模式、工作目录、翻译开关、界面语言、伪装深度，并内置使用说明。

### 翻译说明

- 开启后：输入任意语言 → 译成当前地区语言 → 并注明用**简体中文**回答  
- 默认**本地免费**（Argos / Apple 翻译），不依赖付费云翻译  
- 与上游模型（官方 API 或你自配的兼容接口）**无关**：翻译在本地 hook 中完成  

### 关于「深度」

| 级别 | 说明 |
|------|------|
| 1 | 时区 / 语言环境变量 |
| 2 | 更强环境清理 + 地区人设提示 + 本地反代等 |
| 3 | 进一步清理终端相关环境噪声 |

**无法覆盖：** 公网 IP、支付/账号策略、系统电脑名等。

---

## 🇬🇧 English

### What it is

**fuckcc** is a **process-local environment helper** for Claude Code on macOS:

- Affects only the Claude process (timezone / locale, etc.); **does not change the system timezone**
- After one install, run plain `claude` — **no need to open the app every day**
- Optional free local prompt translation (any language → region language; reply in Simplified Chinese)
- Launch modes (including `--dangerously-skip-permissions`)
- Optional GUI (folder picker, region, modes, translation toggle, guide)

> Use only on machines you control. Follow Anthropic terms and local law.

### Install

```bash
git clone https://github.com/lia0s1/fuckcc.git
cd fuckcc && ./install.sh
```

Then in a new terminal:

```bash
fuckcc use us-west
fuckcc mode bypass
fuckcc hide 3
cd /path/to/project && claude
```

### Daily commands

```bash
fuckcc install | use <region> | mode bypass | hide 3
fuckcc translate on|off | lang en|zh|ja|ko|de | ui
claude
```

### Translation

Runs **locally before** the request hits your model provider. Works with official or custom Anthropic-compatible endpoints.

---

## 🇯🇵 日本語

### 概要

**fuckcc** は macOS 上の Claude Code 向け **プロセス単位** の環境設定ツールです。

- システム時区は変更しません  
- 一度 `install` すれば、普段は `claude` だけで利用できます  
- 任意言語のプロンプトを選択地域の言語へローカル無料翻訳（返答は簡体字中国語を指定）  
- 起動モード（`--dangerously-skip-permissions` を含む）  
- 任意の GUI  

### インストール

```bash
git clone https://github.com/lia0s1/fuckcc.git
cd fuckcc && ./install.sh
```

```bash
fuckcc use us-west
fuckcc mode bypass
fuckcc hide 3
cd プロジェクト && claude
```

### よく使うコマンド

```bash
fuckcc install / use / mode / hide / translate / lang / ui
```

---

## 🇰🇷 한국어

### 소개

**fuckcc**는 macOS Claude Code용 **프로세스 단위** 환경 설정 도구입니다.

- 시스템 시간대는 변경하지 않음  
- 한 번 `install` 하면 평소에는 `claude` 만 실행  
- 모든 입력 언어 → 선택 지역 언어로 로컬 무료 번역 (답변은 중국어 간체 지시)  
- 실행 모드 (`--dangerously-skip-permissions` 포함)  
- 선택적 GUI  

### 설치

```bash
git clone https://github.com/lia0s1/fuckcc.git
cd fuckcc && ./install.sh
```

```bash
fuckcc use us-west
fuckcc mode bypass
fuckcc hide 3
cd 프로젝트 && claude
```

---

## Project layout

```text
fuckcc/          CLI
hooks/           prompt hook
lib/             local translate daemon
proxy/           local reverse proxy
ui/              SwiftUI app
hook/            optional dyld helper (C)
data/            keyword list for probes
Formula/         Homebrew formula
install.sh
```

---

## License

[MIT](./LICENSE)

## Docs

- [SECURITY.md](./SECURITY.md)  
- [CONTRIBUTING.md](./CONTRIBUTING.md)  
- [CHANGELOG.md](./CHANGELOG.md)  
