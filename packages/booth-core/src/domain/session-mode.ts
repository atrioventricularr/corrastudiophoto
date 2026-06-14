import type { SessionBoothMode } from "./booth-mode";

export function createSessionMode(durationSeconds: number): SessionBoothMode {
  if (!Number.isInteger(durationSeconds) || durationSeconds <= 0) {
    throw new Error("Session Mode requires a positive countdown duration.");
  }

  return {
    type: "SESSION",
    durationSeconds,
    maxFrames: null,
  };
}
