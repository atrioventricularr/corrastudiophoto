export type CameraProvider = "CANON_EDSDK" | "SONY_SDK" | "WEBCAM" | "MOCK";

export type PrinterProvider =
  | "DNP"
  | "THERMAL"
  | "EPSON_WIFI"
  | "CANON_SELPHY"
  | "WINDOWS_SPOOLER"
  | "MOCK";

export type HardwareConnectionStatus =
  | "DISCONNECTED"
  | "CONNECTING"
  | "CONNECTED"
  | "ERROR";

export interface CameraStatus {
  provider: CameraProvider;
  status: HardwareConnectionStatus;
  deviceName?: string;
  batteryLevel?: number;
  errorMessage?: string;
}

export interface PrinterStatus {
  provider: PrinterProvider;
  status: HardwareConnectionStatus;
  deviceName?: string;
  paperRemaining?: number;
  errorMessage?: string;
}
