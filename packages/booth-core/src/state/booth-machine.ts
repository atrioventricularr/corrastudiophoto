import { createInitialBoothState, type BoothState } from "./booth-state";
import type { BoothEvent } from "./booth-events";

export function reduceBoothState(
  state: BoothState,
  event: BoothEvent,
): BoothState {
  switch (event.type) {
    case "STARTED":
      return {
        ...state,
        status: "SELECTING_LAYOUT",
        currentSessionId: event.sessionId,
        mode: event.mode,
        frames: [],
        errorMessage: null,
      };

    case "PAYMENT_REQUIRED":
      return {
        ...state,
        status: "WAITING_PAYMENT",
      };

    case "CAPTURE_STARTED":
      return {
        ...state,
        status: "CAPTURING",
      };

    case "FRAME_ADDED":
      return {
        ...state,
        frames: [...state.frames, event.frame],
      };

    case "COMPLETED":
      return {
        ...state,
        status: "COMPLETED",
      };

    case "FAILED":
      return {
        ...state,
        status: "FAILED",
        errorMessage: event.errorMessage,
      };

    case "CANCELLED":
      return {
        ...state,
        status: "CANCELLED",
      };

    case "RESET":
      return createInitialBoothState();

    default: {
      const exhaustiveCheck: never = event;
      return exhaustiveCheck;
    }
  }
}
