import type { LocalSettingsPort } from "@corra/booth-core";

export class MemoryLocalSettingsRepository<TSettings extends Record<string, unknown>>
  implements LocalSettingsPort<TSettings>
{
  private settings: TSettings;

  constructor(initialSettings: TSettings) {
    this.settings = structuredClone(initialSettings);
  }

  async get(): Promise<TSettings> {
    return structuredClone(this.settings);
  }

  async set(settings: TSettings): Promise<void> {
    this.settings = structuredClone(settings);
  }

  async patch(settings: Partial<TSettings>): Promise<void> {
    this.settings = {
      ...this.settings,
      ...structuredClone(settings),
    };
  }
}
