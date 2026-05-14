#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook entry — updates the Tabby tab title only,
# no BEL. Lets the tab show a "thinking" emoji + the current /rename'd session
# name on every user prompt.
#
# Arg $1 — emoji (default 🔵). Reads Claude hook JSON from stdin.

set -u

self_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=_lib.sh
. "$self_dir/_lib.sh"

emoji="${1:-🔵}"

[ -z "${TABBY_TAB_ID:-}" ] && exit 0

read_claude_session_id
resolve_session_name "${session_id:-}"

label="$emoji $session_name"

resolve_titles_dir
mkdir -p "$titles_dir" 2>/dev/null
printf '%s' "$label" > "$titles_dir/$TABBY_TAB_ID.txt" 2>/dev/null

exit 0
