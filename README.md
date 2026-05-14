# tabby-claude-title

[Tabby](https://github.com/Eugeny/tabby) plugin that lets any shell-side process set the current tab's title by writing a file. Originally built so [Claude Code](https://claude.ai/code) hooks can put a status emoji and the session name on the tab — e.g. `🟢 arbio-fix` — and surface which tab needs attention.

It works around the fact that the standard OSC 0 / OSC 2 (`\033]0;…\007`) title escape does not always reach the rendered tab header in current Tabby builds.

## How it works

1. On every new terminal tab the plugin generates a short id and writes `export TABBY_TAB_ID=<id>` into the shell via `session.write` (the line that bash echoes is then erased with `tput cuu1 / tput el`, so you don't see it).
2. The plugin watches `<titles_dir>/<id>.txt`.
3. Any process running inside that shell that knows `$TABBY_TAB_ID` can write a title to the file, and the plugin sets the tab's `customTitle` to the file's contents.

Default `<titles_dir>`:

- Windows: `%APPDATA%\tabby\claude-titles\`
- macOS: `~/Library/Application Support/tabby/claude-titles/`
- Linux: `${XDG_CONFIG_HOME:-~/.config}/tabby/claude-titles/`

## Install

### Quick install (plugin + Claude Code integration)

```bash
git clone https://github.com/vtraigel/tabby-claude-title.git
cd tabby-claude-title
./install.sh --claude
```

This:

1. Builds the plugin (`npm install && npm run build`)
2. Copies the built plugin into Tabby's plugins directory
3. Installs the Claude Code hook scripts into `~/.local/bin/`
4. Prints a `settings.json` snippet for you to merge into `~/.claude/settings.json`

After install, **restart Tabby**.

### Plugin only

```bash
./install.sh
```

### Uninstall

```bash
./install.sh --uninstall
```

## Usage (any shell)

Open a new tab in Tabby. After ~600 ms `TABBY_TAB_ID` is exported in your shell:

```bash
echo $TABBY_TAB_ID
# t1q3z8a9k...
```

Set the tab title:

```bash
echo '🟢 my-tab' > "<titles_dir>/$TABBY_TAB_ID.txt"
```

Clear the title (revert to profile name):

```bash
: > "<titles_dir>/$TABBY_TAB_ID.txt"
```

## Claude Code integration

After `./install.sh --claude`, four hook scripts live in `~/.local/bin/`:

| Event | Script | Title becomes |
|---|---|---|
| `SessionStart` | `claude-title-watcher-start.sh` | spawns a poller — `/rename` updates title live |
| `UserPromptSubmit` | `claude-set-title.sh '🔵'` | `🔵 <session-name>` |
| `Stop` | `claude-notify.sh '🟢'` | `🟢 <session-name>` + BEL (activity indicator) |
| `Notification` | `claude-notify.sh '🟡'` | `🟡 <session-name>` + BEL |

The session name comes from Claude's `/rename` command (stored in `~/.claude/sessions/<pid>.json`).
If you've never run `/rename`, the literal string `Claude` is used.

Merge the printed snippet (with `<INSTALL_DIR>` substituted) into your `~/.claude/settings.json` under the existing `hooks` block. If you already have other hooks for `SessionStart` / `UserPromptSubmit`, just append these entries to the corresponding `hooks` arrays.

### Why a watcher daemon?

`/rename` is a Claude slash command that does **not** fire `UserPromptSubmit`, so a hook alone cannot react to it. The watcher polls the session JSON once per second and updates the title file whenever `name` changes, so the rename shows up in the tab title without you having to send another prompt.

## Caveats

- Env-var injection happens ~600 ms after the tab attaches. If you start a long-running program in the first half-second of a fresh tab, that program will not see `TABBY_TAB_ID`. The next tab session is fine.
- Inject syntax is POSIX (`bash`, `zsh`, `dash`, `ksh`). Not compatible with `fish` out of the box.
- One title file per tab; the plugin removes the file on tab close.
- The watcher daemon polls. If your `~/.claude/sessions/` has thousands of files, expect ~tens of ms per poll.

## License

MIT © Vladimir Traigel
