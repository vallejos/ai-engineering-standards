#!/bin/sh
# Fails if Claude Code wiring leaks out of the .claude/ adapter. Everything outside
# .claude/ must read the same in Cursor, Copilot, Gemini CLI or Codex, so it may
# not mention MCP tool names, permissions, autoMode, hooks or settings.json.
# Claude-specific wiring belongs in claude-infra.
set -eu

pattern='mcp__|permissions|autoMode|hooks|settings\.json'

matches=$(git ls-files | grep -v -e '^\.claude/' -e '^\.claude-plugin/' -e '^\.github/' -e '^scripts/tool-name-lint\.sh$' \
    | xargs grep -n -E "$pattern" 2>/dev/null || true)

if [ -n "$matches" ]; then
    echo "Claude-specific wiring found outside the .claude/ adapter:" >&2
    echo "$matches" >&2
    echo "Move it into .claude/ or into claude-infra." >&2
    exit 1
fi
echo "tool-name lint passed"
