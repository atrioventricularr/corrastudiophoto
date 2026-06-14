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
