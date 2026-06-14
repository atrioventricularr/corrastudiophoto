export interface LocalSettingsPort<TSettings> {
  get(): Promise<TSettings>;
  set(settings: TSettings): Promise<void>;
  patch(settings: Partial<TSettings>): Promise<void>;
}
