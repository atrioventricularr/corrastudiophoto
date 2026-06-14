import { createSessionMode } from "../domain/session-mode";

export interface StartSessionInput {
  durationSeconds: number;
}

export function startSessionUseCase(input: StartSessionInput) {
  return createSessionMode(input.durationSeconds);
}
