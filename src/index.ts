import { NgModule } from '@angular/core'
import { CommonModule } from '@angular/common'
import TabbyCoreModule from 'tabby-core'
import { TerminalDecorator } from 'tabby-terminal'

import { ClaudeTitleDecorator } from './service'

@NgModule({
    imports: [
        CommonModule,
        TabbyCoreModule,
    ],
    providers: [
        { provide: TerminalDecorator, useClass: ClaudeTitleDecorator, multi: true },
    ],
})
export default class TabbyClaudeTitleModule { }
