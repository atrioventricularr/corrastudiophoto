import type { PhotoAsset } from "@corra/shared";
import type { Capture } from "../domain/capture";

export interface GenerateGifRequest {
  sessionId: string;
  frameId: string;
  captures: Capture[];
}

export interface GifGeneratorPort {
  generateGif(request: GenerateGifRequest): Promise<PhotoAsset>;
}
