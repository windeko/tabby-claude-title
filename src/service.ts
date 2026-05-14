import * as fs from 'fs'
import * as path from 'path'
import * as os from 'os'
import { Injectable } from '@angular/core'
import { BaseTabComponent } from 'tabby-core'
import { TerminalDecorator, BaseTerminalTabComponent } from 'tabby-terminal'

function defaultTitlesDir(): string {
    // Use Tabby's own config dir so the path stays predictable across hosts.
    if (process.platform === 'win32') {
        const appData = process.env.APPDATA || path.join(os.homedir(), 'AppData', 'Roaming')
        return path.join(appData, 'tabby', 'claude-titles')
    }
    if (process.platform === 'darwin') {
        return path.join(os.homedir(), 'Library', 'Application Support', 'tabby', 'claude-titles')
    }
    // Linux & other Unix: respect $XDG_CONFIG_HOME.
    const xdg = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config')
    return path.join(xdg, 'tabby', 'claude-titles')
}

function genId(): string {
    return 't' + Date.now().toString(36) + Math.random().toString(36).slice(2, 8)
}

@Injectable({ providedIn: 'root' })
export class ClaudeTitleDecorator extends TerminalDecorator {
    private titlesDir = defaultTitlesDir()
    private tabToId = new WeakMap<BaseTerminalTabComponent, string>()
    private watchers = new Map<string, fs.FSWatcher>()

    constructor() {
        super()
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

        const inject = () => {
            // Leading space keeps line out of bash history (HISTCONTROL=ignorespace).
            // tput cuu1 + tput el erases the line that bash echoed for the typed command,
            // so the user does not see the injected `export …` flash through.
            const cmd = ` export TABBY_TAB_ID=${id}; tput cuu1 2>/dev/null; tput el 2>/dev/null\n`
            try {
                ;(tab as any).session?.write(cmd)
            } catch {
                // ignore
            }
        }
        // give the shell ~600ms to print its first prompt before we inject;
        // leading space keeps it out of bash HISTCONTROL=ignorespace history
        setTimeout(inject, 600)

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
        // also write to inner tab so any code that reads it gets the same
        ;(tab as any).customTitle = title
    }
}
