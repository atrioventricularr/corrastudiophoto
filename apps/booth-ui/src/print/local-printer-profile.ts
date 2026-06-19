import { defaultPrinterProfile } from './default-printer-profile';
import type { PrinterProfile } from './types';

const STORAGE_KEY = 'corra.printerProfile.v1';

export function loadPrinterProfile(): PrinterProfile {
  if (typeof window === 'undefined') {
    return defaultPrinterProfile;
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultPrinterProfile;

    return {
      ...defaultPrinterProfile,
      ...(JSON.parse(raw) as Partial<PrinterProfile>),
    };
  } catch {
    return defaultPrinterProfile;
  }
}

export function savePrinterProfile(profile: PrinterProfile): void {
  if (typeof window === 'undefined') return;

  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(profile));
}

export function clearPrinterProfile(): void {
  if (typeof window === 'undefined') return;

  window.localStorage.removeItem(STORAGE_KEY);
}
