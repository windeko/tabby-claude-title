import { Component } from '@angular/core'
import { ConfigService } from 'tabby-core'

/** @hidden */
@Component({
    template: `
        <h3 class="mb-3">tabby-claude-title</h3>
        <div class="form-group">
            <label>Titles directory</label>
            <input class="form-control"
                   type="text"
                   placeholder="(auto)"
                   [(ngModel)]="config.store.claudeTitle.titlesDir"
                   (ngModelChange)="config.save()">
            <small class="form-text text-muted">
                Where the plugin watches for tab-title files. Leave blank to use the platform default.
            </small>
        </div>
        <div class="form-group form-check">
            <input class="form-check-input"
                   type="checkbox"
                   id="claudeTitleEnableInject"
                   [(ngModel)]="config.store.claudeTitle.enableInject"
                   (ngModelChange)="config.save()">
            <label class="form-check-label" for="claudeTitleEnableInject">
                Inject <code>TABBY_TAB_ID</code> into new terminal tabs
            </label>
        </div>
        <div class="form-group">
            <label>Inject delay (ms)</label>
            <input class="form-control"
                   type="number"
                   min="0"
                   step="100"
                   [(ngModel)]="config.store.claudeTitle.injectDelayMs"
                   (ngModelChange)="config.save()">
            <small class="form-text text-muted">
                How long to wait after a tab attaches before sending the export. Lower = faster, more
                likely to clash with a fast typist; higher = safer but slower.
            </small>
        </div>
    `,
})
export class ClaudeTitleSettingsTabComponent {
    constructor (public config: ConfigService) { }
}
