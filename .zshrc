# Fastfetch (인터랙티브 셸에서만)
if [[ $- == *i* ]] && command -v fastfetch &>/dev/null; then
  fastfetch
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# Starship 프롬프트
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

# 명령어 구문 강조
zinit light zdharma-continuum/fast-syntax-highlighting
# 히스토리 기반 자동 완성
zinit light zsh-users/zsh-autosuggestions
# 추가 자동 완성 정의
zinit light zsh-users/zsh-completions
# Autojump
zinit snippet /opt/homebrew/share/autojump/autojump.zsh

# ============================================
# SCM Breeze (Git 단축키)
# ============================================
# if [[ -z "$CLAUDECODE" ]]; then
#   [ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"
# fi

# ============================================
# 모던 CLI 별칭
# ============================================
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
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."

# ============================================
# fzf + zoxide + navi
# ============================================
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init --cmd cd zsh)"
fi

if command -v navi &>/dev/null; then
  eval "$(navi widget zsh)"
fi

# ============================================
# mise (런타임 버전 관리자)
# ============================================
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

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



##### Alias #####
alias python=python3
alias macscreen='open vnc://miller-macmini.taila343d9.ts.net'
export PATH="$HOME/.local/bin:$PATH"
