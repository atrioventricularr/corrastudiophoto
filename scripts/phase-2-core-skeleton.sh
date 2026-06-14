#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 2 Core Skeleton"
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
[ -d "packages/booth-core/src" ] || fail "packages/booth-core/src not found. Run Phase 0 first."

echo "Repository structure OK."

echo ""
echo "Creating backup..."

BACKUP_DIR="packages/.phase-backups/phase-2-core-before-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

cp -a packages/shared/src "$BACKUP_DIR/shared-src"
cp -a packages/booth-core/src "$BACKUP_DIR/booth-core-src"

echo "Backup stored at: $BACKUP_DIR"

echo ""
echo "Creating shared package structure..."

create_dir "packages/shared/src/types"
create_dir "packages/shared/src/constants"
create_dir "packages/shared/src/validators"

write_file "packages/shared/src/types/common.types.ts" <<'TS'
export type CorraId = string;

export type ISODateTimeString = string;

export type UrlString = string;

export type Nullable<T> = T | null;

export type Maybe<T> = T | undefined;

export type ResultSuccess<T> = {
  ok: true;
  data: T;
};

export type ResultFailure = {
  ok: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
};

export type AppResult<T> = ResultSuccess<T> | ResultFailure;
TS

write_file "packages/shared/src/types/booth.types.ts" <<'TS'
import type { CorraId, ISODateTimeString } from "./common.types";

export type BoothRunMode = "SESSION" | "SINGLE";

export type BoothSessionStatus =
  | "IDLE"
  | "SELECTING_LAYOUT"
  | "SELECTING_TEMPLATE"
  | "WAITING_PAYMENT"
  | "CAPTURING"
  | "COMPOSING"
  | "UPLOADING"
  | "PRINTING"
  | "COMPLETED"
  | "FAILED"
  | "CANCELLED";

export type CaptureStatus = "PENDING" | "CAPTURED" | "FAILED";

export type FrameStatus =
  | "PENDING"
  | "CAPTURING"
  | "COMPOSING"
  | "COMPOSED"
  | "UPLOADED"
  | "PRINTED"
  | "FAILED";

export type PhotoSessionId = CorraId;

export interface PhotoSessionSummary {
  id: PhotoSessionId;
  mode: BoothRunMode;
  status: BoothSessionStatus;
  frameCount: number;
  captureCount: number;
  startedAt: ISODateTimeString;
  completedAt: ISODateTimeString | null;
}
TS

write_file "packages/shared/src/types/asset.types.ts" <<'TS'
import type { CorraId, ISODateTimeString, UrlString } from "./common.types";

export type PhotoAssetKind = "RAW_CAPTURE" | "FINAL_FRAME" | "GIF";

export type PhotoAssetStorageStatus =
  | "LOCAL_ONLY"
  | "UPLOADING"
  | "UPLOADED"
  | "FAILED";

export interface PhotoAsset {
  id: CorraId;
  sessionId: CorraId;
  kind: PhotoAssetKind;
  localPath?: string;
  storageBucket?: string;
  storagePath?: string;
  publicUrl?: UrlString;
  mimeType: string;
  width?: number;
  height?: number;
  sizeBytes?: number;
  status: PhotoAssetStorageStatus;
  createdAt: ISODateTimeString;
}
TS

write_file "packages/shared/src/types/layout.types.ts" <<'TS'
import type { CorraId, ISODateTimeString } from "./common.types";

export type LayoutSlotCount = 2 | 3 | 4 | 5 | 6 | 7 | 8;

export type SlotObjectFit = "cover" | "contain";

export interface LayoutSlot {
  slotIndex: number;
  x: number;
  y: number;
  width: number;
  height: number;
  rotationDeg: number;
  borderRadius: number;
  objectFit: SlotObjectFit;
}

export interface BoothLayout {
  id: CorraId;
  name: string;
  canvasWidth: number;
  canvasHeight: number;
  slotCount: LayoutSlotCount;
  slots: LayoutSlot[];
  isActive: boolean;
  createdAt: ISODateTimeString;
  updatedAt: ISODateTimeString;
}
TS

write_file "packages/shared/src/types/template.types.ts" <<'TS'
import type { CorraId, ISODateTimeString } from "./common.types";

