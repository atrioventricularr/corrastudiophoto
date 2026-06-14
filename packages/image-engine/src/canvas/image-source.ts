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
