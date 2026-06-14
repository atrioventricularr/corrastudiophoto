import type { CameraStatus, PhotoAsset } from "@corra/shared";

export interface CameraPort {
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  getStatus(): Promise<CameraStatus>;
  startPreview(): Promise<void>;
  stopPreview(): Promise<void>;
  captureRawPhoto(sessionId: string, frameId: string, slotIndex: number): Promise<PhotoAsset>;
}
