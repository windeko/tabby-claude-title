#!/usr/bin/env bash
# Claude Code Stop / Notification hook entry — sets the Tabby tab title to
# "<emoji> <session-name|Claude>" and emits a BEL on the tab's PTY so Tabby's
# activity indicator lights up the right tab.
#
# Arg $1 — emoji (default 🟢). Reads Claude hook JSON from stdin.

set -euo pipefail

self_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=_lib.sh
. "$self_dir/_lib.sh"

emoji="${1:-🟢}"

read_claude_session_id
resolve_session_name "${session_id:-}"

label="$emoji $session_name"

# 1) write title file for tabby-claude-title plugin to pick up
if [ -n "${TABBY_TAB_ID:-}" ]; then
    resolve_titles_dir
    mkdir -p "$titles_dir" 2>/dev/null
    printf '%s' "$label" > "$titles_dir/$TABBY_TAB_ID.txt" 2>/dev/null
fi

# 2) walk up the process tree to find a controlling PTY and emit BEL there.
#    Lets Tabby light up the activity indicator on the originating tab even if
#    the user is currently focused on a different one.
pid=$$
while [ -n "$pid" ] && [ "$pid" != "1" ]; do
    fd1=$(readlink "/proc/$pid/fd/1" 2>/dev/null)
    if [[ "$fd1" == /dev/pts/* ]]; then
        printf '\a' >> "$fd1" 2>/dev/null && break
    fi
    pid=$(awk '/^PPid:/ {print $2}' "/proc/$pid/status" 2>/dev/null)
done

exit 0
