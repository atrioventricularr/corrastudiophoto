#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 3 Image Engine"
echo "========================================"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

create_dir() {
  mkdir -p "$1"
  touch "$1/.gitkeep"
}

write_file() {
  local file_path="$1"
  mkdir -p "$(dirname "$file_path")"
  cat > "$file_path"
  echo "WRITE file: $file_path"
}

echo ""
echo "Checking repository structure..."

[ -f "package.json" ] || fail "Root package.json not found. Run Phase 0 first."
[ -d "packages/shared/src" ] || fail "packages/shared/src not found. Run Phase 0 first."
[ -d "packages/booth-core/src" ] || fail "packages/booth-core/src not found. Run Phase 2 first."
[ -d "packages/image-engine/src" ] || fail "packages/image-engine/src not found. Run Phase 0 first."

echo "Repository structure OK."

echo ""
echo "Creating backup..."

BACKUP_DIR="packages/.phase-backups/phase-3-image-engine-before-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

cp -a packages/image-engine/src "$BACKUP_DIR/image-engine-src"

echo "Backup stored at: $BACKUP_DIR"

echo ""
echo "Creating image-engine folders..."

create_dir "packages/image-engine/src/composer"
create_dir "packages/image-engine/src/gif"
create_dir "packages/image-engine/src/qr"
create_dir "packages/image-engine/src/canvas"
create_dir "packages/image-engine/src/utils"

echo ""
echo "Updating image-engine package.json..."

write_file "packages/image-engine/package.json" <<'JSON'
{
  "name": "@corra/image-engine",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc -b",
    "typecheck": "tsc --noEmit",
    "lint": "tsc --noEmit",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@corra/booth-core": "workspace:*",
    "@corra/shared": "workspace:*"
  },
  "devDependencies": {
    "typescript": "^5.7.2"
  }
}
JSON

write_file "packages/image-engine/tsconfig.json" <<'JSON'
{
  "extends": "../../tsconfig.base.json",
  "include": ["src"]
}
JSON

echo ""
echo "Creating image utility files..."

write_file "packages/image-engine/src/utils/asset-id.ts" <<'TS'
export function createAssetId(prefix: string): string {
  const safePrefix = prefix
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");

  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).slice(2, 10);

  return `${safePrefix}-${timestamp}-${random}`;
}
TS

write_file "packages/image-engine/src/utils/mime.ts" <<'TS'
export type SupportedImageMimeType =
  | "image/png"
  | "image/jpeg"
  | "image/webp"
  | "image/gif";

export function getFileExtensionFromMimeType(
  mimeType: SupportedImageMimeType,
): string {
  switch (mimeType) {
    case "image/png":
      return "png";
    case "image/jpeg":
      return "jpg";
    case "image/webp":
      return "webp";
    case "image/gif":
      return "gif";
    default: {
      const exhaustiveCheck: never = mimeType;
      return exhaustiveCheck;
    }
  }
}
TS

write_file "packages/image-engine/src/utils/url.ts" <<'TS'
export function normalizeBaseUrl(baseUrl: string): string {
  const trimmed = baseUrl.trim();

  if (!trimmed) {
    throw new Error("Base URL is required.");
  }

  return trimmed.replace(/\/+$/, "");
}

export function appendQueryParams(
  url: string,
  params: Record<string, string | number | boolean | null | undefined>,
): string {
  const parsedUrl = new URL(url);

  for (const [key, value] of Object.entries(params)) {
    if (value !== null && value !== undefined) {
      parsedUrl.searchParams.set(key, String(value));
    }
  }

  return parsedUrl.toString();
}
TS

echo ""
echo "Creating canvas contracts..."

write_file "packages/image-engine/src/canvas/canvas.types.ts" <<'TS'
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
TS

write_file "packages/image-engine/src/canvas/image-source.ts" <<'TS'
import type { BoothTemplate, PhotoAsset } from "@corra/shared";
import type { ImageSource } from "./canvas.types";

export function imageSourceFromTemplate(template: BoothTemplate): ImageSource {
  if (template.backgroundLocalPath) {
    return {
      kind: "LOCAL_PATH",
      value: template.backgroundLocalPath,
    };
  }

  if (template.backgroundPublicUrl) {
    return {
      kind: "PUBLIC_URL",
      value: template.backgroundPublicUrl,
    };
  }

  if (template.backgroundStoragePath) {
    return {
      kind: "STORAGE_PATH",
      value: template.backgroundStoragePath,
    };
  }

  return {
    kind: "EMPTY",
    value: "",
  };
}

