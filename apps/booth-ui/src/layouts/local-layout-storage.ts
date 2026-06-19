import {
  defaultActivePhotoLayout,
  defaultLayoutGuideSettings,
  defaultPhotoLayouts,
} from './default-layouts';
import type {
  LayoutGuideSettings,
  PhotoLayout,
} from './types';

const LAYOUTS_KEY = 'corra.photoLayouts.v1';
const ACTIVE_LAYOUT_ID_KEY = 'corra.activePhotoLayoutId.v1';
const GUIDE_SETTINGS_KEY = 'corra.layoutGuideSettings.v1';

export function loadPhotoLayouts(): PhotoLayout[] {
  if (typeof window === 'undefined') return defaultPhotoLayouts;

  try {
    const raw = window.localStorage.getItem(LAYOUTS_KEY);
    const parsed = raw ? JSON.parse(raw) : null;

    if (!Array.isArray(parsed) || parsed.length === 0) {
      return defaultPhotoLayouts;
    }

    return parsed as PhotoLayout[];
  } catch {
    return defaultPhotoLayouts;
  }
}

export function savePhotoLayouts(layouts: PhotoLayout[]): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(LAYOUTS_KEY, JSON.stringify(layouts));
}

export function loadActivePhotoLayoutId(): string {
  if (typeof window === 'undefined') return defaultActivePhotoLayout.id;

  return (
    window.localStorage.getItem(ACTIVE_LAYOUT_ID_KEY) ||
    defaultActivePhotoLayout.id
  );
}

export function saveActivePhotoLayoutId(layoutId: string): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(ACTIVE_LAYOUT_ID_KEY, layoutId);
}

export function loadLayoutGuideSettings(): LayoutGuideSettings {
  if (typeof window === 'undefined') return defaultLayoutGuideSettings;

  try {
    const raw = window.localStorage.getItem(GUIDE_SETTINGS_KEY);
    const parsed = raw ? JSON.parse(raw) : null;

    return {
      ...defaultLayoutGuideSettings,
      ...(parsed || {}),
    };
  } catch {
    return defaultLayoutGuideSettings;
  }
}

export function saveLayoutGuideSettings(settings: LayoutGuideSettings): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(GUIDE_SETTINGS_KEY, JSON.stringify(settings));
}

export function clearLayoutStorage(): void {
  if (typeof window === 'undefined') return;

  window.localStorage.removeItem(LAYOUTS_KEY);
  window.localStorage.removeItem(ACTIVE_LAYOUT_ID_KEY);
  window.localStorage.removeItem(GUIDE_SETTINGS_KEY);
}
