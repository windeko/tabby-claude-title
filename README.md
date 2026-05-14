# tabby-claude-title

[![build](https://github.com/windeko/tabby-claude-title/actions/workflows/build.yml/badge.svg)](https://github.com/windeko/tabby-claude-title/actions/workflows/build.yml)
[![npm](https://img.shields.io/npm/v/tabby-claude-title.svg)](https://www.npmjs.com/package/tabby-claude-title)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[Tabby](https://github.com/Eugeny/tabby) plugin that lets any shell-side process set the current tab's title by writing a file. Originally built so [Claude Code](https://claude.ai/code) hooks can put a status emoji and the session name on the tab — e.g. `🟢 arbio-fix` — and surface which tab needs attention.

It works around the fact that the standard OSC 0 / OSC 2 (`\033]0;…\007`) title escape does not always reach the rendered tab header in current Tabby builds.

> Tested with **Tabby 1.0.231** on Windows 11 + WSL2 (Ubuntu 24.04). Should also work on macOS and native Linux.

## How it works

1. On every new terminal tab the plugin generates a short id and writes
   `export TABBY_TAB_ID=<id>` (or `set -gx TABBY_TAB_ID <id>` for fish) into the
   shell via `session.write`. The line that the shell echoes is then erased
   with `tput cuu1 / tput el`, so you don't see it in scrollback.
2. The plugin watches `<titles_dir>/<id>.txt`.
3. Any process running inside that shell that knows `$TABBY_TAB_ID` can write
   a title to the file, and the plugin sets the tab's `customTitle` to the
   file's contents.

Default `<titles_dir>`:

| OS | Path |
|---|---|
| Windows | `%APPDATA%\tabby\claude-titles\` |
| macOS | `~/Library/Application Support/tabby/claude-titles/` |
| Linux | `${XDG_CONFIG_HOME:-~/.config}/tabby/claude-titles/` |

## Install

### Quick install (plugin + Claude Code integration)

```bash
git clone https://github.com/windeko/tabby-claude-title.git
cd tabby-claude-title
./install.sh --claude
```

This:

1. Builds the plugin (`npm install && npm run build`).
2. Copies the built plugin into Tabby's plugins directory.
3. Installs the Claude Code hook scripts into `~/.local/bin/`.
4. Merges the hook entries into `~/.claude/settings.json` automatically
   (using `jq` if available, then `node`, then prints a snippet to paste in
   manually as a last resort).

After install, **restart Tabby**.

### Plugin only

```bash
./install.sh
```

### Uninstall

```bash
./install.sh --uninstall
```

(Removes the plugin only; does not touch `~/.claude/settings.json`.)

## Usage (any shell)

Open a new tab in Tabby. After ~600 ms `TABBY_TAB_ID` is exported in your shell:

```bash
echo $TABBY_TAB_ID
# t1q3z8a9k…
```

Set the tab title:

```bash
echo '🟢 my-tab' > "<titles_dir>/$TABBY_TAB_ID.txt"
```

Clear the title (revert to the profile name):

```bash
: > "<titles_dir>/$TABBY_TAB_ID.txt"
```

## Claude Code integration

After `./install.sh --claude`, four hook scripts live in `~/.local/bin/`:

| Event | Script | Title becomes |
|---|---|---|
| `SessionStart` | `claude-title-watcher-start.sh` | spawns a poller — `/rename` updates the title live |
| `UserPromptSubmit` | `claude-set-title.sh '🔵'` | `🔵 <session-name>` |
| `Stop` | `claude-notify.sh '🟢'` | `🟢 <session-name>` + BEL (activity indicator) |
| `Notification` | `claude-notify.sh '🟡'` | `🟡 <session-name>` + BEL |

The session name comes from Claude's `/rename` command (stored in
`~/.claude/sessions/<pid>.json`). If you've never run `/rename`, the literal
string `Claude` is used.

### Why a watcher daemon?

`/rename` is a Claude slash command that does **not** fire `UserPromptSubmit`,
so a hook alone cannot react to it. The watcher polls the session JSON once
per second and updates the title file whenever `name` changes, so the rename
shows up in the tab title without you having to send another prompt.

## Configuration

Edit your Tabby `config.yaml` (in the same dir as `claude-titles/`) to add a
`claudeTitle:` block:

```yaml
claudeTitle:
  titlesDir: /custom/path           # override default titles dir
  enableInject: true                # set false to disable `export TABBY_TAB_ID=…`
  injectDelayMs: 600                # ms to wait before injecting
```

All keys are optional; defaults shown.

## Caveats

- Env-var injection happens ~600 ms after the tab attaches. If you start a
  long-running program in the first half-second of a fresh tab, that program
  will not see `TABBY_TAB_ID`. The next tab session is fine.
- POSIX shells (`bash`, `zsh`, `dash`, `ksh`) and `fish` are detected
  automatically from `profile.options.command`. Other shells fall through to
  the POSIX path.
- One title file per tab; the plugin removes the file on tab close.
- The Claude integration's watcher daemon polls. If
  `~/.claude/sessions/` has thousands of files, expect ~tens of ms per poll.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT © Vladimir Traigel