export interface BoothTemplate {
  id: CorraId;
  name: string;
  layoutId: CorraId;
  backgroundAssetId: CorraId | null;
  backgroundLocalPath?: string;
  backgroundStoragePath?: string;
  backgroundPublicUrl?: string;
  canvasWidth: number;
  canvasHeight: number;
  isActive: boolean;
  createdAt: ISODateTimeString;
  updatedAt: ISODateTimeString;
}
TS

write_file "packages/shared/src/types/license.types.ts" <<'TS'
import type { CorraId, ISODateTimeString } from "./common.types";

export type LicenseStatus =
  | "PENDING"
  | "ACTIVE"
  | "EXPIRED"
  | "SUSPENDED"
  | "CANCELLED";

export type LicenseBillingCycle = "MONTHLY" | "YEARLY" | "TRIAL" | "LIFETIME";

export interface LicenseRecord {
  id: CorraId;
  licenseCode: string;
  ownerEmail: string;
  ownerName?: string;
  status: LicenseStatus;
  billingCycle: LicenseBillingCycle;
  mayarCustomerId?: string;
  mayarTransactionId?: string;
  mayarSubscriptionId?: string;
  activeFrom: ISODateTimeString;
  activeUntil: ISODateTimeString | null;
  maxDevices: number;
  createdAt: ISODateTimeString;
  updatedAt: ISODateTimeString;
}

export interface LicenseVerificationResult {
  license: LicenseRecord | null;
  isValid: boolean;
  reason:
    | "ACTIVE"
    | "NOT_FOUND"
    | "EXPIRED"
    | "SUSPENDED"
    | "CANCELLED"
    | "PENDING"
    | "DEVICE_LIMIT_REACHED";
}
TS

write_file "packages/shared/src/types/hardware.types.ts" <<'TS'
export type CameraProvider = "CANON_EDSDK" | "SONY_SDK" | "WEBCAM" | "MOCK";

export type PrinterProvider =
  | "DNP"
  | "THERMAL"
  | "EPSON_WIFI"
  | "CANON_SELPHY"
  | "WINDOWS_SPOOLER"
  | "MOCK";

export type HardwareConnectionStatus =
  | "DISCONNECTED"
  | "CONNECTING"
  | "CONNECTED"
  | "ERROR";

export interface CameraStatus {
  provider: CameraProvider;
  status: HardwareConnectionStatus;
  deviceName?: string;
  batteryLevel?: number;
  errorMessage?: string;
}

export interface PrinterStatus {
  provider: PrinterProvider;
  status: HardwareConnectionStatus;
  deviceName?: string;
  paperRemaining?: number;
  errorMessage?: string;
}
TS

write_file "packages/shared/src/constants/booth.constants.ts" <<'TS'
export const MIN_CAPTURE_PER_FRAME = 2;
export const MAX_CAPTURE_PER_FRAME = 8;

export const SUPPORTED_LAYOUT_SLOT_COUNTS = [2, 3, 4, 5, 6, 7, 8] as const;

export const DEFAULT_SESSION_DURATION_SECONDS = 300;

export const DEFAULT_SINGLE_MODE_FRAME_COUNT = 1;
TS

write_file "packages/shared/src/constants/storage.constants.ts" <<'TS'
export const STORAGE_BUCKETS = {
  RAW_PHOTOS: "raw-photos",
  FINAL_FRAMES: "final-frames",
  GIFS: "gifs",
  TEMPLATES: "templates",
  QRIS: "qris",
} as const;

export const DOWNLOAD_PAGE_QUERY_PARAM = "photoId";
TS

write_file "packages/shared/src/validators/layout.validator.ts" <<'TS'
import {
  MAX_CAPTURE_PER_FRAME,
  MIN_CAPTURE_PER_FRAME,
} from "../constants/booth.constants";
import type { BoothLayout } from "../types/layout.types";

