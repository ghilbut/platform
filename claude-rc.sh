#!/usr/bin/env sh

set -eu

export ANTHROPIC_MODEL=claude-opus-4-8
export CLAUDE_CODE_EFFORT_LEVEL=xhigh

exec claude \
  remote-control \
  --remote-control-session-name-prefix "ghilbut" \
  --permission-mode bypassPermissions \
  --spawn worktree \
  --capacity 4 \
  --no-create-session-in-dir
