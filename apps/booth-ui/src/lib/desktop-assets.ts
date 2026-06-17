export type CorraPickedBackgroundAsset = {
  cancelled: boolean;
  error?: string;
  sourcePath?: string;
  targetPath?: string;
  filename?: string;
  url?: string;
  backgroundType?: 'image' | 'video';
};

export type CorraPickedQrisAsset = {
  cancelled: boolean;
  error?: string;
  sourcePath?: string;
  targetPath?: string;
  filename?: string;
  url?: string;
};

export function isDesktopBackgroundPickerAvailable(): boolean {
  return typeof window !== 'undefined' && Boolean(window.corraDesktop?.assets?.pickBackground);
}

export function isDesktopQrisPickerAvailable(): boolean {
  return typeof window !== 'undefined' && Boolean(window.corraDesktop?.assets?.pickQris);
}

export async function pickDesktopBackgroundAsset(): Promise<CorraPickedBackgroundAsset> {
  if (!window.corraDesktop?.assets?.pickBackground) {
    return {
      cancelled: true,
      error: 'Desktop background picker is only available inside Electron.',
    };
  }

  return window.corraDesktop.assets.pickBackground();
}

export async function pickDesktopQrisAsset(): Promise<CorraPickedQrisAsset> {
  if (!window.corraDesktop?.assets?.pickQris) {
    return {
      cancelled: true,
      error: 'Desktop QRIS picker is only available inside Electron.',
    };
  }

  return window.corraDesktop.assets.pickQris();
}