export function validateBoothLayout(layout: BoothLayout): string[] {
  const errors: string[] = [];

  if (!layout.id) errors.push("Layout ID is required.");
  if (!layout.name) errors.push("Layout name is required.");

  if (layout.canvasWidth <= 0) {
    errors.push("Canvas width must be greater than zero.");
  }

  if (layout.canvasHeight <= 0) {
    errors.push("Canvas height must be greater than zero.");
  }

  if (
    layout.slotCount < MIN_CAPTURE_PER_FRAME ||
    layout.slotCount > MAX_CAPTURE_PER_FRAME
  ) {
    errors.push(
      `Layout slot count must be between ${MIN_CAPTURE_PER_FRAME} and ${MAX_CAPTURE_PER_FRAME}.`,
    );
  }

  if (layout.slots.length !== layout.slotCount) {
    errors.push("Slot count does not match slots length.");
  }

  const seenIndexes = new Set<number>();

  for (const slot of layout.slots) {
    if (seenIndexes.has(slot.slotIndex)) {
      errors.push(`Duplicate slot index: ${slot.slotIndex}.`);
    }

    seenIndexes.add(slot.slotIndex);

    if (slot.width <= 0 || slot.height <= 0) {
      errors.push(`Slot ${slot.slotIndex} must have positive size.`);
    }

    if (slot.x < 0 || slot.y < 0) {
      errors.push(`Slot ${slot.slotIndex} cannot have negative position.`);
    }
  }

  return errors;
}

export function assertValidBoothLayout(layout: BoothLayout): void {
  const errors = validateBoothLayout(layout);

  if (errors.length > 0) {
    throw new Error(`Invalid booth layout: ${errors.join(" ")}`);
  }
}
TS

write_file "packages/shared/src/index.ts" <<'TS'
export * from "./types/common.types";
export * from "./types/booth.types";
export * from "./types/asset.types";
export * from "./types/layout.types";
export * from "./types/template.types";
export * from "./types/license.types";
export * from "./types/hardware.types";

export * from "./constants/booth.constants";
export * from "./constants/storage.constants";

export * from "./validators/layout.validator";
TS

echo ""
echo "Creating booth-core domain..."

create_dir "packages/booth-core/src/domain"
create_dir "packages/booth-core/src/use-cases"
create_dir "packages/booth-core/src/ports"
create_dir "packages/booth-core/src/state"

write_file "packages/booth-core/src/domain/booth-mode.ts" <<'TS'
export type SessionBoothMode = {
  type: "SESSION";
  durationSeconds: number;
  maxFrames: null;
};

export type SingleBoothMode = {
  type: "SINGLE";
  targetFrameCount: number;
  durationSeconds: null;
};

export type BoothMode = SessionBoothMode | SingleBoothMode;

export function isSessionMode(mode: BoothMode): mode is SessionBoothMode {
  return mode.type === "SESSION";
}

export function isSingleMode(mode: BoothMode): mode is SingleBoothMode {
  return mode.type === "SINGLE";
}

export function assertSessionMode(mode: BoothMode): asserts mode is SessionBoothMode {
  if (!isSessionMode(mode)) {
    throw new Error("Expected Session Mode. Session Mode must be timer-based.");
  }
}

export function assertSingleMode(mode: BoothMode): asserts mode is SingleBoothMode {
  if (!isSingleMode(mode)) {
    throw new Error("Expected Single Mode. Single Mode must be frame-count-based.");
  }
}
TS

write_file "packages/booth-core/src/domain/session-mode.ts" <<'TS'
import type { SessionBoothMode } from "./booth-mode";

export function createSessionMode(durationSeconds: number): SessionBoothMode {
  if (!Number.isInteger(durationSeconds) || durationSeconds <= 0) {
    throw new Error("Session Mode requires a positive countdown duration.");
  }

  return {
    type: "SESSION",
    durationSeconds,
    maxFrames: null,
  };
}
TS

write_file "packages/booth-core/src/domain/single-mode.ts" <<'TS'
import type { SingleBoothMode } from "./booth-mode";

export function createSingleMode(targetFrameCount: number): SingleBoothMode {
  if (!Number.isInteger(targetFrameCount) || targetFrameCount <= 0) {
    throw new Error("Single Mode requires a positive target frame count.");
  }

  return {
    type: "SINGLE",
    targetFrameCount,
    durationSeconds: null,
  };
}
TS

write_file "packages/booth-core/src/domain/capture.ts" <<'TS'
import type { CorraId, ISODateTimeString, PhotoAsset } from "@corra/shared";

