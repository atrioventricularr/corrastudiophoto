import type { CameraProvider, PrinterProvider } from "@corra/shared";

export interface CorraBoothLocalSettings {
  licenseCode: string | null;
  deviceId: string | null;
  deviceName: string | null;

  selectedCameraProvider: CameraProvider;
  selectedPrinterProvider: PrinterProvider;

  printCopies: number;
  pricePerSession: number;

  qrisImageLocalPath: string | null;
  downloadPageBaseUrl: string;

  lastLicenseCheckAt: string | null;
  lastSyncedAt: string | null;
}

export const DEFAULT_CORRA_BOOTH_LOCAL_SETTINGS: CorraBoothLocalSettings = {
  licenseCode: null,
  deviceId: null,
  deviceName: null,

  selectedCameraProvider: "MOCK",
  selectedPrinterProvider: "MOCK",

  printCopies: 1,
  pricePerSession: 0,

  qrisImageLocalPath: null,
  downloadPageBaseUrl: "",

  lastLicenseCheckAt: null,
  lastSyncedAt: null,
};
