export {};

declare global {
  type CorraDesktopDeviceInfo = {
    fingerprint: string;
    deviceName: string;
    platform: "WINDOWS_ELECTRON";
    osPlatform: string;
    osRelease: string;
    arch: string;
  };

  type CorraVerifyLicenseResult = {
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

  interface Window {
    corraDesktop?: {
      device: {
        getInfo: () => Promise<CorraDesktopDeviceInfo>;
      };
      license: {
        verify: (input: {
          licenseCode: string;
          deviceName?: string;
        }) => Promise<CorraVerifyLicenseResult>;
        readCache: () => Promise<CorraVerifyLicenseResult | null>;
        clearCache: () => Promise<{ ok: boolean }>;
      };
    };
  }
}
