function escapeXml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;")
    .replaceAll("'", "&apos;");
}

function encodeSvgToDataUrl(svg: string): string {
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
}

export function generatePlaceholderQrSvgDataUrl(
  content: string,
  size: number,
): string {
  const safeContent = escapeXml(content);
  const cell = size / 8;

  const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect width="100%" height="100%" fill="white"/>
  <rect x="${cell}" y="${cell}" width="${cell * 2}" height="${cell * 2}" fill="black"/>
  <rect x="${cell * 5}" y="${cell}" width="${cell * 2}" height="${cell * 2}" fill="black"/>
  <rect x="${cell}" y="${cell * 5}" width="${cell * 2}" height="${cell * 2}" fill="black"/>
  <rect x="${cell * 4}" y="${cell * 4}" width="${cell}" height="${cell}" fill="black"/>
  <rect x="${cell * 5}" y="${cell * 5}" width="${cell}" height="${cell}" fill="black"/>
  <rect x="${cell * 6}" y="${cell * 4}" width="${cell}" height="${cell}" fill="black"/>
  <text x="50%" y="${size - cell}" text-anchor="middle" font-family="Arial, sans-serif" font-size="${Math.max(8, cell / 2)}" fill="black">QR PLACEHOLDER</text>
  <desc>${safeContent}</desc>
</svg>`.trim();

  return encodeSvgToDataUrl(svg);
}
