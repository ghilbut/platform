#!/usr/bin/env sh

set -eu

exec claude \
  --model claude-opus-4-8 \
  --effort xhigh \
  remote-control \
  --remote-control-session-name-prefix "ghilbut" \
  --permission-mode bypassPermissions \
  --spawn worktree \
  --capacity 4 \
  --no-create-session-in-dir
