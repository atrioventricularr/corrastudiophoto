#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 4 Data Access"
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
[ -d "packages/image-engine/src" ] || fail "packages/image-engine/src not found. Run Phase 3 first."
[ -d "packages/data-access/src" ] || fail "packages/data-access/src not found. Run Phase 0 first."

echo "Repository structure OK."

echo ""
echo "Creating backup..."

BACKUP_DIR="packages/.phase-backups/phase-4-data-access-before-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

cp -a packages/data-access/src "$BACKUP_DIR/data-access-src"

echo "Backup stored at: $BACKUP_DIR"

echo ""
echo "Creating data-access folders..."

create_dir "packages/data-access/src/config"
create_dir "packages/data-access/src/supabase"
create_dir "packages/data-access/src/supabase/mappers"
create_dir "packages/data-access/src/supabase/repositories"
create_dir "packages/data-access/src/local"
create_dir "packages/data-access/src/local/repositories"
create_dir "packages/data-access/src/offline"
create_dir "packages/data-access/src/utils"

echo ""
echo "Updating data-access package.json..."

write_file "packages/data-access/package.json" <<'JSON'
{
  "name": "@corra/data-access",
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
    "@corra/shared": "workspace:*",
    "@supabase/supabase-js": "^2.47.10"
  },
  "devDependencies": {
    "typescript": "^5.7.2"
  }
}
JSON

write_file "packages/data-access/tsconfig.json" <<'JSON'
{
  "extends": "../../tsconfig.base.json",
  "include": ["src"]
}
JSON

echo ""
echo "Creating config files..."

write_file "packages/data-access/src/config/supabase-config.ts" <<'TS'
export interface SupabasePublicConfig {
  url: string;
  anonKey: string;
}

export interface SupabaseServerConfig {
  url: string;
  serviceRoleKey: string;
}

export function assertSupabasePublicConfig(
  config: SupabasePublicConfig,
): void {
  if (!config.url.trim()) {
    throw new Error("Supabase URL is required.");
  }

  if (!config.anonKey.trim()) {
    throw new Error("Supabase anon key is required.");
  }
}

export function assertSupabaseServerConfig(
  config: SupabaseServerConfig,
): void {
  if (!config.url.trim()) {
    throw new Error("Supabase URL is required.");
  }

  if (!config.serviceRoleKey.trim()) {
    throw new Error("Supabase service-role key is required.");
  }
}
TS

write_file "packages/data-access/src/config/runtime-env.ts" <<'TS'
import type {
  SupabasePublicConfig,
  SupabaseServerConfig,
} from "./supabase-config";

export function getSupabasePublicConfigFromViteEnv(): SupabasePublicConfig {
  const env = import.meta.env as Record<string, string | undefined>;

  return {
    url: env.VITE_SUPABASE_URL ?? "",
    anonKey: env.VITE_SUPABASE_ANON_KEY ?? "",
  };
}

export function getSupabaseServerConfigFromProcessEnv(): SupabaseServerConfig {
  const env =
    typeof process !== "undefined"
      ? (process.env as Record<string, string | undefined>)
      : {};

  return {
    url: env.SUPABASE_URL ?? env.VITE_SUPABASE_URL ?? "",
    serviceRoleKey: env.SUPABASE_SERVICE_ROLE_KEY ?? "",
  };
}
TS

echo ""
echo "Creating Supabase database types..."

write_file "packages/data-access/src/supabase/database.types.ts" <<'TS'
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface LicenseRow {
  id: string;
  license_code: string;
  owner_email: string;
  owner_name: string | null;
  status: "PENDING" | "ACTIVE" | "EXPIRED" | "SUSPENDED" | "CANCELLED";
  billing_cycle: "MONTHLY" | "YEARLY" | "TRIAL" | "LIFETIME";
  mayar_customer_id: string | null;
  mayar_transaction_id: string | null;
  mayar_subscription_id: string | null;
  active_from: string;
  active_until: string | null;
  max_devices: number;
  created_at: string;
  updated_at: string;
}

export type LicenseInsert = Omit<LicenseRow, "id" | "created_at" | "updated_at"> & {
  id?: string;
  created_at?: string;
  updated_at?: string;
};

