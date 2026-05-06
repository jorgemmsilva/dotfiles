#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
set -uo pipefail

KITTY_SOCKET="${KITTY_LISTEN_ON:-unix:/tmp/mykitty}"
LOCK_DIR="${HOME}/.cache/kitty"
mkdir -p "$LOCK_DIR"
LOCK_FILE="$LOCK_DIR/session-switcher.lock"

if [ -f "$LOCK_FILE" ]; then
  read -r old_pid old_win_id < "$LOCK_FILE"
  if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
    if ps -p "$old_pid" -o args= | grep -q "session-switcher"; then
      if [ -n "$old_win_id" ]; then
        kitten @ --to "$KITTY_SOCKET" send-text --match "id:${old_win_id}" $'\x1b[B' 2>/dev/null || true
      else
        kitten @ --to "$KITTY_SOCKET" send-text $'\x1b[B' 2>/dev/null || true
      fi
      exit 0
    fi
  fi
  rm -f "$LOCK_FILE"
fi

# NOTE: IS_NVIM is an hack to allow ctrl+j/k to work on the fzf picker
kitten @ --to "$KITTY_SOCKET" launch --type=overlay --var=skip_save=1 --var=IS_NVIM=1 --allow-remote-control ~/.config/kitty/session-switcher.sh
