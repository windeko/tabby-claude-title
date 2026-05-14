import * as fs from 'fs'
import * as path from 'path'
import * as os from 'os'
import { Injectable } from '@angular/core'
import { BaseTabComponent, ConfigService } from 'tabby-core'
import { TerminalDecorator, BaseTerminalTabComponent } from 'tabby-terminal'

function defaultTitlesDir(): string {
    if (process.platform === 'win32') {
        const appData = process.env.APPDATA || path.join(os.homedir(), 'AppData', 'Roaming')
        return path.join(appData, 'tabby', 'claude-titles')
    }
    if (process.platform === 'darwin') {
        return path.join(os.homedir(), 'Library', 'Application Support', 'tabby', 'claude-titles')
    }
    const xdg = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config')
    return path.join(xdg, 'tabby', 'claude-titles')
}

function genId(): string {
    return 't' + Date.now().toString(36) + Math.random().toString(36).slice(2, 8)
}

/** Pick a shell-specific syntax for exporting an env var, then erase the line. */
function buildInjectCommand(command: string | undefined, id: string): string {
    const exe = (command || '').toLowerCase()
    const isFish = exe.endsWith('fish') || exe.endsWith('fish.exe')
    if (isFish) {
        // fish: `set -gx VAR VALUE`; tput equivalent in fish is the same binary.
        return ` set -gx TABBY_TAB_ID ${id}; tput cuu1 2>/dev/null; tput el 2>/dev/null\n`
    }
    // POSIX (bash / zsh / dash / ksh). Leading space → out of bash history if HISTCONTROL=ignorespace.
    return ` export TABBY_TAB_ID=${id}; tput cuu1 2>/dev/null; tput el 2>/dev/null\n`
}

@Injectable({ providedIn: 'root' })
export class ClaudeTitleDecorator extends TerminalDecorator {
    private titlesDir: string
    private enableInject: boolean
    private injectDelayMs: number
    private tabToId = new WeakMap<BaseTerminalTabComponent, string>()
    private watchers = new Map<string, fs.FSWatcher>()

    constructor(private config: ConfigService) {
        super()
        const cfg = (this.config.store as any).claudeTitle || {}
        this.titlesDir = cfg.titlesDir || defaultTitlesDir()
        this.enableInject = cfg.enableInject !== false
        this.injectDelayMs = typeof cfg.injectDelayMs === 'number' ? cfg.injectDelayMs : 600

        try {
            fs.mkdirSync(this.titlesDir, { recursive: true })
        } catch {
            // ignore
        }
    }

    attach(tab: BaseTerminalTabComponent): void {
        const id = genId()
        this.tabToId.set(tab, id)
        const filePath = path.join(this.titlesDir, `${id}.txt`)

        try {
            fs.writeFileSync(filePath, '')
        } catch {
            // ignore
        }

        if (this.enableInject) {
            const command = (tab as any).profile?.options?.command
            const cmd = buildInjectCommand(command, id)
            setTimeout(() => {
                try {
                    ;(tab as any).session?.write(cmd)
                } catch {
                    // ignore
                }
            }, this.injectDelayMs)
        }

        try {
            const watcher = fs.watch(filePath, () => this.applyTitle(tab, filePath))
            this.watchers.set(id, watcher)
        } catch {
            // ignore
        }
    }

    detach(tab: BaseTerminalTabComponent): void {
        const id = this.tabToId.get(tab)
        if (!id) return
        this.tabToId.delete(tab)
        const w = this.watchers.get(id)
        w?.close()
        this.watchers.delete(id)
        try {
            fs.unlinkSync(path.join(this.titlesDir, `${id}.txt`))
        } catch {
            // ignore
        }
    }

    private applyTitle(tab: BaseTerminalTabComponent, filePath: string): void {
        let title: string
        try {
            title = fs.readFileSync(filePath, 'utf-8').trim()
        } catch {
            return
        }

        const target = (tab.parent as BaseTabComponent | null) ?? tab
        ;(target as any).customTitle = title
        ;(tab as any).customTitle = title
    }
}
