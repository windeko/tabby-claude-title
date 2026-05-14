# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-05-14

### Added
- `install.sh` now auto-merges the hook entries into `~/.claude/settings.json`
  using `jq` (or `python3` as a fallback). Falls back to printing a snippet
  when neither is available.
- `examples/claude-code/` set of portable Bash hook scripts (POSIX paths,
  WSL / macOS / Linux detection).
- `_lib.sh` with `resolve_titles_dir`, `read_claude_session_id`, and
  `resolve_session_name` helpers — shared by all hook scripts.
- `claude-title-watcher.sh` daemon — polls `~/.claude/sessions/<pid>.json` and
  pushes name changes to the tab title file, so `/rename` reflects live without
  waiting for the next prompt to fire a hook.
- Configurable defaults via `claudeTitle` block in Tabby's `config.yaml`
  (currently `titlesDir`).
- GitHub Actions CI: lints + builds the plugin on every push and pull request.
- CONTRIBUTING.md, issue templates, and a development section in README.
- Fish-shell compatible env-var injection: plugin detects shell from
  `profile.options.command` and emits the correct syntax.

### Changed
- `defaultTitlesDir()` now uses platform-appropriate config dirs
  (`%APPDATA%\tabby\` on Windows, `~/Library/Application Support/tabby/` on
  macOS, `${XDG_CONFIG_HOME:-~/.config}/tabby/` on Linux). The earlier
  fallback `~/.tabby-claude-titles/` is gone.
- All hook scripts now run with `set -euo pipefail` so jq / read failures
  abort the script instead of silently writing a broken title.

## [0.1.0] - 2026-05-13

### Added
- Initial release. Plugin watches `<titles_dir>/<id>.txt` and applies file
  contents to the tab's `customTitle`.
- `TABBY_TAB_ID` env-var injected into each terminal tab via `session.write`,
  with `tput cuu1 / tput el` cleanup to hide the inject line.
- README with Quickstart and Claude Code integration example.
