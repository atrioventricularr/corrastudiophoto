import type { PhotoAsset } from "@corra/shared";
import { createAssetId } from "../utils/asset-id";
import type {
  CanvasAdapter,
  CanvasHandle,
  DrawImageOptions,
  ExportCanvasOptions,
  ImageSource,
  LoadedImageHandle,
} from "./canvas.types";

interface RecordedDrawOperation {
  canvasId: string;
  imageId: string;
  source: ImageSource;
  options: DrawImageOptions;
}

export class InMemoryCanvasAdapter implements CanvasAdapter {
  private readonly drawOperations: RecordedDrawOperation[] = [];

  async createCanvas(width: number, height: number): Promise<CanvasHandle> {
    if (width <= 0 || height <= 0) {
      throw new Error("Canvas width and height must be positive.");
    }

    return {
      id: createAssetId("canvas"),
      width,
      height,
    };
  }

  async loadImage(source: ImageSource): Promise<LoadedImageHandle> {
    return {
      id: createAssetId("image"),
      source,
    };
  }

  async drawImage(
    canvas: CanvasHandle,
    image: LoadedImageHandle,
    options: DrawImageOptions,
  ): Promise<void> {
    this.drawOperations.push({
      canvasId: canvas.id,
      imageId: image.id,
      source: image.source,
      options,
    });
  }

  async exportCanvas(
    canvas: CanvasHandle,
    options: ExportCanvasOptions,
  ): Promise<PhotoAsset> {
    return {
      id: createAssetId("final-frame"),
      sessionId: options.sessionId,
      kind: "FINAL_FRAME",
      localPath: `memory://frames/${options.sessionId}/${options.frameId}.${options.mimeType.split("/")[1]}`,
      mimeType: options.mimeType,
      width: canvas.width,
      height: canvas.height,
      status: "LOCAL_ONLY",
      createdAt: new Date().toISOString(),
    };
  }

  getRecordedDrawOperations(): RecordedDrawOperation[] {
    return [...this.drawOperations];
  }

  clear(): void {
    this.drawOperations.length = 0;
  }
}
