import type { QrCodePort } from "@corra/booth-core";
import { generatePlaceholderQrSvgDataUrl } from "./svg-placeholder-qr";
import type { QrCodeGeneratorOptions, QrCodeImage } from "./qr-code.types";

const DEFAULT_OPTIONS: QrCodeGeneratorOptions = {
  size: 512,
  margin: 24,
  darkColor: "#000000",
  lightColor: "#ffffff",
};

export class PlaceholderQrCodeGenerator implements QrCodePort {
  constructor(private readonly options: Partial<QrCodeGeneratorOptions> = {}) {}

  async generateDataUrl(content: string): Promise<string> {
    const qr = await this.generate(content);
    return qr.dataUrl;
  }

  async generate(content: string): Promise<QrCodeImage> {
    if (!content.trim()) {
      throw new Error("QR content is required.");
    }

    const options = {
      ...DEFAULT_OPTIONS,
      ...this.options,
    };

    return {
      content,
      dataUrl: generatePlaceholderQrSvgDataUrl(content, options.size),
      mimeType: "image/svg+xml",
    };
  }
}
