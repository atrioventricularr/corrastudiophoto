import { DEFAULT_CORRA_BRAND_CONFIG } from './default-brand-config';
import type { CorraBrandConfig } from './types';

const STORAGE_KEY = 'corra.brandConfig.v1';

export function loadLocalBrandConfig(): CorraBrandConfig {
  if (typeof window === 'undefined') {
    return DEFAULT_CORRA_BRAND_CONFIG;
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);

    if (!raw) {
      return DEFAULT_CORRA_BRAND_CONFIG;
    }

    return {
      ...DEFAULT_CORRA_BRAND_CONFIG,
      ...JSON.parse(raw),
      appearance: {
        ...DEFAULT_CORRA_BRAND_CONFIG.appearance,
        ...(JSON.parse(raw).appearance || {}),
      },
    };
  } catch {
    return DEFAULT_CORRA_BRAND_CONFIG;
  }
}

export function saveLocalBrandConfig(config: CorraBrandConfig): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
}

export function clearLocalBrandConfig(): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.removeItem(STORAGE_KEY);
}
