import { DEFAULT_CORRA_PAYMENT_CONFIG } from './default-payment-config';
import type { CorraPaymentConfig } from './types';

const STORAGE_KEY = 'corra.paymentConfig.v1';

export function loadLocalPaymentConfig(): CorraPaymentConfig {
  if (typeof window === 'undefined') {
    return DEFAULT_CORRA_PAYMENT_CONFIG;
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);

    if (!raw) {
      return DEFAULT_CORRA_PAYMENT_CONFIG;
    }

    const parsed = JSON.parse(raw) as Partial<CorraPaymentConfig>;

    return {
      ...DEFAULT_CORRA_PAYMENT_CONFIG,
      ...parsed,
      staticQris: {
        ...DEFAULT_CORRA_PAYMENT_CONFIG.staticQris,
        ...(parsed.staticQris || {}),
      },
      doku: {
        ...DEFAULT_CORRA_PAYMENT_CONFIG.doku,
        ...(parsed.doku || {}),
      },
      mayarCheckout: {
        ...DEFAULT_CORRA_PAYMENT_CONFIG.mayarCheckout,
        ...(parsed.mayarCheckout || {}),
      },
      manualCash: {
        ...DEFAULT_CORRA_PAYMENT_CONFIG.manualCash,
        ...(parsed.manualCash || {}),
      },
    };
  } catch {
    return DEFAULT_CORRA_PAYMENT_CONFIG;
  }
}

export function saveLocalPaymentConfig(config: CorraPaymentConfig): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.setItem(
    STORAGE_KEY,
    JSON.stringify({
      ...config,
      updatedAt: new Date().toISOString(),
    }),
  );
}

export function clearLocalPaymentConfig(): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.removeItem(STORAGE_KEY);
}
