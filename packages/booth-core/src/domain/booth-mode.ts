export type SessionBoothMode = {
  type: "SESSION";
  durationSeconds: number;
  maxFrames: null;
};

export type SingleBoothMode = {
  type: "SINGLE";
  targetFrameCount: number;
  durationSeconds: null;
};

export type BoothMode = SessionBoothMode | SingleBoothMode;

export function isSessionMode(mode: BoothMode): mode is SessionBoothMode {
  return mode.type === "SESSION";
}

export function isSingleMode(mode: BoothMode): mode is SingleBoothMode {
  return mode.type === "SINGLE";
}

export function assertSessionMode(mode: BoothMode): asserts mode is SessionBoothMode {
  if (!isSessionMode(mode)) {
    throw new Error("Expected Session Mode. Session Mode must be timer-based.");
  }
}

export function assertSingleMode(mode: BoothMode): asserts mode is SingleBoothMode {
  if (!isSingleMode(mode)) {
    throw new Error("Expected Single Mode. Single Mode must be frame-count-based.");
  }
}
