#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
set -euo pipefail

SESSIONS_DIR="${HOME}/.config/kitty/sessions"
mkdir -p "$SESSIONS_DIR"

ls_json=$(kitten @ ls 2>/dev/null)
[ -z "$ls_json" ] && ls_json='[]'

orig_layout=$(printf '%s' "$ls_json" | jq -r '
  [.[] | select(.is_focused == true) | .tabs[] | select(.is_focused == true) | .layout][0] // empty')

restored=0
restore_layout() {
  [ "$restored" = 1 ] && return
  restored=1
  if [ -n "$orig_layout" ] && [ "$orig_layout" != "stack" ]; then
    kitten @ action goto_layout "$orig_layout" 2>/dev/null || true
  fi
}
trap restore_layout EXIT

current=$(printf '%s' "$ls_json" | jq -r '
  [ .[]  | select(.is_focused == true)
    | .tabs[] | select(.is_focused == true)
    | .windows[]
    | select(.session_name != null and .session_name != "")
    | .session_name ][0] // empty')

if [ -n "$current" ]; then
  path="${SESSIONS_DIR}/${current}.kitty-session"
  if [ -f "$path" ]; then
    kitten @ action "save_as_session --save-only --match='state:focused_os_window and session:. and not var:skip_save=1' \"$path\""
    exit 0
  fi
fi

if [ -n "$orig_layout" ] && [ "$orig_layout" != "stack" ]; then
  kitten @ action goto_layout stack 2>/dev/null || true
fi

printf 'session name: '
read -r name

restore_layout

[ -z "$name" ] && exit 0

name="${name%.kitty-session}"
name="${name%.kitty_session}"
name="${name%.session}"

path="${SESSIONS_DIR}/${name}.kitty-session"
kitten @ action "save_as_session --save-only --match='state:focused_os_window and not var:skip_save=1' \"$path\""
