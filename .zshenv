# ============================================
# Secrets — macOS Keychain 에서 읽어 env 로 주입
# ============================================
# GitHub MCP 서버용 PAT (security add-generic-password -s github-mcp 로 저장)
export GITHUB_PERSONAL_ACCESS_TOKEN="$(security find-generic-password -s github-mcp -w 2>/dev/null)"
# Slack Bot Token (SEUL)
export SLACK_BOT_SEUL_TOKEN="$(security find-generic-password -s claude-slack-bot-seul-token -w 2>/dev/null)"
