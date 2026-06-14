import type { PhotoAsset } from "@corra/shared";

export interface UploadAssetRequest {
  asset: PhotoAsset;
  localPath: string;
}

export interface StoragePort {
  uploadAsset(request: UploadAssetRequest): Promise<PhotoAsset>;
  getPublicUrl(asset: PhotoAsset): Promise<string>;
}
