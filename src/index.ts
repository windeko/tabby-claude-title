import { NgModule } from '@angular/core'
import { CommonModule } from '@angular/common'
import { FormsModule } from '@angular/forms'
import TabbyCoreModule, { ConfigProvider } from 'tabby-core'
import { TerminalDecorator } from 'tabby-terminal'
import { SettingsTabProvider } from 'tabby-settings'

import { ClaudeTitleDecorator } from './service'
import { ClaudeTitleConfigProvider } from './configProvider'
import { ClaudeTitleSettingsTabComponent } from './settingsTab.component'
import { ClaudeTitleSettingsTabProvider } from './settingsTabProvider'

@NgModule({
    imports: [
        CommonModule,
        FormsModule,
        TabbyCoreModule,
    ],
    providers: [
        { provide: ConfigProvider, useClass: ClaudeTitleConfigProvider, multi: true },
        { provide: TerminalDecorator, useClass: ClaudeTitleDecorator, multi: true },
        { provide: SettingsTabProvider, useClass: ClaudeTitleSettingsTabProvider, multi: true },
    ],
    declarations: [
        ClaudeTitleSettingsTabComponent,
    ],
})
export default class TabbyClaudeTitleModule { }
