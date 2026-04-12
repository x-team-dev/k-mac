# k-mac

One-command Mac setup for Korean users.

```bash
curl -fsSL djohnkang.github.io/setup.sh | bash
```

## What it does

**macOS Settings**
- Fast key repeat, disable autocorrect/autocapitalize
- Mouse: max tracking speed, secondary click, smart zoom
- Dock: clean up, keep only Messages, Calendar, System Settings
- Finder: open Downloads by default, gallery view, path bar, status bar
- Screenshots: save to `~/Screenshots`

**Keyboard (한/영)**
- Right Command → F18 for input source switching
- Caps Lock → Control
- Persists across reboots via LaunchAgent

**Homebrew**
- Auto-install with Apple Silicon / Intel detection

**Apps** (each optional, default Yes)
| Category | Default |
|----------|---------|
| Browser | Chrome |
| Terminal | iTerm2 |
| Launcher | Raycast |
| AI | Claude, Claude Code, ChatGPT, Codex, Codex App, Gemini CLI |

## Requirements

- macOS Catalina or later
- Fresh or existing Mac (idempotent — safe to re-run)

## How it works

The script runs in 4 phases:

1. **macOS defaults** — `defaults write` commands, no dependencies needed
2. **Keyboard remapping** — `hidutil` + LaunchAgent (requires `sudo`)
3. **Homebrew** — install if missing, load into current shell
4. **Apps** — interactive prompts, Enter to accept defaults

## Customization

Fork this repo and edit `setup.sh` to match your preferences:

- Change Dock apps (line ~47-50)
- Swap default apps in Phase 4
- Add/remove macOS settings in Phase 1

---

**한국어**

새 Mac에서 터미널을 열고 위 명령어 한 줄이면 끝입니다.
한/영 전환(Right Command → F18), macOS 기본 설정, 브라우저, 터미널, AI 도구까지 한 번에 설치됩니다.

## License

MIT
