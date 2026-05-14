# shellcheck shell=bash
# Shared helpers for tabby-claude-title example scripts.
# Sourced, not executed.

# Resolve the tabby-claude-title titles directory for the current host.
# Mirrors src/service.ts:defaultTitlesDir().
#
# Sets `titles_dir` (global). Returns 0 on success.
resolve_titles_dir() {
    # shellcheck disable=SC2034  # `titles_dir` is consumed by callers
    # WSL2 → query Windows for %APPDATA% then convert.
    if grep -qi microsoft /proc/version 2>/dev/null && command -v wslpath >/dev/null 2>&1; then
        local win
        win=$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r\n')
        if [ -n "$win" ]; then
            titles_dir="$(wslpath -u "$win")/tabby/claude-titles"
            return 0
        fi
    fi
    # macOS
    if [ "$(uname)" = "Darwin" ]; then
        titles_dir="$HOME/Library/Application Support/tabby/claude-titles"
        return 0
    fi
    # Linux & other Unix
    titles_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tabby/claude-titles"
    return 0
}

# Read Claude hook stdin (JSON) and extract session_id.
# Sets `session_id`. Tolerates missing stdin / missing jq.
read_claude_session_id() {
    # shellcheck disable=SC2034  # `session_id` is consumed by callers
    session_id=""
    if [ -t 0 ]; then
        return
    fi
    local payload
    payload=$(cat 2>/dev/null)
    [ -z "$payload" ] && return
    if command -v jq >/dev/null 2>&1; then
        session_id=$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null)
    fi
}

# Look up the user-supplied session name (set by /rename) for a given session_id.
# Sets `session_name`. Defaults to "Claude" if not found.
resolve_session_name() {
    local sid="$1"
    # shellcheck disable=SC2034  # `session_name` is consumed by callers
    session_name=""
    if [ -n "$sid" ] && command -v jq >/dev/null 2>&1; then
        local f
        for f in "$HOME/.claude/sessions"/*.json; do
            [ -f "$f" ] || continue
            if grep -q "\"sessionId\":\"$sid\"" "$f" 2>/dev/null; then
                session_name=$(jq -r '.name // empty' "$f" 2>/dev/null)
                break
            fi
        done
    fi
    [ -z "$session_name" ] && session_name="Claude"
}