export function imageSourceFromPhotoAsset(asset: PhotoAsset): ImageSource {
  if (asset.localPath) {
    return {
      kind: "LOCAL_PATH",
      value: asset.localPath,
    };
  }

  if (asset.publicUrl) {
    return {
      kind: "PUBLIC_URL",
      value: asset.publicUrl,
    };
  }

  if (asset.storagePath) {
    return {
      kind: "STORAGE_PATH",
      value: asset.storagePath,
    };
  }

  throw new Error(`Photo asset ${asset.id} does not contain a usable image source.`);
}
TS

write_file "packages/image-engine/src/canvas/in-memory-canvas.adapter.ts" <<'TS'
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
TS

echo ""
echo "Creating composition engine..."

write_file "packages/image-engine/src/composer/slot-transform.ts" <<'TS'
import type { LayoutSlot } from "@corra/shared";
import type { DrawImageOptions } from "../canvas/canvas.types";

export interface SlotTransformInput {
  slot: LayoutSlot;
}

export function slotToDrawImageOptions(
  input: SlotTransformInput,
): DrawImageOptions {
  const { slot } = input;

  if (slot.width <= 0 || slot.height <= 0) {
    throw new Error(`Invalid slot size for slot ${slot.slotIndex}.`);
  }

  return {
    x: slot.x,
    y: slot.y,
    width: slot.width,
    height: slot.height,
    rotationDeg: slot.rotationDeg,
    borderRadius: slot.borderRadius,
    objectFit: slot.objectFit,
  };
}
TS

write_file "packages/image-engine/src/composer/layer-engine.ts" <<'TS'
import type { BoothLayout, BoothTemplate } from "@corra/shared";
import type { Capture } from "@corra/booth-core";
import {
  imageSourceFromPhotoAsset,
  imageSourceFromTemplate,
} from "../canvas/image-source";
import type { ImageSource } from "../canvas/canvas.types";

export type CompositionLayerKind = "TEMPLATE_BACKGROUND" | "RAW_CAPTURE";

export interface TemplateBackgroundLayer {
  kind: "TEMPLATE_BACKGROUND";
  order: 0;
  source: ImageSource;
}

export interface RawCaptureLayer {
  kind: "RAW_CAPTURE";
  order: number;
  slotIndex: number;
  capture: Capture;
  source: ImageSource;
}

export type CompositionLayer = TemplateBackgroundLayer | RawCaptureLayer;

export interface BuildCompositionLayersInput {
  layout: BoothLayout;
  template: BoothTemplate;
  captures: Capture[];
}

export function buildCompositionLayers(
  input: BuildCompositionLayersInput,
): CompositionLayer[] {
  const { layout, template, captures } = input;

  if (layout.id !== template.layoutId) {
    throw new Error("Template layout ID does not match selected layout ID.");
  }

  if (captures.length !== layout.slotCount) {
    throw new Error(
      `Layout requires ${layout.slotCount} captures, but received ${captures.length}.`,
    );
  }

  const layers: CompositionLayer[] = [
    {
      kind: "TEMPLATE_BACKGROUND",
      order: 0,
      source: imageSourceFromTemplate(template),
    },
  ];

  for (const capture of captures) {
    const slotExists = layout.slots.some(
      (slot) => slot.slotIndex === capture.slotIndex,
    );

    if (!slotExists) {
      throw new Error(`Capture slot ${capture.slotIndex} does not exist in layout.`);
    }

    layers.push({
      kind: "RAW_CAPTURE",
      order: 10 + capture.slotIndex,
      slotIndex: capture.slotIndex,
      capture,
      source: imageSourceFromPhotoAsset(capture.asset),
    });
  }

  return layers.sort((a, b) => a.order - b.order);
}
TS

write_file "packages/image-engine/src/composer/frame-composer.ts" <<'TS'
import type { PhotoAsset } from "@corra/shared";
import type { ComposeFrameRequest, ImageComposerPort } from "@corra/booth-core";
import type { CanvasAdapter } from "../canvas/canvas.types";
import { buildCompositionLayers } from "./layer-engine";
import { slotToDrawImageOptions } from "./slot-transform";

export interface FrameComposerOptions {
  outputMimeType?: "image/png" | "image/jpeg" | "image/webp";
  outputQuality?: number;
}

