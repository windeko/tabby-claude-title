#!/usr/bin/env bash
# Installer for tabby-claude-title.
#
# - Builds the plugin (if dist/ is missing) and copies it to Tabby's plugins
#   directory so the next Tabby launch picks it up.
# - Optionally installs the Claude Code integration scripts and prints the
#   settings.json snippet you need to merge into ~/.claude/settings.json.
#
# Usage:
#   ./install.sh             # plugin only
#   ./install.sh --claude    # plugin + Claude Code hook scripts
#   ./install.sh --uninstall # remove the plugin (does not touch ~/.claude)

set -euo pipefail

cmd="${1:-}"

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

# ---------- actions ----------
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

install_claude_integration() {
    local bin="$HOME/.local/bin"
    mkdir -p "$bin"
    for f in _lib.sh claude-notify.sh claude-set-title.sh claude-title-watcher.sh claude-title-watcher-start.sh; do
        cp "$src_root/examples/claude-code/$f" "$bin/"
        chmod +x "$bin/$f"
    done
    echo "==> Claude scripts installed to $bin"
    echo
    echo "Add this to ~/.claude/settings.json (merge with existing 'hooks' block):"
    echo
    sed "s|<INSTALL_DIR>|$bin|g" "$src_root/examples/claude-code/settings.json.snippet"
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

# ---------- main ----------
src_root="$(cd "$(dirname "$0")" && pwd)"

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
