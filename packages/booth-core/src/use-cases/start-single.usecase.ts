import { createSingleMode } from "../domain/single-mode";

export interface StartSingleInput {
  targetFrameCount: number;
}

export function startSingleUseCase(input: StartSingleInput) {
  return createSingleMode(input.targetFrameCount);
}
