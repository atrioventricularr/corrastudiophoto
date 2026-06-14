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
