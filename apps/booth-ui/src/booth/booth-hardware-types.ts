export type BoothHardwareRuntimeInfo = {
  ok: boolean;
  appVersion?: string;
  platform?: string;
  arch?: string;
  node?: string;
  electron?: string;
  chrome?: string;
  hostname?: string;
  username?: string;
  userDataPath?: string;
  tempPath?: string;
  timestamp?: string;
  error?: string;
};

export type BoothHardwarePrinterInfo = {
  name: string;
  displayName: string;
  description?: string;
  status?: number;
  isDefault?: boolean;
  options?: Record<string, unknown>;
};

export type BoothHardwarePrinterListResult = {
  ok: boolean;
  printers: BoothHardwarePrinterInfo[];
  error?: string;
};

export type BoothHardwarePrintPayload = {
  printerName?: string;
  silent?: boolean;
  copies?: number;
  pageSize?: string | Record<string, unknown>;
};

export type BoothHardwareActionResult = {
  ok: boolean;
  error?: string;
  isFullScreen?: boolean;
  isKiosk?: boolean;
};

export type BoothHardwareTestStatus =
  | 'untested'
  | 'passed'
  | 'warning'
  | 'failed';

export type BoothHardwareTestRecord = {
  id: string;
  label: string;
  status: BoothHardwareTestStatus;
  message?: string;
  updatedAt: string;
};
