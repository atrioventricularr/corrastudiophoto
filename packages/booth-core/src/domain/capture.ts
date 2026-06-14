import type { CorraId, ISODateTimeString, PhotoAsset } from "@corra/shared";

export interface Capture {
  id: CorraId;
  sessionId: CorraId;
  frameId: CorraId;
  slotIndex: number;
  asset: PhotoAsset;
  capturedAt: ISODateTimeString;
}

export function createCapture(input: Capture): Capture {
  if (!input.id) throw new Error("Capture ID is required.");
  if (!input.sessionId) throw new Error("Session ID is required.");
  if (!input.frameId) throw new Error("Frame ID is required.");
  if (!Number.isInteger(input.slotIndex) || input.slotIndex < 0) {
    throw new Error("Capture slot index must be a non-negative integer.");
  }

  if (input.asset.kind !== "RAW_CAPTURE") {
    throw new Error("Capture asset must have kind RAW_CAPTURE.");
  }

  return input;
}
