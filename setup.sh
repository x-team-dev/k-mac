#!/bin/bash
# k-mac — opinionated Mac setup for Korean users
# https://github.com/djohnkang/k-mac
# Usage: curl -fsSL djohnkang.github.io/setup.sh | bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

confirm() {
    read -rp "$1 (Y/n) " answer
    [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]
}

echo ""
echo "========================================="
echo "  Fresh Mac Bootstrap"
echo "========================================="
echo ""

# =========================================================
# Phase 1: macOS System Settings (no dependencies)
# =========================================================
echo "--- macOS 시스템 설정 ---"
echo ""

# 키보드
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain TISRomanSwitchState -bool false
info "키보드 설정 완료 (빠른 반복, 자동교정 끔, Caps Lock ABC 전환 끔)"

# 마우스
defaults write NSGlobalDomain com.apple.mouse.scaling -float 3.0
defaults write com.apple.AppleMultitouchMouse MouseButtonMode -string "TwoButton"
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string "TwoButton"
defaults write com.apple.AppleMultitouchMouse MouseOneFingerDoubleTapGesture -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseOneFingerDoubleTapGesture -int 1
info "마우스 설정 완료 (최고 속도, 보조 클릭, 스마트 줌)"

# Dock (기본 설정만 — 앱 정리는 Homebrew 설치 후 dockutil로 처리)
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true
info "Dock 기본 설정 완료 (크기, 최근 항목 끔, 최소화 방식)"

# Finder
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "glyv"
killall Finder 2>/dev/null || true
info "Finder 설정 완료 (Downloads, 경로막대, 상태막대, 갤러리 뷰)"

# 스크린샷
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
mkdir -p "${HOME}/Screenshots"
info "스크린샷 저장 위치: ~/Screenshots"

echo ""

# =========================================================
# Phase 2: Keyboard Remapping (sudo 필요)
# =========================================================
echo "--- 키보드 리매핑 (한/영 전환) ---"
echo ""

# hidutil 스크립트 생성 (Right Command → F18, Caps Lock → Ctrl)
sudo mkdir -p /Users/Shared/bin
sudo tee /Users/Shared/bin/userkeymapping > /dev/null << 'SCRIPT'
#!/bin/bash
hidutil property --set '{"UserKeyMapping":[
  {"HIDKeyboardModifierMappingSrc":0x7000000e7,"HIDKeyboardModifierMappingDst":0x70000006d},
  {"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000e0}
]}'
SCRIPT
sudo chmod 755 /Users/Shared/bin/userkeymapping

# LaunchAgent
sudo tee /Library/LaunchAgents/userkeymapping.plist > /dev/null << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>userkeymapping</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/Shared/bin/userkeymapping</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST

sudo launchctl bootout system /Library/LaunchAgents/userkeymapping.plist 2>/dev/null || true
sudo launchctl bootstrap system /Library/LaunchAgents/userkeymapping.plist
/Users/Shared/bin/userkeymapping > /dev/null 2>&1
info "키 리매핑 완료 (Right Cmd → F18, Caps Lock → Ctrl)"

# 61번 (입력 메뉴에서 다음 소스 선택) 비활성화 — Ctrl+Option+Space 충돌 방지
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 61 \
  "<dict><key>enabled</key><false/></dict>"

# 입력 소스 전환 단축키 → F18 (이전 입력 소스 선택 = 60번)
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 60 \
  "<dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key><array>
        <integer>65535</integer>
        <integer>79</integer>
        <integer>8388608</integer>
      </array>
    </dict>
  </dict>"

# 변경 즉시 반영
ACTIVATE="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
if [[ -x "$ACTIVATE" ]]; then
    "$ACTIVATE" -u
    info "입력 소스 단축키 → F18 완료"
else
    warn "activateSettings 없음 — 입력 소스 단축키를 수동 설정하세요"
    open "x-apple.systempreferences:com.apple.Keyboard"
    echo "  → 키보드 단축키 > 입력 소스 > F18 지정"
fi

echo ""

# =========================================================
# Phase 3: Homebrew
# =========================================================
echo "--- Homebrew ---"
echo ""

if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if command -v brew &>/dev/null; then
    info "Homebrew 이미 설치됨"
else
    echo "Homebrew 설치 중..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || fail "Homebrew 설치 실패"
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    info "Homebrew 설치 완료"
fi

echo ""

# =========================================================
# Phase 3.5: Dock 앱 정리 (dockutil — macOS 버전 무관하게 안정적)
# =========================================================
echo "--- Dock 앱 정리 ---"
echo ""

brew install dockutil 2>/dev/null || true

if command -v dockutil &>/dev/null; then
    dockutil --remove all --no-restart 2>/dev/null || true

    for app in \
        "/System/Applications/Messages.app" \
        "/System/Applications/Calendar.app"; do
        if [[ -d "$app" ]]; then
            dockutil --add "$app" --no-restart 2>/dev/null || true
        fi
    done

    # macOS 13+ 은 System Settings, 이전 버전은 System Preferences
    if [[ -d "/System/Applications/System Settings.app" ]]; then
        dockutil --add "/System/Applications/System Settings.app" --no-restart 2>/dev/null || true
    elif [[ -d "/System/Applications/System Preferences.app" ]]; then
        dockutil --add "/System/Applications/System Preferences.app" --no-restart 2>/dev/null || true
    fi

    killall Dock 2>/dev/null || true
    info "Dock 정리 완료 (Messages, Calendar, System Settings)"
else
    warn "dockutil 설치 실패 — Dock 앱을 수동으로 정리하세요"
fi

echo ""

# =========================================================
# Phase 4: 기본 앱 설치 (bundles)
# =========================================================
echo "--- 기본 앱 설치 ---"
echo ""

# 브라우저
if confirm "브라우저 설치? (Chrome)"; then
    brew install --cask google-chrome 2>/dev/null || true
    info "Chrome 설치 완료"
else
    warn "브라우저 설치 건너뜀"
fi

# 터미널
if confirm "터미널 설치? (iTerm2)"; then
    brew install --cask iterm2 2>/dev/null || true
    info "iTerm2 설치 완료"
else
    warn "터미널 설치 건너뜀"
fi

# 개발 도구
if confirm "개발 도구 설치? (GitHub CLI - gh)"; then
    brew install gh 2>/dev/null || true
    info "GitHub CLI (gh) 설치 완료"
else
    warn "GitHub CLI 설치 건너뜀"
fi

# 런처
if confirm "런처 설치? (Raycast)"; then
    brew install --cask raycast 2>/dev/null || true
    info "Raycast 설치 완료"
else
    warn "런처 설치 건너뜀"
fi

# AI 도구
if confirm "AI 도구 설치? (Claude, Claude Code, ChatGPT, Codex, Gemini CLI)"; then
    brew install --cask claude 2>/dev/null || true
    brew install --cask claude-code 2>/dev/null || true
    brew install --cask chatgpt 2>/dev/null || true
    brew install --cask codex 2>/dev/null || true
    brew install --cask codex-app 2>/dev/null || true
    brew install gemini-cli 2>/dev/null || true
    info "AI 도구 설치 완료"
else
    warn "AI 도구 설치 건너뜀"
fi

echo ""
echo "========================================="
echo "  Bootstrap 완료!"
echo "========================================="
echo ""
