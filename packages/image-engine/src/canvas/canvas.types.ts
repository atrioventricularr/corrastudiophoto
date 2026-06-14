import type { PhotoAsset } from "@corra/shared";

export type ImageSourceKind =
  | "LOCAL_PATH"
  | "PUBLIC_URL"
  | "STORAGE_PATH"
  | "DATA_URL"
  | "EMPTY";

export interface ImageSource {
  kind: ImageSourceKind;
  value: string;
}

export interface CanvasHandle {
  id: string;
  width: number;
  height: number;
}

export interface LoadedImageHandle {
  id: string;
  source: ImageSource;
  width?: number;
  height?: number;
}

export interface DrawImageOptions {
  x: number;
  y: number;
  width: number;
  height: number;
  rotationDeg: number;
  borderRadius: number;
  objectFit: "cover" | "contain";
}

export interface ExportCanvasOptions {
  sessionId: string;
  frameId: string;
  mimeType: "image/png" | "image/jpeg" | "image/webp";
  quality?: number;
}

export interface CanvasAdapter {
  createCanvas(width: number, height: number): Promise<CanvasHandle>;

  loadImage(source: ImageSource): Promise<LoadedImageHandle>;

  drawImage(
    canvas: CanvasHandle,
    image: LoadedImageHandle,
    options: DrawImageOptions,
  ): Promise<void>;

  exportCanvas(
    canvas: CanvasHandle,
    options: ExportCanvasOptions,
  ): Promise<PhotoAsset>;
}
