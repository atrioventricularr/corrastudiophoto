import { createCapture } from "../domain/capture";
import type { CameraPort } from "../ports/camera.port";

export interface CapturePhotoInput {
  sessionId: string;
  frameId: string;
  slotIndex: number;
  captureId: string;
  capturedAt: string;
}

export async function capturePhotoUseCase(
  camera: CameraPort,
  input: CapturePhotoInput,
) {
  const asset = await camera.captureRawPhoto(
    input.sessionId,
    input.frameId,
    input.slotIndex,
  );

  return createCapture({
    id: input.captureId,
    sessionId: input.sessionId,
    frameId: input.frameId,
    slotIndex: input.slotIndex,
    asset,
    capturedAt: input.capturedAt,
  });
}