export type LicenseUpdate = Partial<LicenseInsert>;

export interface BoothDeviceRow {
  id: string;
  license_id: string;
  device_fingerprint: string;
  device_name: string | null;
  platform: string;
  last_seen_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface TransactionRow {
  id: string;
  session_id: string | null;
  license_id: string | null;
  type: string;
  message: string;
  metadata: Json | null;
  created_at: string;
}

export interface PhotoSessionRow {
  id: string;
  license_id: string | null;
  device_id: string | null;
  mode: "SESSION" | "SINGLE";
  status: string;
  frame_count: number;
  capture_count: number;
  started_at: string;
  completed_at: string | null;
  metadata: Json | null;
  created_at: string;
  updated_at: string;
}

export interface PhotoAssetRow {
  id: string;
  session_id: string;
  frame_id: string | null;
  kind: "RAW_CAPTURE" | "FINAL_FRAME" | "GIF";
  storage_bucket: string | null;
  storage_path: string | null;
  public_url: string | null;
  mime_type: string;
  width: number | null;
  height: number | null;
  size_bytes: number | null;
  created_at: string;
}

export interface TemplateRow {
  id: string;
  layout_id: string;
  name: string;
  background_storage_path: string | null;
  background_public_url: string | null;
  canvas_width: number;
  canvas_height: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface LayoutRow {
  id: string;
  name: string;
  canvas_width: number;
  canvas_height: number;
  slot_count: number;
  slots: Json;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Database {
  public: {
    Tables: {
      licenses: {
        Row: LicenseRow;
        Insert: LicenseInsert;
        Update: LicenseUpdate;
      };
      booth_devices: {
        Row: BoothDeviceRow;
        Insert: Partial<BoothDeviceRow>;
        Update: Partial<BoothDeviceRow>;
      };
      transactions: {
        Row: TransactionRow;
        Insert: Partial<TransactionRow>;
        Update: Partial<TransactionRow>;
      };
      photo_sessions: {
        Row: PhotoSessionRow;
        Insert: Partial<PhotoSessionRow>;
        Update: Partial<PhotoSessionRow>;
      };
      photo_assets: {
        Row: PhotoAssetRow;
        Insert: Partial<PhotoAssetRow>;
        Update: Partial<PhotoAssetRow>;
      };
      templates: {
        Row: TemplateRow;
        Insert: Partial<TemplateRow>;
        Update: Partial<TemplateRow>;
      };
      layouts: {
        Row: LayoutRow;
        Insert: Partial<LayoutRow>;
        Update: Partial<LayoutRow>;
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
}
TS

echo ""
echo "Creating Supabase client factory..."

write_file "packages/data-access/src/supabase/supabase-client.ts" <<'TS'
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import {
  assertSupabasePublicConfig,
  assertSupabaseServerConfig,
  type SupabasePublicConfig,
  type SupabaseServerConfig,
} from "../config/supabase-config";
import type { Database } from "./database.types";

export type CorraSupabaseClient = SupabaseClient<Database>;

export function createSupabaseBrowserClient(
  config: SupabasePublicConfig,
): CorraSupabaseClient {
  assertSupabasePublicConfig(config);

  return createClient<Database>(config.url, config.anonKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  });
}

export function createSupabaseServerClient(
  config: SupabaseServerConfig,
): CorraSupabaseClient {
  assertSupabaseServerConfig(config);

  return createClient<Database>(config.url, config.serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}
TS

echo ""
echo "Creating Supabase mappers..."

write_file "packages/data-access/src/supabase/mappers/license.mapper.ts" <<'TS'
import type { LicenseRecord } from "@corra/shared";
import type { LicenseRow } from "../database.types";

export function mapLicenseRowToRecord(row: LicenseRow): LicenseRecord {
  return {
    id: row.id,
    licenseCode: row.license_code,
    ownerEmail: row.owner_email,
    ownerName: row.owner_name ?? undefined,
    status: row.status,
    billingCycle: row.billing_cycle,
    mayarCustomerId: row.mayar_customer_id ?? undefined,
    mayarTransactionId: row.mayar_transaction_id ?? undefined,
    mayarSubscriptionId: row.mayar_subscription_id ?? undefined,
    activeFrom: row.active_from,
    activeUntil: row.active_until,
    maxDevices: row.max_devices,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}
TS

write_file "packages/data-access/src/supabase/mappers/photo-asset.mapper.ts" <<'TS'
import type { PhotoAsset, PhotoAssetKind } from "@corra/shared";
import type { PhotoAssetRow } from "../database.types";

export function mapPhotoAssetRowToAsset(row: PhotoAssetRow): PhotoAsset {
  return {
    id: row.id,
    sessionId: row.session_id,
    kind: row.kind as PhotoAssetKind,
    storageBucket: row.storage_bucket ?? undefined,
    storagePath: row.storage_path ?? undefined,
    publicUrl: row.public_url ?? undefined,
    mimeType: row.mime_type,
    width: row.width ?? undefined,
    height: row.height ?? undefined,
    sizeBytes: row.size_bytes ?? undefined,
    status: row.storage_path ? "UPLOADED" : "LOCAL_ONLY",
    createdAt: row.created_at,
  };
}

export function mapPhotoAssetToInsert(asset: PhotoAsset): Partial<PhotoAssetRow> {
  return {
    id: asset.id,
    session_id: asset.sessionId,
    kind: asset.kind,
    storage_bucket: asset.storageBucket ?? null,
    storage_path: asset.storagePath ?? null,
    public_url: asset.publicUrl ?? null,
    mime_type: asset.mimeType,
    width: asset.width ?? null,
    height: asset.height ?? null,
    size_bytes: asset.sizeBytes ?? null,
    created_at: asset.createdAt,
  };
}
TS

echo ""
echo "Creating Supabase repositories..."

write_file "packages/data-access/src/supabase/repositories/supabase-license.repository.ts" <<'TS'
import type { LicenseRepositoryPort } from "@corra/booth-core";
import type { LicenseRecord } from "@corra/shared";
import { mapLicenseRowToRecord } from "../mappers/license.mapper";
import type { CorraSupabaseClient } from "../supabase-client";

export class SupabaseLicenseRepository implements LicenseRepositoryPort {
  constructor(private readonly client: CorraSupabaseClient) {}

  async findByCode(licenseCode: string): Promise<LicenseRecord | null> {
    const normalizedCode = licenseCode.trim();

    if (!normalizedCode) {
      return null;
    }

    const { data, error } = await this.client
      .from("licenses")
      .select("*")
      .eq("license_code", normalizedCode)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to find license: ${error.message}`);
    }

    return data ? mapLicenseRowToRecord(data) : null;
  }

  async bindDevice(licenseCode: string, deviceId: string): Promise<void> {
    const license = await this.findByCode(licenseCode);

    if (!license) {
      throw new Error("Cannot bind device because license was not found.");
    }

    const { error } = await this.client.from("booth_devices").upsert({
      id: deviceId,
      license_id: license.id,
      device_fingerprint: deviceId,
      platform: "WINDOWS_ELECTRON",
      last_seen_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    if (error) {
      throw new Error(`Failed to bind device: ${error.message}`);
    }
  }
}
TS

write_file "packages/data-access/src/supabase/repositories/supabase-storage.repository.ts" <<'TS'
import type { StoragePort, UploadAssetRequest } from "@corra/booth-core";
import {
  STORAGE_BUCKETS,
  type PhotoAsset,
  type PhotoAssetKind,
} from "@corra/shared";
import type { CorraSupabaseClient } from "../supabase-client";

function bucketForAssetKind(kind: PhotoAssetKind): string {
  switch (kind) {
    case "RAW_CAPTURE":
      return STORAGE_BUCKETS.RAW_PHOTOS;
    case "FINAL_FRAME":
      return STORAGE_BUCKETS.FINAL_FRAMES;
    case "GIF":
      return STORAGE_BUCKETS.GIFS;
    default: {
      const exhaustiveCheck: never = kind;
      return exhaustiveCheck;
    }
  }
}

function extensionFromMimeType(mimeType: string): string {
  switch (mimeType) {
    case "image/png":
      return "png";
    case "image/jpeg":
      return "jpg";
    case "image/webp":
      return "webp";
    case "image/gif":
      return "gif";
    default:
      return "bin";
  }
}

function createStoragePath(asset: PhotoAsset): string {
  const extension = extensionFromMimeType(asset.mimeType);
  return `${asset.sessionId}/${asset.id}.${extension}`;
}

async function resolveUploadBody(localPath: string): Promise<Blob> {
  if (
    localPath.startsWith("data:") ||
    localPath.startsWith("blob:") ||
    localPath.startsWith("http://") ||
    localPath.startsWith("https://")
  ) {
    const response = await fetch(localPath);

    if (!response.ok) {
      throw new Error(`Failed to fetch upload body from ${localPath}.`);
    }

    return response.blob();
  }

  throw new Error(
    "SupabaseStorageRepository cannot read filesystem paths directly. For Electron, create an Electron storage adapter that reads the file and passes binary data.",
  );
}

export class SupabaseStorageRepository implements StoragePort {
  constructor(private readonly client: CorraSupabaseClient) {}

  async uploadAsset(request: UploadAssetRequest): Promise<PhotoAsset> {
    const bucket = bucketForAssetKind(request.asset.kind);
    const storagePath = request.asset.storagePath ?? createStoragePath(request.asset);
    const body = await resolveUploadBody(request.localPath);

    const { error } = await this.client.storage
      .from(bucket)
      .upload(storagePath, body, {
        contentType: request.asset.mimeType,
        upsert: true,
      });

    if (error) {
      throw new Error(`Failed to upload asset: ${error.message}`);
    }

    const publicUrl = await this.getPublicUrl({
      ...request.asset,
      storageBucket: bucket,
      storagePath,
    });

    return {
      ...request.asset,
      storageBucket: bucket,
      storagePath,
      publicUrl,
      status: "UPLOADED",
    };
  }

  async getPublicUrl(asset: PhotoAsset): Promise<string> {
    if (!asset.storageBucket || !asset.storagePath) {
      throw new Error("Asset requires storage bucket and storage path.");
    }

    const { data } = this.client.storage
      .from(asset.storageBucket)
      .getPublicUrl(asset.storagePath);

    return data.publicUrl;
  }
}
TS

write_file "packages/data-access/src/supabase/repositories/supabase-photo.repository.ts" <<'TS'
import type { PhotoAsset, PhotoSessionSummary } from "@corra/shared";
import { mapPhotoAssetRowToAsset, mapPhotoAssetToInsert } from "../mappers/photo-asset.mapper";
import type { CorraSupabaseClient } from "../supabase-client";

export interface CreatePhotoSessionInput {
  id: string;
  licenseId?: string | null;
  deviceId?: string | null;
  mode: "SESSION" | "SINGLE";
  status: string;
  frameCount: number;
  captureCount: number;
  startedAt: string;
  metadata?: Record<string, unknown>;
}

export interface PhotoRepository {
  createSession(input: CreatePhotoSessionInput): Promise<PhotoSessionSummary>;
  updateSessionStatus(sessionId: string, status: string, completedAt?: string | null): Promise<void>;
  saveAsset(asset: PhotoAsset, frameId?: string | null): Promise<PhotoAsset>;
  listAssetsBySession(sessionId: string): Promise<PhotoAsset[]>;
}

export class SupabasePhotoRepository implements PhotoRepository {
  constructor(private readonly client: CorraSupabaseClient) {}

  async createSession(input: CreatePhotoSessionInput): Promise<PhotoSessionSummary> {
    const now = new Date().toISOString();

    const { data, error } = await this.client
      .from("photo_sessions")
      .insert({
        id: input.id,
        license_id: input.licenseId ?? null,
        device_id: input.deviceId ?? null,
        mode: input.mode,
        status: input.status,
        frame_count: input.frameCount,
        capture_count: input.captureCount,
        started_at: input.startedAt,
        completed_at: null,
        metadata: input.metadata ?? null,
        created_at: now,
        updated_at: now,
      })
      .select("*")
      .single();

    if (error) {
      throw new Error(`Failed to create photo session: ${error.message}`);
    }

    return {
      id: data.id,
      mode: data.mode,
      status: data.status as PhotoSessionSummary["status"],
      frameCount: data.frame_count,
      captureCount: data.capture_count,
      startedAt: data.started_at,
      completedAt: data.completed_at,
    };
  }

  async updateSessionStatus(
    sessionId: string,
    status: string,
    completedAt: string | null = null,
  ): Promise<void> {
    const { error } = await this.client
      .from("photo_sessions")
      .update({
        status,
        completed_at: completedAt,
        updated_at: new Date().toISOString(),
      })
      .eq("id", sessionId);

    if (error) {
      throw new Error(`Failed to update photo session: ${error.message}`);
    }
  }

  async saveAsset(asset: PhotoAsset, frameId: string | null = null): Promise<PhotoAsset> {
    const { data, error } = await this.client
      .from("photo_assets")
      .upsert({
        ...mapPhotoAssetToInsert(asset),
        frame_id: frameId,
      })
      .select("*")
      .single();

    if (error) {
      throw new Error(`Failed to save photo asset: ${error.message}`);
    }

    return mapPhotoAssetRowToAsset(data);
  }

  async listAssetsBySession(sessionId: string): Promise<PhotoAsset[]> {
    const { data, error } = await this.client
      .from("photo_assets")
      .select("*")
      .eq("session_id", sessionId)
      .order("created_at", { ascending: true });

    if (error) {
      throw new Error(`Failed to list photo assets: ${error.message}`);
    }

    return data.map(mapPhotoAssetRowToAsset);
  }
}
TS

write_file "packages/data-access/src/supabase/repositories/supabase-transaction-log.repository.ts" <<'TS'
import type {
  TransactionLogEntry,
  TransactionLogPort,
} from "@corra/booth-core";
import type { CorraSupabaseClient } from "../supabase-client";

export class SupabaseTransactionLogRepository implements TransactionLogPort {
  constructor(private readonly client: CorraSupabaseClient) {}

  async append(entry: TransactionLogEntry): Promise<void> {
    const { error } = await this.client.from("transactions").insert({
      id: entry.id,
      session_id: entry.sessionId ?? null,
      type: entry.type,
      message: entry.message,
      metadata: entry.metadata ?? null,
      created_at: entry.createdAt,
    });

    if (error) {
      throw new Error(`Failed to append transaction log: ${error.message}`);
    }
  }
}
TS

echo ""
echo "Creating local repositories..."

write_file "packages/data-access/src/local/repositories/memory-local-settings.repository.ts" <<'TS'
import type { LocalSettingsPort } from "@corra/booth-core";

export class MemoryLocalSettingsRepository<TSettings extends Record<string, unknown>>
  implements LocalSettingsPort<TSettings>
{
  private settings: TSettings;

  constructor(initialSettings: TSettings) {
    this.settings = structuredClone(initialSettings);
  }

  async get(): Promise<TSettings> {
    return structuredClone(this.settings);
  }

  async set(settings: TSettings): Promise<void> {
    this.settings = structuredClone(settings);
  }

  async patch(settings: Partial<TSettings>): Promise<void> {
    this.settings = {
      ...this.settings,
      ...structuredClone(settings),
    };
  }
}
TS

write_file "packages/data-access/src/local/repositories/browser-local-storage-settings.repository.ts" <<'TS'
import type { LocalSettingsPort } from "@corra/booth-core";

export class BrowserLocalStorageSettingsRepository<
  TSettings extends Record<string, unknown>,
> implements LocalSettingsPort<TSettings>
{
  constructor(
    private readonly storageKey: string,
    private readonly defaultSettings: TSettings,
  ) {}

  async get(): Promise<TSettings> {
    this.assertLocalStorageAvailable();

    const rawValue = localStorage.getItem(this.storageKey);

    if (!rawValue) {
      return structuredClone(this.defaultSettings);
    }

    try {
      return {
        ...this.defaultSettings,
        ...(JSON.parse(rawValue) as Partial<TSettings>),
      };
    } catch {
      return structuredClone(this.defaultSettings);
    }
  }

  async set(settings: TSettings): Promise<void> {
    this.assertLocalStorageAvailable();
    localStorage.setItem(this.storageKey, JSON.stringify(settings));
  }

  async patch(settings: Partial<TSettings>): Promise<void> {
    const current = await this.get();

    await this.set({
      ...current,
      ...settings,
    });
  }

  private assertLocalStorageAvailable(): void {
    if (typeof localStorage === "undefined") {
      throw new Error("localStorage is not available in this runtime.");
    }
  }
}
TS

write_file "packages/data-access/src/local/local-settings.types.ts" <<'TS'
import type { CameraProvider, PrinterProvider } from "@corra/shared";

export interface CorraBoothLocalSettings {
  licenseCode: string | null;
  deviceId: string | null;
  deviceName: string | null;

  selectedCameraProvider: CameraProvider;
  selectedPrinterProvider: PrinterProvider;

  printCopies: number;
  pricePerSession: number;

  qrisImageLocalPath: string | null;
  downloadPageBaseUrl: string;

  lastLicenseCheckAt: string | null;
  lastSyncedAt: string | null;
}

export const DEFAULT_CORRA_BOOTH_LOCAL_SETTINGS: CorraBoothLocalSettings = {
  licenseCode: null,
  deviceId: null,
  deviceName: null,

  selectedCameraProvider: "MOCK",
  selectedPrinterProvider: "MOCK",

  printCopies: 1,
  pricePerSession: 0,

  qrisImageLocalPath: null,
  downloadPageBaseUrl: "",

  lastLicenseCheckAt: null,
  lastSyncedAt: null,
};
TS

echo ""
echo "Creating offline queue..."

write_file "packages/data-access/src/offline/offline-queue.types.ts" <<'TS'
export type OfflineQueueJobType =
  | "UPLOAD_ASSET"
  | "SAVE_PHOTO_SESSION"
  | "SAVE_TRANSACTION_LOG"
  | "VERIFY_LICENSE"
  | "SYNC_SETTINGS";

export type OfflineQueueJobStatus =
  | "PENDING"
  | "PROCESSING"
  | "COMPLETED"
  | "FAILED";

export interface OfflineQueueJob<TPayload = unknown> {
  id: string;
  type: OfflineQueueJobType;
  status: OfflineQueueJobStatus;
  payload: TPayload;
  retryCount: number;
  lastError: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface OfflineQueueRepository {
  enqueue<TPayload>(job: OfflineQueueJob<TPayload>): Promise<void>;
  listPending(limit?: number): Promise<Array<OfflineQueueJob<unknown>>>;
  markProcessing(jobId: string): Promise<void>;
  markCompleted(jobId: string): Promise<void>;
  markFailed(jobId: string, errorMessage: string): Promise<void>;
}
TS

write_file "packages/data-access/src/offline/memory-offline-queue.repository.ts" <<'TS'
import type {
  OfflineQueueJob,
  OfflineQueueRepository,
} from "./offline-queue.types";

export class MemoryOfflineQueueRepository implements OfflineQueueRepository {
  private readonly jobs = new Map<string, OfflineQueueJob<unknown>>();

  async enqueue<TPayload>(job: OfflineQueueJob<TPayload>): Promise<void> {
    this.jobs.set(job.id, job as OfflineQueueJob<unknown>);
  }

  async listPending(limit = 50): Promise<Array<OfflineQueueJob<unknown>>> {
    return [...this.jobs.values()]
      .filter((job) => job.status === "PENDING" || job.status === "FAILED")
      .sort((a, b) => a.createdAt.localeCompare(b.createdAt))
      .slice(0, limit);
  }

  async markProcessing(jobId: string): Promise<void> {
    this.patchJob(jobId, {
      status: "PROCESSING",
      updatedAt: new Date().toISOString(),
    });
  }

  async markCompleted(jobId: string): Promise<void> {
    this.patchJob(jobId, {
      status: "COMPLETED",
      updatedAt: new Date().toISOString(),
    });
  }

  async markFailed(jobId: string, errorMessage: string): Promise<void> {
    const current = this.getJob(jobId);

    this.patchJob(jobId, {
      status: "FAILED",
      retryCount: current.retryCount + 1,
      lastError: errorMessage,
      updatedAt: new Date().toISOString(),
    });
  }

  private getJob(jobId: string): OfflineQueueJob<unknown> {
    const job = this.jobs.get(jobId);

    if (!job) {
      throw new Error(`Offline queue job not found: ${jobId}.`);
    }

    return job;
  }

  private patchJob(
    jobId: string,
    patch: Partial<OfflineQueueJob<unknown>>,
  ): void {
    const current = this.getJob(jobId);

    this.jobs.set(jobId, {
      ...current,
      ...patch,
    });
  }
}
TS

echo ""
echo "Creating utility files..."

write_file "packages/data-access/src/utils/create-id.ts" <<'TS'
export function createDataAccessId(prefix: string): string {
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

write_file "packages/data-access/src/utils/error.ts" <<'TS'
export function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  if (typeof error === "string") {
    return error;
  }

  return "Unknown error";
}
TS

echo ""
echo "Creating data-access facade..."

write_file "packages/data-access/src/index.ts" <<'TS'
export * from "./config/supabase-config";
export * from "./config/runtime-env";

export * from "./supabase/database.types";
export * from "./supabase/supabase-client";

export * from "./supabase/mappers/license.mapper";
export * from "./supabase/mappers/photo-asset.mapper";

export * from "./supabase/repositories/supabase-license.repository";
export * from "./supabase/repositories/supabase-storage.repository";
export * from "./supabase/repositories/supabase-photo.repository";
export * from "./supabase/repositories/supabase-transaction-log.repository";

export * from "./local/local-settings.types";
export * from "./local/repositories/memory-local-settings.repository";
export * from "./local/repositories/browser-local-storage-settings.repository";

export * from "./offline/offline-queue.types";
export * from "./offline/memory-offline-queue.repository";

export * from "./utils/create-id";
export * from "./utils/error";
TS

echo ""
echo "Creating docs..."

write_file "docs/data-access.md" <<'MD'
# Corra Booth Data Access

Phase 4 creates the data-access skeleton.

## Responsibilities

`packages/data-access` handles:

- Supabase client creation
- License repository
- Photo session repository
- Photo asset repository
- Supabase Storage repository
- Transaction log repository
- Local settings repository
- Offline queue skeleton

## Security Boundary

Do not put these inside the booth UI:

- Mayar API key
- Mayar webhook secret
- Supabase service-role key
- Any backend-only secret

The booth UI may use:

- Supabase URL
- Supabase anon key

The service-role key is only for:

- Supabase Edge Functions
- trusted server runtime
- backend scripts

## Storage Note

The generic `SupabaseStorageRepository` can upload browser-readable URLs:

- data URL
- blob URL
- http URL
- https URL

It intentionally cannot read raw filesystem paths.

For Electron production, create a dedicated Electron storage adapter that reads files from disk in the main process, then uploads the binary safely.

## Planned Repositories

Current skeleton:

- `SupabaseLicenseRepository`
- `SupabaseStorageRepository`
- `SupabasePhotoRepository`
- `SupabaseTransactionLogRepository`
- `MemoryLocalSettingsRepository`
- `BrowserLocalStorageSettingsRepository`
- `MemoryOfflineQueueRepository`

## Next Phase

Phase 5 should create Supabase SQL migrations:

- licenses
- booth_devices
- transactions
- photo_sessions
- photo_assets
- templates
- layouts
- vouchers
- admin_users
MD

echo ""
echo "Running install and typecheck..."

pnpm install

pnpm --filter @corra/shared typecheck
pnpm --filter @corra/booth-core typecheck
pnpm --filter @corra/image-engine typecheck
pnpm --filter @corra/data-access typecheck

echo ""
echo "========================================"
echo " Phase 4 completed."
echo "========================================"
echo ""
echo "Recommended git commit:"
echo "  git add ."
echo "  git commit -m \"feat: add data access skeleton\""
echo ""
