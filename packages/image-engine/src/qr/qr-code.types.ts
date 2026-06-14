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
