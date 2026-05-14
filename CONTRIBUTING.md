# Contributing

Thanks for taking the time to look. Bug reports and pull requests are welcome.

## Dev setup

```bash
git clone https://github.com/windeko/tabby-claude-title.git
cd tabby-claude-title
npm install --legacy-peer-deps
npm run build         # writes dist/
npm run watch         # rebuilds on save
```

To exercise the plugin against your local Tabby, point Tabby at the dev
checkout — symlink or copy `dist/` + `package.json` into your
`<tabby-data>/plugins/node_modules/tabby-claude-title/`. The included
`./install.sh` does this in one shot:

```bash
./install.sh
```

Then restart Tabby. Open DevTools (`Ctrl+Shift+I`) to see plugin logs in the
console.

## Layout

```
src/                        TypeScript plugin source
  index.ts                  NgModule, providers
  service.ts                TerminalDecorator — attach/detach + title watcher
  configProvider.ts         claudeTitle:* defaults in config.yaml
examples/claude-code/       Portable Bash hook scripts + settings snippet
install.sh                  Plugin + Claude integration installer
```

## Code style

- TypeScript: 4 spaces, no semicolons, double-quoted strings, no `any` except
  where Tabby's public typings force it (`(tab as any).session`).
- Bash: `set -euo pipefail`, double-quoted variables, fail loudly on bad
  input. Run `shellcheck` before sending a PR.

## Submitting changes

1. Fork → branch off `master`.
2. Update `CHANGELOG.md` under `## [Unreleased]` (create the section if
   missing).
3. Run `npm run build` and commit the resulting `dist/` only on release
   tagging commits, not on every change.
4. Open a PR. CI runs `npm run build` and `shellcheck`.
