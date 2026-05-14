import { Injectable } from '@angular/core'
import { SettingsTabProvider } from 'tabby-settings'

import { ClaudeTitleSettingsTabComponent } from './settingsTab.component'

/** @hidden */
@Injectable()
export class ClaudeTitleSettingsTabProvider extends SettingsTabProvider {
    id = 'claude-title'
    icon = 'window-restore'
    title = 'Claude Title'

    getComponentType (): any {
        return ClaudeTitleSettingsTabComponent
    }
}