export interface Capture {
  id: CorraId;
  sessionId: CorraId;
  frameId: CorraId;
  slotIndex: number;
  asset: PhotoAsset;
  capturedAt: ISODateTimeString;
}

export function createCapture(input: Capture): Capture {
  if (!input.id) throw new Error("Capture ID is required.");
  if (!input.sessionId) throw new Error("Session ID is required.");
  if (!input.frameId) throw new Error("Frame ID is required.");
  if (!Number.isInteger(input.slotIndex) || input.slotIndex < 0) {
    throw new Error("Capture slot index must be a non-negative integer.");
  }

  if (input.asset.kind !== "RAW_CAPTURE") {
    throw new Error("Capture asset must have kind RAW_CAPTURE.");
  }

  return input;
}
TS

write_file "packages/booth-core/src/domain/frame.ts" <<'TS'
import {
  MAX_CAPTURE_PER_FRAME,
  MIN_CAPTURE_PER_FRAME,
  type CorraId,
  type FrameStatus,
  type ISODateTimeString,
  type PhotoAsset,
} from "@corra/shared";

import type { Capture } from "./capture";

export interface Frame {
  id: CorraId;
  sessionId: CorraId;
  layoutId: CorraId;
  templateId: CorraId;
  captures: Capture[];
  finalAsset: PhotoAsset | null;
  gifAsset: PhotoAsset | null;
  status: FrameStatus;
  createdAt: ISODateTimeString;
  completedAt: ISODateTimeString | null;
}

export function assertValidCaptureCount(captureCount: number): void {
  if (
    !Number.isInteger(captureCount) ||
    captureCount < MIN_CAPTURE_PER_FRAME ||
    captureCount > MAX_CAPTURE_PER_FRAME
  ) {
    throw new Error(
      `A frame must contain ${MIN_CAPTURE_PER_FRAME}-${MAX_CAPTURE_PER_FRAME} captures.`,
    );
  }
}

export function createFrame(input: Frame): Frame {
  if (!input.id) throw new Error("Frame ID is required.");
  if (!input.sessionId) throw new Error("Session ID is required.");
  if (!input.layoutId) throw new Error("Layout ID is required.");
  if (!input.templateId) throw new Error("Template ID is required.");

  if (input.captures.length > 0) {
    assertValidCaptureCount(input.captures.length);
  }

  if (input.finalAsset && input.finalAsset.kind !== "FINAL_FRAME") {
    throw new Error("Frame final asset must have kind FINAL_FRAME.");
  }

  if (input.gifAsset && input.gifAsset.kind !== "GIF") {
    throw new Error("Frame GIF asset must have kind GIF.");
  }

  return input;
}
TS

write_file "packages/booth-core/src/domain/layout.ts" <<'TS'
import {
  assertValidBoothLayout,
  type BoothLayout,
  type LayoutSlot,
} from "@corra/shared";

export function createBoothLayout(layout: BoothLayout): BoothLayout {
  assertValidBoothLayout(layout);
  return layout;
}

export function getLayoutSlot(layout: BoothLayout, slotIndex: number): LayoutSlot {
  const slot = layout.slots.find((item) => item.slotIndex === slotIndex);

  if (!slot) {
    throw new Error(`Layout slot not found: ${slotIndex}.`);
  }

  return slot;
}
TS

write_file "packages/booth-core/src/domain/template.ts" <<'TS'
import type { BoothTemplate } from "@corra/shared";

export function createBoothTemplate(template: BoothTemplate): BoothTemplate {
  if (!template.id) throw new Error("Template ID is required.");
  if (!template.name) throw new Error("Template name is required.");
  if (!template.layoutId) throw new Error("Template layout ID is required.");

  if (template.canvasWidth <= 0 || template.canvasHeight <= 0) {
    throw new Error("Template canvas size must be positive.");
  }

  return template;
}
TS

write_file "packages/booth-core/src/domain/license.ts" <<'TS'
import type {
  ISODateTimeString,
  LicenseRecord,
  LicenseVerificationResult,
} from "@corra/shared";

