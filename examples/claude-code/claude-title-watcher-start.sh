#!/usr/bin/env bash
# Claude Code SessionStart hook entry — reads the hook JSON, extracts
# session_id, and spawns claude-title-watcher.sh in the background so that
# `/rename` updates the tab title without waiting for the next prompt.

set -u

self_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=_lib.sh
. "$self_dir/_lib.sh"

[ -z "${TABBY_TAB_ID:-}" ] && exit 0

read_claude_session_id
[ -z "${session_id:-}" ] && exit 0

nohup "$self_dir/claude-title-watcher.sh" "$session_id" "$TABBY_TAB_ID" \
    </dev/null >/dev/null 2>&1 &
disown 2>/dev/null

exit 0
