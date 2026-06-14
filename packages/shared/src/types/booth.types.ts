import type { CorraId, ISODateTimeString } from "./common.types";

export type BoothRunMode = "SESSION" | "SINGLE";

export type BoothSessionStatus =
  | "IDLE"
  | "SELECTING_LAYOUT"
  | "SELECTING_TEMPLATE"
  | "WAITING_PAYMENT"
  | "CAPTURING"
  | "COMPOSING"
  | "UPLOADING"
  | "PRINTING"
  | "COMPLETED"
  | "FAILED"
  | "CANCELLED";

export type CaptureStatus = "PENDING" | "CAPTURED" | "FAILED";

export type FrameStatus =
  | "PENDING"
  | "CAPTURING"
  | "COMPOSING"
  | "COMPOSED"
  | "UPLOADED"
  | "PRINTED"
  | "FAILED";

export type PhotoSessionId = CorraId;

export interface PhotoSessionSummary {
  id: PhotoSessionId;
  mode: BoothRunMode;
  status: BoothSessionStatus;
  frameCount: number;
  captureCount: number;
  startedAt: ISODateTimeString;
  completedAt: ISODateTimeString | null;
}
