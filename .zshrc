# ============================================
# 인터랙티브 셸 전용
# ============================================
if [[ $- == *i* ]] && command -v fastfetch &>/dev/null; then
  fastfetch
fi

# ============================================
# Oh My Zsh + Starship 프롬프트
# ============================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# ============================================
# Zinit 플러그인 매니저
# ============================================
if [[ ! -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
  command mkdir -p "$HOME/.local/share/zinit"
  command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light zdharma-continuum/fast-syntax-highlighting   # 명령어 구문 강조
zinit light zsh-users/zsh-autosuggestions                # 히스토리 기반 자동 완성
zinit light zsh-users/zsh-completions                    # 추가 자동 완성 정의
zinit snippet /opt/homebrew/share/autojump/autojump.zsh  # Autojump

# ============================================
# 환경 변수 / PATH
# ============================================
export PATH="$HOME/.local/bin:$PATH"
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

# ============================================
# 별칭
# ============================================
# 모던 CLI 대체
alias ls="lsd"
alias ll="lsd -la"
alias lt="lsd --tree"
alias cat="bat"
alias find="fd"
alias grep="rg"
alias top="btop"
alias df="duf"
alias du="dust"
alias vim="nvim"
alias vi="nvim"
alias lg="lazygit"

# 단축키
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."
alias python=python3
alias screen_miller_macmini='open vnc://100.96.120.47'
alias yolo='claude --dangerously-skip-permissions'

# ============================================
# 도구 런처
# ============================================
function tools() {
  local cmds=(
    "btop:🖥️  시스템 모니터링"
    "lazygit:📦 Git UI"
    "duf:💾 디스크 사용량"
    "dust:📁 폴더 크기 분석"
    "fastfetch:ℹ️  시스템 정보"
  )
  local selected=$(printf '%s\n' "${cmds[@]}" | fzf --delimiter=: --with-nth=2 --height=40% --reverse --border --prompt="도구 선택: ")
  local cmd="${selected%%:*}"
  [[ -n "$cmd" ]] && eval "$cmd"
}

# ============================================
# 런타임 버전 관리자 / CLI 보조
# ============================================
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

if command -v navi &>/dev/null; then
  eval "$(navi widget zsh)"
fi

# ============================================
# Secrets — macOS Keychain 에서 읽어 env 로 주입
# ============================================
# GitHub MCP 서버용 PAT (security add-generic-password -s github-mcp 로 저장)
export GITHUB_PERSONAL_ACCESS_TOKEN="$(security find-generic-password -s github-mcp -w 2>/dev/null)"
# Slack Bot Token (SEUL)
export SLACK_BOT_SEUL_TOKEN="$(security find-generic-password -s claude-slack-bot-seul-token -w 2>/dev/null)"

[ -r ~/.config/secrets/tokens.env ] && source ~/.config/secrets/tokens.env


# ============================================
# NAS 마운트 (rclone NFS)
#   mountnas        → 외부 IP + Tailscale 둘 다
#   mountnas ip     → 외부 IP 만 (~/mnt/MillerNAS)
#   mountnas ts     → Tailscale 만 (~/mnt/MillerNAS-ts)
#   umountnas [ip|ts|all]  → 동일 인자 규칙으로 해제
# ============================================
mountnas() {
  local target="${1:-all}"
  if [[ "$target" != "ip" && "$target" != "ts" && "$target" != "all" ]]; then
    echo "사용법: mountnas [ip|ts|all]  (기본 all)"
    return 1
  fi
  mkdir -p ~/mnt/MillerNAS ~/mnt/MillerNAS-ts
  if [[ "$target" == "ip" || "$target" == "all" ]]; then
    rclone nfsmount MillerNAS:/ ~/mnt/MillerNAS \
      --vfs-cache-mode full --addr 127.0.0.1:12000 --daemon \
      && echo "[OK] MillerNAS (외부 IP) 마운트"
  fi
  if [[ "$target" == "ts" || "$target" == "all" ]]; then
    rclone nfsmount MillerNAS-ts:/ ~/mnt/MillerNAS-ts \
      --vfs-cache-mode full --addr 127.0.0.1:12001 --daemon \
      && echo "[OK] MillerNAS-ts (Tailscale) 마운트"
  fi
}

umountnas() {
  local target="${1:-all}"
  if [[ "$target" != "ip" && "$target" != "ts" && "$target" != "all" ]]; then
    echo "사용법: umountnas [ip|ts|all]  (기본 all)"
    return 1
  fi
  if [[ "$target" == "ip" || "$target" == "all" ]]; then
    diskutil unmount force ~/mnt/MillerNAS 2>/dev/null
    pkill -f "rclone nfsmount MillerNAS:/" 2>/dev/null
    echo "[STOP] MillerNAS (외부 IP) 해제"
  fi
  if [[ "$target" == "ts" || "$target" == "all" ]]; then
    diskutil unmount force ~/mnt/MillerNAS-ts 2>/dev/null
    pkill -f "rclone nfsmount MillerNAS-ts:/" 2>/dev/null
    echo "[STOP] MillerNAS-ts (Tailscale) 해제"
  fi
}


# ============================================
# zoxide — 반드시 파일 끝 (경고 방지)
# ============================================
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init --cmd cd zsh)"
fi
