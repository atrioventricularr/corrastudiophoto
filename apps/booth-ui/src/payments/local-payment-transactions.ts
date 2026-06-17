import type { CorraPaymentTransaction } from './transaction-types';

const STORAGE_KEY = 'corra.paymentTransactions.v1';

export function loadLocalPaymentTransactions(): CorraPaymentTransaction[] {
  if (typeof window === 'undefined') {
    return [];
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);

    if (!raw) {
      return [];
    }

    const parsed = JSON.parse(raw);

    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function saveLocalPaymentTransactions(
  transactions: CorraPaymentTransaction[],
): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
}

export function clearLocalPaymentTransactions(): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.removeItem(STORAGE_KEY);
}