export class FrameComposer implements ImageComposerPort {
  constructor(
    private readonly canvasAdapter: CanvasAdapter,
    private readonly options: FrameComposerOptions = {},
  ) {}

  async composeFrame(request: ComposeFrameRequest): Promise<PhotoAsset> {
    const { sessionId, frameId, layout, template, captures } = request;

    if (layout.canvasWidth !== template.canvasWidth) {
      throw new Error("Layout width and template width must match.");
    }

    if (layout.canvasHeight !== template.canvasHeight) {
      throw new Error("Layout height and template height must match.");
    }

    const canvas = await this.canvasAdapter.createCanvas(
      layout.canvasWidth,
      layout.canvasHeight,
    );

    const layers = buildCompositionLayers({
      layout,
      template,
      captures,
    });

    for (const layer of layers) {
      if (layer.kind === "TEMPLATE_BACKGROUND") {
        const image = await this.canvasAdapter.loadImage(layer.source);

        await this.canvasAdapter.drawImage(canvas, image, {
          x: 0,
          y: 0,
          width: layout.canvasWidth,
          height: layout.canvasHeight,
          rotationDeg: 0,
          borderRadius: 0,
          objectFit: "cover",
        });

        continue;
      }

      const slot = layout.slots.find(
        (layoutSlot) => layoutSlot.slotIndex === layer.slotIndex,
      );

      if (!slot) {
        throw new Error(`Slot not found: ${layer.slotIndex}.`);
      }

      const image = await this.canvasAdapter.loadImage(layer.source);

      await this.canvasAdapter.drawImage(
        canvas,
        image,
        slotToDrawImageOptions({ slot }),
      );
    }

    return this.canvasAdapter.exportCanvas(canvas, {
      sessionId,
      frameId,
      mimeType: this.options.outputMimeType ?? "image/png",
      quality: this.options.outputQuality,
    });
  }
}
TS

echo ""
echo "Creating GIF generator skeleton..."

write_file "packages/image-engine/src/gif/gif.types.ts" <<'TS'
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
TS

write_file "packages/image-engine/src/gif/mock-gif-renderer.ts" <<'TS'
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
TS

write_file "packages/image-engine/src/gif/gif-generator.ts" <<'TS'
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
TS

echo ""
echo "Creating QR and download URL builder..."

write_file "packages/image-engine/src/qr/download-url-builder.ts" <<'TS'
import { DOWNLOAD_PAGE_QUERY_PARAM } from "@corra/shared";
import { appendQueryParams, normalizeBaseUrl } from "../utils/url";

export interface BuildDownloadUrlInput {
  baseUrl: string;
  photoId: string;
  sessionId?: string;
  frameId?: string;
  downloadToken?: string;
}

export function buildDownloadUrl(input: BuildDownloadUrlInput): string {
  const baseUrl = normalizeBaseUrl(input.baseUrl);

  if (!input.photoId.trim()) {
    throw new Error("Photo ID is required to build download URL.");
  }

  return appendQueryParams(baseUrl, {
    [DOWNLOAD_PAGE_QUERY_PARAM]: input.photoId.trim(),
    sessionId: input.sessionId,
    frameId: input.frameId,
    token: input.downloadToken,
  });
}
TS

write_file "packages/image-engine/src/qr/qr-code.types.ts" <<'TS'
export interface QrCodeImage {
  content: string;
  dataUrl: string;
  mimeType: "image/svg+xml" | "image/png";
}

export interface QrCodeGeneratorOptions {
  size: number;
  margin: number;
  darkColor: string;
  lightColor: string;
}
TS

write_file "packages/image-engine/src/qr/svg-placeholder-qr.ts" <<'TS'
function escapeXml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;")
    .replaceAll("'", "&apos;");
}

function encodeSvgToDataUrl(svg: string): string {
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
}

