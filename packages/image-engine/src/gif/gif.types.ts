import type { PhotoAsset } from "@corra/shared";
import type { Capture } from "@corra/booth-core";

export interface GifFrameInput {
  capture: Capture;
  delayMs: number;
}

export interface GifRenderOptions {
  width: number;
  height: number;
  repeat: number;
  quality?: number;
}

export interface RenderGifInput {
  sessionId: string;
  frameId: string;
  frames: GifFrameInput[];
  options: GifRenderOptions;
}

export interface GifRenderer {
  render(input: RenderGifInput): Promise<PhotoAsset>;
}
