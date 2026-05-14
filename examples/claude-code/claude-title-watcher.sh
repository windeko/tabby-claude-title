#!/usr/bin/env bash
# Daemon — polls ~/.claude/sessions/<pid>.json for `name` field changes and
# pushes them to the tabby-claude-title plugin's title file. This lets
# `/rename` reflect in the tab title immediately (without waiting for the
# next prompt to fire a hook).
#
# Args: $1 session_id   $2 TABBY_TAB_ID
# Spawned in the background by SessionStart hook (claude-title-watcher-start.sh).
# Exits when the matching session JSON disappears (session ended).

set -u

self_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=_lib.sh
. "$self_dir/_lib.sh"

session_id="${1:-}"
tab_id="${2:-}"
[ -z "$session_id" ] || [ -z "$tab_id" ] && exit 0

resolve_titles_dir
mkdir -p "$titles_dir" 2>/dev/null
title_file="$titles_dir/$tab_id.txt"

# Single-instance per session — avoid duplicates if SessionStart fires twice.
pidfile="/tmp/claude-title-watcher.${session_id}.pid"
if [ -f "$pidfile" ]; then
    old=$(cat "$pidfile" 2>/dev/null)
    if [ -n "$old" ] && kill -0 "$old" 2>/dev/null; then
        exit 0
    fi
fi
echo $$ > "$pidfile"
trap 'rm -f "$pidfile"' EXIT

last_label=""
miss_count=0

while :; do
    name=""
    src=""
    for f in "$HOME/.claude/sessions"/*.json; do
        [ -f "$f" ] || continue
        if grep -q "\"sessionId\":\"$session_id\"" "$f" 2>/dev/null; then
            src="$f"
            if command -v jq >/dev/null 2>&1; then
                name=$(jq -r '.name // empty' "$f" 2>/dev/null)
            fi
            break
        fi
    done

    if [ -z "$src" ]; then
        miss_count=$((miss_count + 1))
        if [ "$miss_count" -ge 5 ]; then
            exit 0
        fi
        sleep 1
        continue
    fi
    miss_count=0

    [ -z "$name" ] && name="Claude"

    current=$(cat "$title_file" 2>/dev/null || true)
    emoji="${current%% *}"
    case "$emoji" in
        🟢|🟡|🔵|🟠|🔴|⚪|⚫) : ;;
        *) emoji="🔵" ;;
    esac

    label="$emoji $name"
    if [ "$label" != "$last_label" ] && [ "$label" != "$current" ]; then
        printf '%s' "$label" > "$title_file"
        last_label="$label"
    fi

    sleep 1
done
