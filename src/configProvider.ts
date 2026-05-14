import { ConfigProvider } from 'tabby-core'

/**
 * Adds `claudeTitle:` defaults to Tabby's merged config.
 * Users can override these in `config.yaml`, e.g.:
 *
 *   claudeTitle:
 *     titlesDir: /custom/path/claude-titles
 *     enableInject: true
 *     injectDelayMs: 600
 */
export class ClaudeTitleConfigProvider extends ConfigProvider {
    defaults = {
        claudeTitle: {
            titlesDir: null,        // null → resolved by service.ts
            enableInject: true,     // turn off if `export TABBY_TAB_ID=...` injection is unwanted
            injectDelayMs: 600,     // wait this many ms after `attach()` before injecting
        },
    }

    platformDefaults = { }
}
