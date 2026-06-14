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
