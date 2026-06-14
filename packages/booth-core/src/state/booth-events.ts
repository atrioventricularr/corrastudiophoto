import type { BoothMode } from "../domain/booth-mode";
import type { Frame } from "../domain/frame";

export type BoothEvent =
  | {
      type: "STARTED";
      sessionId: string;
      mode: BoothMode;
    }
  | {
      type: "PAYMENT_REQUIRED";
    }
  | {
      type: "CAPTURE_STARTED";
    }
  | {
      type: "FRAME_ADDED";
      frame: Frame;
    }
  | {
      type: "COMPLETED";
    }
  | {
      type: "FAILED";
      errorMessage: string;
    }
  | {
      type: "CANCELLED";
    }
  | {
      type: "RESET";
    };
