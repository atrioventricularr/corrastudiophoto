import type { BoothLayout, BoothTemplate, PhotoAsset } from "@corra/shared";
import type { Capture } from "../domain/capture";

export interface ComposeFrameRequest {
  sessionId: string;
  frameId: string;
  layout: BoothLayout;
  template: BoothTemplate;
  captures: Capture[];
}

export interface ImageComposerPort {
  composeFrame(request: ComposeFrameRequest): Promise<PhotoAsset>;
}