export function generatePlaceholderQrSvgDataUrl(
  content: string,
  size: number,
): string {
  const safeContent = escapeXml(content);
  const cell = size / 8;

  const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect width="100%" height="100%" fill="white"/>
  <rect x="${cell}" y="${cell}" width="${cell * 2}" height="${cell * 2}" fill="black"/>
  <rect x="${cell * 5}" y="${cell}" width="${cell * 2}" height="${cell * 2}" fill="black"/>
  <rect x="${cell}" y="${cell * 5}" width="${cell * 2}" height="${cell * 2}" fill="black"/>
  <rect x="${cell * 4}" y="${cell * 4}" width="${cell}" height="${cell}" fill="black"/>
  <rect x="${cell * 5}" y="${cell * 5}" width="${cell}" height="${cell}" fill="black"/>
  <rect x="${cell * 6}" y="${cell * 4}" width="${cell}" height="${cell}" fill="black"/>
  <text x="50%" y="${size - cell}" text-anchor="middle" font-family="Arial, sans-serif" font-size="${Math.max(8, cell / 2)}" fill="black">QR PLACEHOLDER</text>
  <desc>${safeContent}</desc>
</svg>`.trim();

  return encodeSvgToDataUrl(svg);
}
TS

write_file "packages/image-engine/src/qr/qr-code-generator.ts" <<'TS'
import type { QrCodePort } from "@corra/booth-core";
import { generatePlaceholderQrSvgDataUrl } from "./svg-placeholder-qr";
import type { QrCodeGeneratorOptions, QrCodeImage } from "./qr-code.types";

const DEFAULT_OPTIONS: QrCodeGeneratorOptions = {
  size: 512,
  margin: 24,
  darkColor: "#000000",
  lightColor: "#ffffff",
};

export class PlaceholderQrCodeGenerator implements QrCodePort {
  constructor(private readonly options: Partial<QrCodeGeneratorOptions> = {}) {}

  async generateDataUrl(content: string): Promise<string> {
    const qr = await this.generate(content);
    return qr.dataUrl;
  }

  async generate(content: string): Promise<QrCodeImage> {
    if (!content.trim()) {
      throw new Error("QR content is required.");
    }

    const options = {
      ...DEFAULT_OPTIONS,
      ...this.options,
    };

    return {
      content,
      dataUrl: generatePlaceholderQrSvgDataUrl(content, options.size),
      mimeType: "image/svg+xml",
    };
  }
}
TS

echo ""
echo "Creating image-engine facade..."

write_file "packages/image-engine/src/index.ts" <<'TS'
export * from "./canvas/canvas.types";
export * from "./canvas/image-source";
export * from "./canvas/in-memory-canvas.adapter";

export * from "./composer/slot-transform";
export * from "./composer/layer-engine";
export * from "./composer/frame-composer";

export * from "./gif/gif.types";
export * from "./gif/mock-gif-renderer";
export * from "./gif/gif-generator";

export * from "./qr/download-url-builder";
export * from "./qr/qr-code.types";
export * from "./qr/svg-placeholder-qr";
export * from "./qr/qr-code-generator";

export * from "./utils/asset-id";
export * from "./utils/mime";
export * from "./utils/url";
TS

echo ""
echo "Creating docs..."

write_file "docs/image-engine.md" <<'MD'
# Corra Booth Image Engine

Phase 3 creates the image-engine skeleton.

## Responsibility

The image engine is responsible for:

- Building composition layers
- Drawing the template background at the bottom layer
- Drawing raw captures above the template
- Transforming layout slots into draw operations
- Exporting the final frame
- Generating GIF assets
- Building download URLs
- Generating QR code data URLs

## Layering Rule

Strict order:

1. Template/background image
2. Raw capture 1
3. Raw capture 2
4. Raw capture 3
5. Raw capture etc.

The template is a full background image. It is not assumed to be a transparent PNG.

## Current Phase

This phase uses placeholder/mock adapters:

- `InMemoryCanvasAdapter`
- `MockGifRenderer`
- `PlaceholderQrCodeGenerator`

These exist so the app can typecheck and the architecture can be tested before adding heavy native dependencies.

## Later Implementation Options

For Windows/Electron production:

- `sharp`
- `canvas`
- `jimp`
- native printer pipeline
- FFmpeg/GIF renderer if needed

For browser/mobile:

- HTML Canvas
- OffscreenCanvas
- WebCodecs where available
- Capacitor filesystem for local assets

## Important Boundary

The image engine must not depend on Electron, Canon SDK, Sony SDK, DNP SDK, Mayar, or Supabase service-role keys.
MD

echo ""
echo "Running typecheck..."

pnpm --filter @corra/shared typecheck
pnpm --filter @corra/booth-core typecheck
pnpm --filter @corra/image-engine typecheck

echo ""
echo "========================================"
echo " Phase 3 completed."
echo "========================================"
echo ""
echo "Recommended git commit:"
echo "  git add ."
echo "  git commit -m \"feat: add image engine skeleton\""
echo ""
