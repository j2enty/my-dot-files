#!/bin/bash
# Claude Code 상태줄 — 이모지 스타일
# 📁 디렉토리  🌿 브랜치  🤖 모델  👤 Max(...)  🧠 컨텍스트%  🧑🏻‍💻 실행중/누적  ⚙️ v버전

input=$(cat)

dir=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
version=$(echo "$input" | jq -r '.version')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

branch=$(cd "$dir" 2>/dev/null && git -c core.fileMode=false -c advice.detachedHead=false rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no git')

case "$model" in
  *'Claude 3.5 Sonnet'*) short_model='Sonnet 3.5' ;;
  *'Claude 3.5 Haiku'*)  short_model='Haiku 3.5' ;;
  *'Sonnet 4.5'*|*'claude-sonnet-4-5'*) short_model='Sonnet 4.5' ;;
  *'Opus 4.5'*|*'claude-opus-4-5'*)     short_model='Opus 4.5' ;;
  *'Haiku 4.5'*|*'claude-haiku-4-5'*)   short_model='Haiku 4.5' ;;
  *'Sonnet 4.6'*|*'claude-sonnet-4-6'*) short_model='Sonnet 4.6' ;;
  *'Opus 4.6'*|*'claude-opus-4-6'*)     short_model='Opus 4.6' ;;
  *'Sonnet 4.7'*|*'claude-sonnet-4-7'*) short_model='Sonnet 4.7' ;;
  *'Opus 4.7'*|*'claude-opus-4-7'*)     short_model='Opus 4.7' ;;
  *) short_model="$model" ;;
esac

# Max 플랜 사용량
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
plan_info=""
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  plan_info="Max("
  [ -n "$five_pct" ] && plan_info="${plan_info}5h:$(printf '%.0f' "$five_pct")%"
  [ -n "$five_pct" ] && [ -n "$week_pct" ] && plan_info="${plan_info} "
  [ -n "$week_pct" ] && plan_info="${plan_info}7d:$(printf '%.0f' "$week_pct")%"
  plan_info="${plan_info})"
else
  plan_info="Max"
fi

# 에이전트 카운트 — 실행 중(Agent/Task uses - results) / 세션 누적(uses 전체)
agent_count=0
agent_total=0
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  # 마지막 4MB만 파싱(성능). 파일이 4MB를 넘으면 첫 줄이 잘렸을 수 있어 버림
  file_size=$(wc -c <"$transcript_path" 2>/dev/null | tr -d ' ')
  if [ -n "$file_size" ] && [ "$file_size" -gt 4194304 ]; then
    tail_cmd="tail -c 4194304 \"$transcript_path\" | sed '1d'"
  else
    tail_cmd="cat \"$transcript_path\""
  fi
  counts=$(eval "$tail_cmd" 2>/dev/null | jq -rs '
    reduce .[] as $e (
      {uses: [], results: []};
      if $e.type == "assistant" then
        .uses += [$e.message.content[]? | select(.type == "tool_use" and (.name == "Agent" or .name == "Task")) | .id]
      elif $e.type == "user" then
        .results += [$e.message.content[]? | select(.type == "tool_result") | .tool_use_id]
      else .
      end
    )
    | "\((.uses - .results) | length) \(.uses | length)"
  ' 2>/dev/null)
  if [ -n "$counts" ]; then
    agent_count=$(echo "$counts" | awk '{print $1}')
    agent_total=$(echo "$counts" | awk '{print $2}')
  fi
fi

agent_info="  🧑🏻‍💻 ${agent_count}/${agent_total}"

# 컨텍스트 사용률 (세션 시작부터 현재까지 컨텍스트 윈도우 소진 비율)
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$ctx_pct" ]; then
  ctx_info="  🧠 $(printf '%.0f' "$ctx_pct")%"
else
  ctx_info="  🧠 -"
fi

printf '📁 %s  🌿 %s  🤖 %s  👤 %s%s%s  ⚙️ v%s' \
  "$(basename "$dir")" "$branch" "$short_model" "$plan_info" "$ctx_info" "$agent_info" "$version"
