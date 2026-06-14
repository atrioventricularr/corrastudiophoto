import type {
  GenerateGifRequest,
  GifGeneratorPort,
} from "@corra/booth-core";
import type { PhotoAsset } from "@corra/shared";
import type { GifRenderer } from "./gif.types";

export interface GifGeneratorOptions {
  width: number;
  height: number;
  delayMs: number;
  repeat: number;
  quality?: number;
}

export class GifGenerator implements GifGeneratorPort {
  constructor(
    private readonly renderer: GifRenderer,
    private readonly options: GifGeneratorOptions,
  ) {}

  async generateGif(request: GenerateGifRequest): Promise<PhotoAsset> {
    if (request.captures.length <= 0) {
      throw new Error("Cannot generate GIF without captures.");
    }

    return this.renderer.render({
      sessionId: request.sessionId,
      frameId: request.frameId,
      frames: request.captures.map((capture) => ({
        capture,
        delayMs: this.options.delayMs,
      })),
      options: {
        width: this.options.width,
        height: this.options.height,
        repeat: this.options.repeat,
        quality: this.options.quality,
      },
    });
  }
}
