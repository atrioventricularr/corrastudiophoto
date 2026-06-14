import type { PhotoAsset, PrinterStatus } from "@corra/shared";

export interface PrintJobRequest {
  frameAsset: PhotoAsset;
  copies: number;
}

export interface PrintJobResult {
  jobId: string;
  accepted: boolean;
  message?: string;
}

export interface PrinterPort {
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  getStatus(): Promise<PrinterStatus>;
  printFrame(request: PrintJobRequest): Promise<PrintJobResult>;
}