export function isLicenseDateActive(
  activeFrom: ISODateTimeString,
  activeUntil: ISODateTimeString | null,
  now: Date = new Date(),
): boolean {
  const fromTime = new Date(activeFrom).getTime();

  if (Number.isNaN(fromTime)) {
    return false;
  }

  if (now.getTime() < fromTime) {
    return false;
  }

  if (!activeUntil) {
    return true;
  }

  const untilTime = new Date(activeUntil).getTime();

  if (Number.isNaN(untilTime)) {
    return false;
  }

  return now.getTime() <= untilTime;
}

export function verifyLicenseRecord(
  license: LicenseRecord | null,
  now: Date = new Date(),
): LicenseVerificationResult {
  if (!license) {
    return {
      license: null,
      isValid: false,
      reason: "NOT_FOUND",
    };
  }

  if (license.status === "SUSPENDED") {
    return {
      license,
      isValid: false,
      reason: "SUSPENDED",
    };
  }

  if (license.status === "CANCELLED") {
    return {
      license,
      isValid: false,
      reason: "CANCELLED",
    };
  }

  if (license.status === "PENDING") {
    return {
      license,
      isValid: false,
      reason: "PENDING",
    };
  }

  if (!isLicenseDateActive(license.activeFrom, license.activeUntil, now)) {
    return {
      license,
      isValid: false,
      reason: "EXPIRED",
    };
  }

  return {
    license,
    isValid: true,
    reason: "ACTIVE",
  };
}
TS

echo ""
echo "Creating booth-core ports..."

write_file "packages/booth-core/src/ports/camera.port.ts" <<'TS'
import type { CameraStatus, PhotoAsset } from "@corra/shared";

export interface CameraPort {
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  getStatus(): Promise<CameraStatus>;
  startPreview(): Promise<void>;
  stopPreview(): Promise<void>;
  captureRawPhoto(sessionId: string, frameId: string, slotIndex: number): Promise<PhotoAsset>;
}
TS

write_file "packages/booth-core/src/ports/printer.port.ts" <<'TS'
import type { PhotoAsset, PrinterStatus } from "@corra/shared";

export interface PrintJobRequest {
  frameAsset: PhotoAsset;
  copies: number;
}

export interface PrintJobResult {
  jobId: string;
  accepted: boolean;
  message?: string;
}

export interface PrinterPort {
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  getStatus(): Promise<PrinterStatus>;
  printFrame(request: PrintJobRequest): Promise<PrintJobResult>;
}
TS

write_file "packages/booth-core/src/ports/storage.port.ts" <<'TS'
import type { PhotoAsset } from "@corra/shared";

export interface UploadAssetRequest {
  asset: PhotoAsset;
  localPath: string;
}

export interface StoragePort {
  uploadAsset(request: UploadAssetRequest): Promise<PhotoAsset>;
  getPublicUrl(asset: PhotoAsset): Promise<string>;
}
TS

write_file "packages/booth-core/src/ports/license-repository.port.ts" <<'TS'
import type { LicenseRecord } from "@corra/shared";

export interface LicenseRepositoryPort {
  findByCode(licenseCode: string): Promise<LicenseRecord | null>;
  bindDevice?(licenseCode: string, deviceId: string): Promise<void>;
}
TS

write_file "packages/booth-core/src/ports/transaction-log.port.ts" <<'TS'
export interface TransactionLogEntry {
  id: string;
  sessionId?: string;
  type:
    | "LICENSE_VERIFIED"
    | "PHOTO_SESSION_STARTED"
    | "PHOTO_CAPTURED"
    | "FRAME_COMPOSED"
    | "ASSET_UPLOADED"
    | "PRINT_REQUESTED"
    | "ERROR";
  message: string;
  metadata?: Record<string, unknown>;
  createdAt: string;
}

export interface TransactionLogPort {
  append(entry: TransactionLogEntry): Promise<void>;
}
TS

write_file "packages/booth-core/src/ports/qr-generator.port.ts" <<'TS'
export interface QrCodePort {
  generateDataUrl(content: string): Promise<string>;
}
TS

write_file "packages/booth-core/src/ports/local-settings.port.ts" <<'TS'
export interface LocalSettingsPort<TSettings> {
  get(): Promise<TSettings>;
  set(settings: TSettings): Promise<void>;
  patch(settings: Partial<TSettings>): Promise<void>;
}
TS

