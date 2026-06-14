import type { SingleBoothMode } from "./booth-mode";

export function createSingleMode(targetFrameCount: number): SingleBoothMode {
  if (!Number.isInteger(targetFrameCount) || targetFrameCount <= 0) {
    throw new Error("Single Mode requires a positive target frame count.");
  }

  return {
    type: "SINGLE",
    targetFrameCount,
    durationSeconds: null,
  };
}
