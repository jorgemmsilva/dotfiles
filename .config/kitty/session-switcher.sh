#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
set -uo pipefail

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

if [ -n "$orig_layout" ] && [ "$orig_layout" != "stack" ]; then
  kitten @ action goto_layout stack 2>/dev/null || true
fi

active=$(printf '%s' "$ls_json" | jq -r '
  [ .[].tabs[].windows[]
    | select(.session_name != null and .session_name != "")
    | {name: .session_name, t: (.last_focused_at // 0)} ]
  | group_by(.name)
  | map({name: .[0].name, t: (map(.t) | max)})
  | sort_by(-.t)
  | .[].name
')

current=$(printf '%s\n' "$active" | sed -n '1p')

known=$(find "$SESSIONS_DIR" -maxdepth 1 -type f \
  \( -name '*.kitty-session' -o -name '*.kitty_session' -o -name '*.session' \) \
  -exec basename {} \; 2>/dev/null | sed -E 's/\.(kitty-session|kitty_session|session)$//')

list=$(printf '%s\n%s\n' "$active" "$known" | awk 'NF && !seen[$0]++')
if [ -n "$current" ]; then
  list=$(printf '%s\n' "$list" | grep -vxF "$current" || true)
fi

selection=$(printf '%s\n' "$list" | fzf \
    --print-query \
    --prompt='session: ' \
    --height=30% \
    --border=rounded \
    --border-label=' sessions ' \
    --color='border:#585b70,label:#cdd6f4' \
    --expect=enter)

query=$(printf '%s' "$selection" | sed -n '1p')
match=$(printf '%s' "$selection" | sed -n '3p')
name="${match:-$query}"

restore_layout

[ -z "$name" ] && exit 0

path="${SESSIONS_DIR}/${name}.kitty-session"
[ -f "$path" ] || printf 'new_os_window\nlaunch\n' > "$path"

kitten @ action goto_session "$path"
