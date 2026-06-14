export type CorraDesktopDeviceInfo = {
  fingerprint: string;
  deviceName: string;
  platform: "WINDOWS_ELECTRON";
  osPlatform: string;
  osRelease: string;
  arch: string;
};

export type CorraVerifyLicenseInput = {
  licenseCode: string;
  deviceName?: string;
};

export type CorraVerifyLicenseResult = {
  valid: boolean;
  reason?: string;
  source?: string;
  checkedAt?: string;
  verifyUrl?: string;
  license?: {
    id: string;
    licenseCode: string;
    ownerEmail: string;
    ownerName: string | null;
    billingCycle: string;
    activeFrom: string | null;
    activeUntil: string | null;
    maxDevices: number;
  };
  device?: {
    id: string;
    alreadyActivated: boolean;
  };
  deviceInfo?: CorraDesktopDeviceInfo;
  mayar?: Record<string, unknown>;
  detail?: string;
  response?: unknown;
  raw?: string;
};

export function isCorraDesktop(): boolean {
  return typeof window !== "undefined" && Boolean(window.corraDesktop);
}

export async function getDesktopDeviceInfo(): Promise<CorraDesktopDeviceInfo | null> {
  if (!window.corraDesktop) {
    return null;
  }

  return window.corraDesktop.device.getInfo();
}

export async function verifyDesktopLicense(
  input: CorraVerifyLicenseInput,
): Promise<CorraVerifyLicenseResult> {
  if (!window.corraDesktop) {
    return {
      valid: false,
      reason: "Corra Desktop bridge is not available. Run inside Electron.",
    };
  }

  return window.corraDesktop.license.verify(input);
}

export async function readDesktopLicenseCache(): Promise<CorraVerifyLicenseResult | null> {
  if (!window.corraDesktop) {
    return null;
  }

  return window.corraDesktop.license.readCache();
}

export async function clearDesktopLicenseCache(): Promise<{ ok: boolean }> {
  if (!window.corraDesktop) {
    return {
      ok: false,
    };
  }

  return window.corraDesktop.license.clearCache();
}
