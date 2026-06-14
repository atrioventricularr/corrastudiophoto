import {
  MAX_CAPTURE_PER_FRAME,
  MIN_CAPTURE_PER_FRAME,
  type CorraId,
  type FrameStatus,
  type ISODateTimeString,
  type PhotoAsset,
} from "@corra/shared";

import type { Capture } from "./capture";

export interface Frame {
  id: CorraId;
  sessionId: CorraId;
  layoutId: CorraId;
  templateId: CorraId;
  captures: Capture[];
  finalAsset: PhotoAsset | null;
  gifAsset: PhotoAsset | null;
  status: FrameStatus;
  createdAt: ISODateTimeString;
  completedAt: ISODateTimeString | null;
}

export function assertValidCaptureCount(captureCount: number): void {
  if (
    !Number.isInteger(captureCount) ||
    captureCount < MIN_CAPTURE_PER_FRAME ||
    captureCount > MAX_CAPTURE_PER_FRAME
  ) {
    throw new Error(
      `A frame must contain ${MIN_CAPTURE_PER_FRAME}-${MAX_CAPTURE_PER_FRAME} captures.`,
    );
  }
}

export function createFrame(input: Frame): Frame {
  if (!input.id) throw new Error("Frame ID is required.");
  if (!input.sessionId) throw new Error("Session ID is required.");
  if (!input.layoutId) throw new Error("Layout ID is required.");
  if (!input.templateId) throw new Error("Template ID is required.");

  if (input.captures.length > 0) {
    assertValidCaptureCount(input.captures.length);
  }

  if (input.finalAsset && input.finalAsset.kind !== "FINAL_FRAME") {
    throw new Error("Frame final asset must have kind FINAL_FRAME.");
  }

  if (input.gifAsset && input.gifAsset.kind !== "GIF") {
    throw new Error("Frame GIF asset must have kind GIF.");
  }

  return input;
}
