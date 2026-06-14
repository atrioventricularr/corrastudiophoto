import type { BoothSessionStatus } from "@corra/shared";
import type { BoothMode } from "../domain/booth-mode";
import type { Frame } from "../domain/frame";

export interface BoothState {
  status: BoothSessionStatus;
  mode: BoothMode | null;
  currentSessionId: string | null;
  frames: Frame[];
  errorMessage: string | null;
}

export function createInitialBoothState(): BoothState {
  return {
    status: "IDLE",
    mode: null,
    currentSessionId: null,
    frames: [],
    errorMessage: null,
  };
}
