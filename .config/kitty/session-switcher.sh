#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
set -uo pipefail

SESSIONS_DIR="${HOME}/.config/kitty/sessions"
mkdir -p "$SESSIONS_DIR"

LOCK_DIR="${HOME}/.cache/kitty"
mkdir -p "$LOCK_DIR"
LOCK_FILE="$LOCK_DIR/session-switcher.lock"

if [ -f "$LOCK_FILE" ]; then
  read -r old_pid old_win_id < "$LOCK_FILE"
  if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
    if ps -p "$old_pid" -o args= | grep -q "session-switcher"; then
      if [ -n "$old_win_id" ]; then
        kitten @ send-text --match "id:${old_win_id}" $'\x1b[B' 2>/dev/null || true
      else
        kitten @ send-text $'\x1b[B' 2>/dev/null || true
      fi
      exit 0
    fi
  fi
  rm -f "$LOCK_FILE"
fi

win_id="${KITTY_WINDOW_ID:-}"
if [ -z "$win_id" ]; then
  win_id=$(kitten @ ls 2>/dev/null | jq -r '[.[].tabs[].windows[] | select(.is_focused == true) | .id][0] // empty')
fi
printf '%s %s\n' $$ "$win_id" > "$LOCK_FILE"

ls_json=$(kitten @ ls 2>/dev/null)
[ -z "$ls_json" ] && ls_json='[]'

orig_layout=$(printf '%s' "$ls_json" | jq -r '
  [.[] | select(.is_focused == true) | .tabs[] | select(.is_focused == true) | .layout][0] // empty')

restored=0
restore_layout() {
  [ "$restored" = 1 ] && return
  restored=1
  rm -f "$LOCK_FILE"
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

term_lines=$(tput lines 2>/dev/null || echo 24)
fzf_height=$(( term_lines * 30 / 100 ))
[ "$fzf_height" -lt 8 ] && fzf_height=8

top_margin=$(( (term_lines - fzf_height) / 2 ))
bottom_margin=$(( term_lines - fzf_height - top_margin ))

selection=$(printf '%s\n' "$list" | fzf \
    --cycle \
    --print-query \
    --prompt='session: ' \
    --margin="${top_margin},0,${bottom_margin},0" \
    --layout=reverse \
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