write_file "packages/booth-core/src/ports/image-composer.port.ts" <<'TS'
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
TS

write_file "packages/booth-core/src/ports/gif-generator.port.ts" <<'TS'
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
TS

echo ""
echo "Creating booth-core use cases..."

write_file "packages/booth-core/src/use-cases/start-session.usecase.ts" <<'TS'
import { createSessionMode } from "../domain/session-mode";

export interface StartSessionInput {
  durationSeconds: number;
}

export function startSessionUseCase(input: StartSessionInput) {
  return createSessionMode(input.durationSeconds);
}
TS

write_file "packages/booth-core/src/use-cases/start-single.usecase.ts" <<'TS'
import { createSingleMode } from "../domain/single-mode";

export interface StartSingleInput {
  targetFrameCount: number;
}

export function startSingleUseCase(input: StartSingleInput) {
  return createSingleMode(input.targetFrameCount);
}
TS

write_file "packages/booth-core/src/use-cases/capture-photo.usecase.ts" <<'TS'
import { createCapture } from "../domain/capture";
import type { CameraPort } from "../ports/camera.port";

export interface CapturePhotoInput {
  sessionId: string;
  frameId: string;
  slotIndex: number;
  captureId: string;
  capturedAt: string;
}

export async function capturePhotoUseCase(
  camera: CameraPort,
  input: CapturePhotoInput,
) {
  const asset = await camera.captureRawPhoto(
    input.sessionId,
    input.frameId,
    input.slotIndex,
  );

  return createCapture({
    id: input.captureId,
    sessionId: input.sessionId,
    frameId: input.frameId,
    slotIndex: input.slotIndex,
    asset,
    capturedAt: input.capturedAt,
  });
}
TS

write_file "packages/booth-core/src/use-cases/compose-frame.usecase.ts" <<'TS'
import { assertValidCaptureCount } from "../domain/frame";
import type {
  ComposeFrameRequest,
  ImageComposerPort,
} from "../ports/image-composer.port";

export async function composeFrameUseCase(
  composer: ImageComposerPort,
  request: ComposeFrameRequest,
) {
  assertValidCaptureCount(request.captures.length);
  return composer.composeFrame(request);
}
TS

write_file "packages/booth-core/src/use-cases/generate-gif.usecase.ts" <<'TS'
import type {
  GenerateGifRequest,
  GifGeneratorPort,
} from "../ports/gif-generator.port";

export async function generateGifUseCase(
  gifGenerator: GifGeneratorPort,
  request: GenerateGifRequest,
) {
  if (request.captures.length <= 0) {
    throw new Error("Cannot generate GIF without captures.");
  }

  return gifGenerator.generateGif(request);
}
TS

write_file "packages/booth-core/src/use-cases/upload-assets.usecase.ts" <<'TS'
import type { PhotoAsset } from "@corra/shared";
import type { StoragePort } from "../ports/storage.port";

export interface UploadAssetsInput {
  assets: Array<{
    asset: PhotoAsset;
    localPath: string;
  }>;
}

export async function uploadAssetsUseCase(
  storage: StoragePort,
  input: UploadAssetsInput,
): Promise<PhotoAsset[]> {
  const uploadedAssets: PhotoAsset[] = [];

  for (const item of input.assets) {
    const uploaded = await storage.uploadAsset({
      asset: item.asset,
      localPath: item.localPath,
    });

    uploadedAssets.push(uploaded);
  }

  return uploadedAssets;
}
TS

write_file "packages/booth-core/src/use-cases/print-frame.usecase.ts" <<'TS'
import type { PhotoAsset } from "@corra/shared";
import type { PrinterPort } from "../ports/printer.port";

export interface PrintFrameInput {
  frameAsset: PhotoAsset;
  copies: number;
}

export async function printFrameUseCase(
  printer: PrinterPort,
  input: PrintFrameInput,
) {
  if (input.frameAsset.kind !== "FINAL_FRAME") {
    throw new Error("Only FINAL_FRAME assets can be printed.");
  }

  if (!Number.isInteger(input.copies) || input.copies <= 0) {
    throw new Error("Print copies must be a positive integer.");
  }

  return printer.printFrame({
    frameAsset: input.frameAsset,
    copies: input.copies,
  });
}
TS

