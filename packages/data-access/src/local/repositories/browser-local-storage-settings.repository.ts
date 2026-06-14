import type { LocalSettingsPort } from "@corra/booth-core";

export class BrowserLocalStorageSettingsRepository<
  TSettings extends Record<string, unknown>,
> implements LocalSettingsPort<TSettings>
{
  constructor(
    private readonly storageKey: string,
    private readonly defaultSettings: TSettings,
  ) {}

  async get(): Promise<TSettings> {
    this.assertLocalStorageAvailable();

    const rawValue = localStorage.getItem(this.storageKey);

    if (!rawValue) {
      return structuredClone(this.defaultSettings);
    }

    try {
      return {
        ...this.defaultSettings,
        ...(JSON.parse(rawValue) as Partial<TSettings>),
      };
    } catch {
      return structuredClone(this.defaultSettings);
    }
  }

  async set(settings: TSettings): Promise<void> {
    this.assertLocalStorageAvailable();
    localStorage.setItem(this.storageKey, JSON.stringify(settings));
  }

  async patch(settings: Partial<TSettings>): Promise<void> {
    const current = await this.get();

    await this.set({
      ...current,
      ...settings,
    });
  }

  private assertLocalStorageAvailable(): void {
    if (typeof localStorage === "undefined") {
      throw new Error("localStorage is not available in this runtime.");
    }
  }
}
