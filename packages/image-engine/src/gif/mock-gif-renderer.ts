import type { PhotoAsset } from "@corra/shared";
import { createAssetId } from "../utils/asset-id";
import type { GifRenderer, RenderGifInput } from "./gif.types";

export class MockGifRenderer implements GifRenderer {
  async render(input: RenderGifInput): Promise<PhotoAsset> {
    if (input.frames.length <= 0) {
      throw new Error("Cannot render GIF without frames.");
    }

    if (input.options.width <= 0 || input.options.height <= 0) {
      throw new Error("GIF width and height must be positive.");
    }

    return {
      id: createAssetId("gif"),
      sessionId: input.sessionId,
      kind: "GIF",
      localPath: `memory://gifs/${input.sessionId}/${input.frameId}.gif`,
      mimeType: "image/gif",
      width: input.options.width,
      height: input.options.height,
      status: "LOCAL_ONLY",
      createdAt: new Date().toISOString(),
    };
  }
}