write_file "packages/booth-core/src/use-cases/verify-license.usecase.ts" <<'TS'
import { verifyLicenseRecord } from "../domain/license";
import type { LicenseRepositoryPort } from "../ports/license-repository.port";

export interface VerifyLicenseInput {
  licenseCode: string;
  now?: Date;
}

export async function verifyLicenseUseCase(
  licenseRepository: LicenseRepositoryPort,
  input: VerifyLicenseInput,
) {
  if (!input.licenseCode.trim()) {
    throw new Error("License code is required.");
  }

  const license = await licenseRepository.findByCode(input.licenseCode.trim());

  return verifyLicenseRecord(license, input.now ?? new Date());
}
TS

echo ""
echo "Creating booth-core state machine skeleton..."

write_file "packages/booth-core/src/state/booth-state.ts" <<'TS'
import type { BoothSessionStatus } from "@corra/shared";
import type { BoothMode } from "../domain/booth-mode";
import type { Frame } from "../domain/frame";

export interface BoothState {
  status: BoothSessionStatus;
  mode: BoothMode | null;
  currentSessionId: string | null;
  frames: Frame[];
  errorMessage: string | null;
}

export function createInitialBoothState(): BoothState {
  return {
    status: "IDLE",
    mode: null,
    currentSessionId: null,
    frames: [],
    errorMessage: null,
  };
}
TS

write_file "packages/booth-core/src/state/booth-events.ts" <<'TS'
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
TS

write_file "packages/booth-core/src/state/booth-machine.ts" <<'TS'
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
TS

write_file "packages/booth-core/src/index.ts" <<'TS'
export * from "./domain/booth-mode";
export * from "./domain/session-mode";
export * from "./domain/single-mode";
export * from "./domain/capture";
export * from "./domain/frame";
export * from "./domain/layout";
export * from "./domain/template";
export * from "./domain/license";

export * from "./ports/camera.port";
export * from "./ports/printer.port";
export * from "./ports/storage.port";
export * from "./ports/license-repository.port";
export * from "./ports/transaction-log.port";
export * from "./ports/qr-generator.port";
export * from "./ports/local-settings.port";
export * from "./ports/image-composer.port";
export * from "./ports/gif-generator.port";

export * from "./use-cases/start-session.usecase";
export * from "./use-cases/start-single.usecase";
export * from "./use-cases/capture-photo.usecase";
export * from "./use-cases/compose-frame.usecase";
export * from "./use-cases/generate-gif.usecase";
export * from "./use-cases/upload-assets.usecase";
export * from "./use-cases/print-frame.usecase";
export * from "./use-cases/verify-license.usecase";

export * from "./state/booth-state";
export * from "./state/booth-events";
export * from "./state/booth-machine";
TS

echo ""
echo "Updating docs..."

write_file "docs/core-domain.md" <<'MD'
# Corra Booth Core Domain

Phase 2 creates the first business-logic skeleton.

## Strict Rules

### Session Mode

Session Mode is timer-based.

The user can generate as many frames as possible while the countdown timer is active.

### Single Mode

Single Mode is frame-count-based.

The user generates a fixed number of frames. Single Mode does not use a countdown timer.

## Image Terms

### Capture

A Capture is one raw photo taken from the camera.

### Frame

A Frame is the final composed image.

One Frame contains 2-8 Captures depending on the selected layout.

### Template

A Template is a full background image.

The Template is placed at the bottom layer. Raw Captures are drawn above the Template based on layout coordinates.

## Platform Boundary

The core package does not know Canon, Sony, DNP, Epson, Supabase, Electron, or Windows.

It only knows ports/interfaces:

- CameraPort
- PrinterPort
- StoragePort
- LicenseRepositoryPort
- ImageComposerPort
- GifGeneratorPort

Concrete implementations come later.
MD

echo ""
echo "Running typecheck for shared and booth-core..."

pnpm --filter @corra/shared typecheck
pnpm --filter @corra/booth-core typecheck

echo ""
echo "========================================"
echo " Phase 2 completed."
echo "========================================"
echo ""
echo "Recommended git commit:"
echo "  git add ."
echo "  git commit -m \"feat: add booth core domain skeleton\""
echo ""
