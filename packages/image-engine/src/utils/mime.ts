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
