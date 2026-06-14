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
