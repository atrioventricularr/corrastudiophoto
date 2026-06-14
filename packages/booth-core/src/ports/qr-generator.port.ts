export interface QrCodePort {
  generateDataUrl(content: string): Promise<string>;
}
