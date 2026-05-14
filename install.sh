#!/usr/bin/env bash
# Installer for tabby-claude-title.
#
# - Builds the plugin (if dist/ is missing) and copies it to Tabby's plugins
#   directory so the next Tabby launch picks it up.
# - Optionally installs the Claude Code integration scripts and merges the
#   hooks into ~/.claude/settings.json (jq, falling back to node, falling back
#   to printing a snippet).
#
# Usage:
#   ./install.sh             # plugin only
#   ./install.sh --claude    # plugin + Claude Code integration
#   ./install.sh --uninstall # remove the plugin (does not touch ~/.claude)

set -euo pipefail

cmd="${1:-}"
src_root="$(cd "$(dirname "$0")" && pwd)"

# ---------- platform helpers ----------
is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

resolve_appdata_wsl() {
    local win
    win=$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r\n')
    [ -z "$win" ] && return 1
    wslpath -u "$win"
}

tabby_plugins_dir() {
    if is_wsl; then
        echo "$(resolve_appdata_wsl)/tabby/plugins/node_modules"
        return
    fi
    case "$(uname)" in
        Darwin)
            echo "$HOME/Library/Application Support/tabby/plugins/node_modules" ;;
        Linux|*)
            echo "${XDG_CONFIG_HOME:-$HOME/.config}/tabby/plugins/node_modules" ;;
    esac
}

# ---------- core actions ----------
build_if_missing() {
    if [ ! -f "$src_root/dist/index.js" ]; then
        echo "==> Building plugin"
        ( cd "$src_root" && npm install --legacy-peer-deps && npm run build )
    fi
}

install_plugin() {
    build_if_missing
    local target
    target="$(tabby_plugins_dir)/tabby-claude-title"
    mkdir -p "$target/dist"
    cp "$src_root/dist/index.js" "$target/dist/"
    [ -f "$src_root/dist/index.js.map" ] && cp "$src_root/dist/index.js.map" "$target/dist/"
    cp "$src_root/package.json" "$target/"
    echo "==> Plugin installed: $target"
    echo "    Restart Tabby for it to load."
}

uninstall_plugin() {
    local target
    target="$(tabby_plugins_dir)/tabby-claude-title"
    if [ -d "$target" ]; then
        rm -rf "$target"
        echo "==> Removed $target"
    else
        echo "Plugin not found at $target"
    fi
}

# ---------- settings.json merge ----------

# Merge the snippet into ~/.claude/settings.json, preserving any existing
# hooks the user already has. Tries jq → node → printing a snippet.
merge_claude_settings() {
    local bin="$1"
    local settings="$HOME/.claude/settings.json"
    local snippet="$src_root/examples/claude-code/settings.json.snippet"

    # Materialise the snippet with the real install dir substituted in.
    local snippet_resolved
    snippet_resolved=$(sed "s|<INSTALL_DIR>|$bin|g" "$snippet")

    mkdir -p "$(dirname "$settings")"
    if [ ! -f "$settings" ]; then
        echo '{}' > "$settings"
    fi

    if command -v jq >/dev/null 2>&1; then
        echo "==> Merging hooks into $settings (jq)"
        local tmp
        tmp=$(mktemp)
        printf '%s' "$snippet_resolved" > "$tmp.add"
        jq -s '
            .[0] as $orig
            | .[1] as $add
            | $orig
            | .hooks = ((.hooks // {}) as $cur
                       | $add.hooks
                       | reduce keys[] as $k
                           ($cur; .[$k] = (($cur[$k] // []) + $add[$k])))
        ' "$settings" "$tmp.add" > "$tmp"
        mv "$tmp" "$settings"
        rm -f "$tmp.add"
        return 0
    fi

    if command -v node >/dev/null 2>&1; then
        echo "==> Merging hooks into $settings (node)"
        SNIPPET="$snippet_resolved" SETTINGS="$settings" node - <<'NODE'
const fs = require('fs');
const path = process.env.SETTINGS;
const snippet = JSON.parse(process.env.SNIPPET);
const orig = JSON.parse(fs.readFileSync(path, 'utf8') || '{}');
orig.hooks = orig.hooks || {};
for (const [event, blocks] of Object.entries(snippet.hooks || {})) {
    orig.hooks[event] = (orig.hooks[event] || []).concat(blocks);
}
fs.writeFileSync(path, JSON.stringify(orig, null, 2) + '\n');
NODE
        return 0
    fi

    echo "==> Could not auto-merge ~/.claude/settings.json (no jq, no node)."
    echo "    Add this manually under the 'hooks' block:"
    echo
    printf '%s\n' "$snippet_resolved"
    echo
    return 1
}

install_claude_integration() {
    local bin="$HOME/.local/bin"
    mkdir -p "$bin"
    for f in _lib.sh claude-notify.sh claude-set-title.sh claude-title-watcher.sh claude-title-watcher-start.sh; do
        cp "$src_root/examples/claude-code/$f" "$bin/"
        chmod +x "$bin/$f"
    done
    echo "==> Claude scripts installed to $bin"
    merge_claude_settings "$bin"
}

# ---------- main ----------
case "$cmd" in
    --uninstall)
        uninstall_plugin ;;
    --claude)
        install_plugin
        echo
        install_claude_integration ;;
    "")
        install_plugin ;;
    *)
        echo "Usage: $0 [--claude|--uninstall]" >&2
        exit 2 ;;
esac
