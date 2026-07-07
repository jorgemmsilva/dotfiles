#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
set -uo pipefail

SESSIONS_DIR="${HOME}/.config/kitty/sessions"
mkdir -p "$SESSIONS_DIR"
SELF="${HOME}/.config/kitty/session-switcher.sh"

# Build the fzf list as "<colored-marker>\t<name>". Active sessions get a
# green dot, saved-but-closed ones a dim circle. Reads $active/$current from the
# environment so it can be re-invoked via `--list` for fzf's reload binding.
build_list() {
  local known
  known=$(
    for f in "$SESSIONS_DIR"/*.kitty-session "$SESSIONS_DIR"/*.kitty_session "$SESSIONS_DIR"/*.session; do
      [ -f "$f" ] || continue
      local n="${f##*/}"; n="${n%.*}"
      printf '%s\n' "$n"
    done
  )
  printf '%s\n%s\n' "${active:-}" "$known" \
    | awk 'NF && !seen[$0]++' \
    | grep -vxF "${current:-}" 2>/dev/null \
    | { if [ -n "${EXCLUDE_FILE:-}" ] && [ -s "$EXCLUDE_FILE" ]; then \
          grep -vxF -f "$EXCLUDE_FILE"; else cat; fi; } \
    | while IFS= read -r n; do
        if printf '%s\n' "${active:-}" | grep -qxF "$n"; then
          printf '\033[32m\xe2\x97\x8f\033[0m %s\n' "$n"
        else
          printf '\033[90m\xe2\x97\x8b\033[0m %s\n' "$n"
        fi
      done
}

# Re-entrant list mode used by fzf's reload() binding. When a name is passed,
# delete that session's file(s) first, then print the refreshed list. Doing the
# delete + relist in a single reload command avoids fzf action-chaining quirks.
if [ "${1:-}" = "--list" ]; then
  d="${2:-}"
  if [ -n "$d" ]; then
    rm -f "$SESSIONS_DIR/$d.kitty-session" \
          "$SESSIONS_DIR/$d.kitty_session" \
          "$SESSIONS_DIR/$d.session" 2>/dev/null || true
    # Remember the deletion so it stays out of the list even if the session is
    # still open (active). Persists across reloads within this switcher run.
    [ -n "${EXCLUDE_FILE:-}" ] && printf '%s\n' "$d" >> "$EXCLUDE_FILE"
  fi
  build_list
  exit 0
fi

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

# Fetch the kitty state once; everything below is derived from this.
ls_json=$(kitten @ ls 2>/dev/null)
[ -z "$ls_json" ] && ls_json='[]'

# Single jq pass: focused window id, focused layout, current session name,
# and the active sessions sorted by most-recently-focused.
meta=$(printf '%s' "$ls_json" | jq -c '
  [.[] | select(.is_focused == true)] as $focused_os
  | {
      win_id: ([$focused_os[].tabs[] | select(.is_focused == true)
                 | .windows[] | select(.is_focused == true) | .id][0] // null),
      layout: ([$focused_os[].tabs[] | select(.is_focused == true) | .layout][0] // null),
      current: ([$focused_os[].tabs[] | select(.is_focused == true)
                  | .windows[]
                  | select(.session_name != null and .session_name != "")
                  | .session_name][0] // null),
      active: ([ .[].tabs[].windows[]
                 | select(.session_name != null and .session_name != "")
                 | {name: .session_name, t: (.last_focused_at // 0)} ]
               | group_by(.name)
               | map({name: .[0].name, t: (map(.t) | max)})
               | sort_by(-.t)
               | map(.name))
    }')

win_id="${KITTY_WINDOW_ID:-}"
[ -z "$win_id" ] && win_id=$(printf '%s' "$meta" | jq -r '.win_id // empty')
printf '%s %s\n' $$ "$win_id" > "$LOCK_FILE"

orig_layout=$(printf '%s' "$meta" | jq -r '.layout // empty')

# Tracks sessions deleted during this run so they stay hidden even while still
# open (active). build_list and the --list reload filter against it.
EXCLUDE_FILE=$(mktemp "${LOCK_DIR}/session-switcher.exclude.XXXXXX")

restored=0
restore_layout() {
  [ "$restored" = 1 ] && return
  restored=1
  rm -f "$LOCK_FILE" "$EXCLUDE_FILE"
  if [ -n "$orig_layout" ] && [ "$orig_layout" != "stack" ]; then
    kitten @ action goto_layout "$orig_layout" 2>/dev/null || true
  fi
}
trap restore_layout EXIT

if [ -n "$orig_layout" ] && [ "$orig_layout" != "stack" ]; then
  kitten @ action goto_layout stack 2>/dev/null || true
fi

active=$(printf '%s' "$meta" | jq -r '.active[]?')
current=$(printf '%s' "$meta" | jq -r '.current // empty')
[ -z "$current" ] && current=$(printf '%s\n' "$active" | sed -n '1p')

# Export what build_list needs so fzf's reload() (which re-runs "$SELF --list"
# in a fresh shell) sees the same active/current set. Deletes don't change the
# running sessions, so these stay valid across reloads.
export SESSIONS_DIR active current EXCLUDE_FILE

term_lines=$(tput lines 2>/dev/null || echo 24)
fzf_height=$(( term_lines * 30 / 100 ))
[ "$fzf_height" -lt 8 ] && fzf_height=8

top_margin=$(( (term_lines - fzf_height) / 2 ))
bottom_margin=$(( term_lines - fzf_height - top_margin ))

# ctrl-x deletes the highlighted session's file(s) ({2} = name field) then
# reloads the list in place.
selection=$(build_list | fzf \
    --ansi \
    --delimiter=' ' \
    --with-nth=1,2 \
    --cycle \
    --print-query \
    --prompt='session: ' \
    --header='ctrl-x: delete  enter: switch' \
    --margin="${top_margin},0,${bottom_margin},0" \
    --layout=reverse \
    --border=rounded \
    --border-label=' sessions ' \
    --color='border:#585b70,label:#cdd6f4' \
    --bind 'ctrl-j:down,ctrl-k:up' \
    --bind 'ctrl-x:reload("'"$SELF"'" --list {2})')

query=$(printf '%s' "$selection" | sed -n '1p')
match=$(printf '%s' "$selection" | sed -n '2p' | cut -d' ' -f2)
name="${match:-$query}"

restore_layout

[ -z "$name" ] && exit 0

path="${SESSIONS_DIR}/${name}.kitty-session"
[ -f "$path" ] || printf 'new_os_window\nlaunch\n' > "$path"

kitten @ action goto_session "$path"
