#!/bin/bash
# DotFiles setup.sh
# DotFiles 레포의 파일·디렉토리를 홈 디렉토리에 심링크로 배치
#
# 흐름: 충돌 시 백업 → 심링크 생성 → 결과 요약
# 멱등성: 이미 올바른 심링크면 건너뜀 (재실행 안전)
#
# 사용법:
#   ./setup.sh              # 실제 적용
#   ./setup.sh -n           # dry-run (변경 없이 시뮬레이션)
#   ./setup.sh -f           # 충돌 시 백업 없이 강제 덮어쓰기

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TS="$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
FORCE=0

usage() {
  cat <<EOF
사용법: $SCRIPT_NAME [옵션]

DotFiles 레포의 파일을 홈 디렉토리에 심링크로 배치합니다.

옵션:
  -n, --dry-run   실제 변경 없이 시뮬레이션
  -f, --force     충돌 시 백업 없이 강제 덮어쓰기
  -h, --help      이 도움말

대상:
  $DOTFILES_ROOT/claude/CLAUDE.md      → \$HOME/.claude/CLAUDE.md
  $DOTFILES_ROOT/claude/settings.json  → \$HOME/.claude/settings.json
  $DOTFILES_ROOT/claude/plugins        → \$HOME/.claude/plugins
  $DOTFILES_ROOT/local/bin/<각 실행파일> → \$HOME/.local/bin/<각 실행파일>

충돌 처리 (기본):
  1. 대상에 올바른 심링크 → 건너뜀 (재실행 안전)
  2. 대상이 다른 곳을 가리키는 심링크 / 일반 파일·디렉토리 →
     "<원래경로>.bak.$BACKUP_TS" 로 백업 후 새 심링크 생성
  3. 부모 디렉토리 없으면 자동 생성 (mkdir -p)
EOF
}

log()  { echo "[$SCRIPT_NAME] $*"; }
warn() { echo "[$SCRIPT_NAME] ⚠ $*" >&2; }
err()  { echo "[$SCRIPT_NAME] ✗ $*" >&2; }
ok()   { echo "[$SCRIPT_NAME] ✓ $*"; }

# 인자 파싱
while (( $# > 0 )); do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift ;;
    -f|--force)   FORCE=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) err "알 수 없는 옵션: $1"; usage; exit 2 ;;
  esac
done

# 매핑 정의
# 형식: "<DotFiles 상대경로>:<홈 절대경로>"
LINKS=(
  "claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
  "claude/settings.json:$HOME/.claude/settings.json"
  "claude/plugins:$HOME/.claude/plugins"
  "ghostty:$HOME/.config/ghostty"
)

# local/bin/* 자동 추가 (실행 가능한 파일만)
if [[ -d "$DOTFILES_ROOT/local/bin" ]]; then
  for entry in "$DOTFILES_ROOT/local/bin"/*; do
    [[ -e "$entry" ]] || continue
    name="$(basename "$entry")"
    LINKS+=("local/bin/$name:$HOME/.local/bin/$name")
  done
fi

# 카운터
COUNT_LINKED=0
COUNT_SKIPPED=0
COUNT_BACKED_UP=0
COUNT_FAILED=0
FAILED_LIST=()

# 단일 매핑 처리
process_link() {
  local rel="$1"
  local target="$2"
  local source="$DOTFILES_ROOT/$rel"

  # 소스 존재 확인
  if [[ ! -e "$source" ]]; then
    warn "[$rel] DotFiles에 소스 없음 — 건너뜀"
    (( ++COUNT_FAILED ))
    FAILED_LIST+=("$rel (소스 없음)")
    return
  fi

  # 부모 디렉토리 보장
  local parent
  parent="$(dirname "$target")"
  if [[ ! -d "$parent" ]]; then
    if (( DRY_RUN )); then
      log "[$rel] [dry-run] mkdir -p $parent"
    else
      mkdir -p "$parent"
      log "[$rel] 부모 디렉토리 생성: $parent"
    fi
  fi

  # 이미 올바른 심링크면 건너뜀 (멱등성)
  if [[ -L "$target" ]]; then
    local current
    current="$(readlink "$target")"
    if [[ "$current" == "$source" ]]; then
      log "[$rel] 이미 올바른 심링크 — 건너뜀"
      (( ++COUNT_SKIPPED ))
      return
    fi
  fi

  # 충돌 처리
  if [[ -e "$target" || -L "$target" ]]; then
    if (( FORCE )); then
      if (( DRY_RUN )); then
        log "[$rel] [dry-run] 강제 모드: $target 제거"
      else
        rm -rf "$target"
        log "[$rel] 강제 모드: 기존 항목 제거"
      fi
    else
      local backup="${target}.bak.${BACKUP_TS}"
      if (( DRY_RUN )); then
        log "[$rel] [dry-run] 백업: $target → $backup"
      else
        mv "$target" "$backup"
        log "[$rel] 백업: $(basename "$target") → $(basename "$backup")"
        (( ++COUNT_BACKED_UP ))
      fi
    fi
  fi

  # 심링크 생성
  if (( DRY_RUN )); then
    log "[$rel] [dry-run] ln -s $source $target"
  else
    if ln -s "$source" "$target"; then
      ok "[$rel] → $target"
      (( ++COUNT_LINKED ))
    else
      err "[$rel] 심링크 생성 실패"
      (( ++COUNT_FAILED ))
      FAILED_LIST+=("$rel (심링크 실패)")
    fi
  fi
}

# 사전 점검
if [[ "$(uname -s)" != "Darwin" && "$(uname -s)" != "Linux" ]]; then
  err "macOS 또는 Linux 전용"; exit 1
fi

log "DotFiles 루트: $DOTFILES_ROOT"
if (( DRY_RUN )); then
  log "*** DRY-RUN 모드 — 실제 변경 없음 ***"
fi
if (( FORCE )); then
  warn "강제 모드 — 충돌 항목은 백업 없이 제거됨"
fi
echo

# 매핑 처리
for mapping in "${LINKS[@]}"; do
  rel="${mapping%%:*}"
  target="${mapping#*:}"
  process_link "$rel" "$target"
done

# 요약
echo
echo "═══════════════════════════════════════"
log "결과 요약:"
log "  심링크 생성: $COUNT_LINKED"
log "  건너뜀(이미 정상): $COUNT_SKIPPED"
log "  백업: $COUNT_BACKED_UP"
log "  실패: $COUNT_FAILED"

if (( COUNT_FAILED > 0 )); then
  err "실패 항목:"
  for item in "${FAILED_LIST[@]}"; do
    err "  - $item"
  done
  exit 1
fi

ok "전체 완료"
