import type { PhotoLayoutSlot } from '../layouts';
import type { PhotoTemplateLayer, TemplateAssetRef } from '../templates';
import type { FinalRenderOptions, FinalRenderResult } from './final-render-types';

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const image = new Image();

    image.crossOrigin = 'anonymous';
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error(`Failed to load image: ${src}`));
    image.src = src;
  });
}

function percentToPx(value: number, total: number): number {
  return (value / 100) * total;
}

function getAssetById(
  assets: TemplateAssetRef[],
  assetId: string,
): TemplateAssetRef | undefined {
  return assets.find((asset) => asset.id === assetId);
}

function drawCover(
  context: CanvasRenderingContext2D,
  image: HTMLImageElement,
  x: number,
  y: number,
  width: number,
  height: number,
) {
  const imageRatio = image.width / image.height;
  const targetRatio = width / height;

  let sourceWidth = image.width;
  let sourceHeight = image.height;
  let sourceX = 0;
  let sourceY = 0;

  if (imageRatio > targetRatio) {
    sourceWidth = image.height * targetRatio;
    sourceX = (image.width - sourceWidth) / 2;
  } else {
    sourceHeight = image.width / targetRatio;
    sourceY = (image.height - sourceHeight) / 2;
  }

  context.drawImage(
    image,
    sourceX,
    sourceY,
    sourceWidth,
    sourceHeight,
    x,
    y,
    width,
    height,
  );
}

function drawContain(
  context: CanvasRenderingContext2D,
  image: HTMLImageElement,
  x: number,
  y: number,
  width: number,
  height: number,
) {
  const scale = Math.min(width / image.width, height / image.height);
  const renderWidth = image.width * scale;
  const renderHeight = image.height * scale;

  context.drawImage(
    image,
    x + (width - renderWidth) / 2,
    y + (height - renderHeight) / 2,
    renderWidth,
    renderHeight,
  );
}

function clipSlotPath(
  context: CanvasRenderingContext2D,
  slot: PhotoLayoutSlot,
  x: number,
  y: number,
  width: number,
  height: number,
) {
  context.beginPath();

  if (slot.shape === 'circle') {
    const radius = Math.min(width, height) / 2;
    context.arc(x + width / 2, y + height / 2, radius, 0, Math.PI * 2);
    context.clip();
    return;
  }

  const radius =
    slot.shape === 'square'
      ? 0
      : Math.min(width, height) * (slot.borderRadiusPercent / 100);

  context.roundRect(x, y, width, height, radius);
  context.clip();
}

async function drawSlotPhoto(
  context: CanvasRenderingContext2D,
  slot: PhotoLayoutSlot,
  photoUrl: string,
  canvasWidth: number,
  canvasHeight: number,
) {
  const image = await loadImage(photoUrl);

  const x = percentToPx(slot.xPercent, canvasWidth);
  const y = percentToPx(slot.yPercent, canvasHeight);
  const width = percentToPx(slot.widthPercent, canvasWidth);
  const height = percentToPx(slot.heightPercent, canvasHeight);

  context.save();

  context.translate(x + width / 2, y + height / 2);
  context.rotate((slot.rotationDeg * Math.PI) / 180);
  context.translate(-(x + width / 2), -(y + height / 2));

  clipSlotPath(context, slot, x, y, width, height);

  if (slot.cropMode === 'contain') {
    drawContain(context, image, x, y, width, height);
  } else if (slot.cropMode === 'fill') {
    context.drawImage(image, x, y, width, height);
  } else {
    drawCover(context, image, x, y, width, height);
  }

  context.restore();
}

function drawEmptySlotPlaceholder(
  context: CanvasRenderingContext2D,
  slot: PhotoLayoutSlot,
  canvasWidth: number,
  canvasHeight: number,
) {
  const x = percentToPx(slot.xPercent, canvasWidth);
  const y = percentToPx(slot.yPercent, canvasHeight);
  const width = percentToPx(slot.widthPercent, canvasWidth);
  const height = percentToPx(slot.heightPercent, canvasHeight);

  context.save();
  context.fillStyle = '#e0f2fe';
  context.strokeStyle = '#2563eb';
  context.lineWidth = 6;
  context.setLineDash([24, 16]);

  clipSlotPath(context, slot, x, y, width, height);
  context.fillRect(x, y, width, height);
  context.strokeRect(x, y, width, height);

  context.restore();
}

async function drawTemplateLayer(
  context: CanvasRenderingContext2D,
  layer: PhotoTemplateLayer,
  asset: TemplateAssetRef,
  canvasWidth: number,
  canvasHeight: number,
) {
  if (!layer.visible || !asset.url) return;

  const image = await loadImage(asset.url);

  const x = percentToPx(layer.xPercent, canvasWidth);
  const y = percentToPx(layer.yPercent, canvasHeight);
  const width = percentToPx(layer.widthPercent, canvasWidth);
  const height = percentToPx(layer.heightPercent, canvasHeight);

  context.save();
  context.globalAlpha = layer.opacity;
  context.translate(x + width / 2, y + height / 2);
  context.rotate((layer.rotationDeg * Math.PI) / 180);
  context.translate(-(x + width / 2), -(y + height / 2));
  context.drawImage(image, x, y, width, height);
  context.restore();
}

export async function renderFinalTemplateToCanvas(
  options: FinalRenderOptions,
): Promise<FinalRenderResult> {
  const { template, layout } = options;

  const canvas = document.createElement('canvas');
  const widthPx = template.paperSnapshot.canvasWidthPx;
  const heightPx = template.paperSnapshot.canvasHeightPx;

  canvas.width = widthPx;
  canvas.height = heightPx;

  const context = canvas.getContext('2d');

  if (!context) {
    throw new Error('Canvas 2D context is not available.');
  }

  context.fillStyle =
    options.backgroundColor || layout.backgroundColor || '#ffffff';
  context.fillRect(0, 0, widthPx, heightPx);

  const sortedLayers = [...template.layers].sort(
    (a, b) => a.zIndex - b.zIndex,
  );

  const bottomLayers = sortedLayers.filter((layer) => layer.zIndex < 50);
  const topLayers = sortedLayers.filter((layer) => layer.zIndex >= 50);

  for (const layer of bottomLayers) {
    const asset = getAssetById(template.assets, layer.assetId);
    if (asset) {
      await drawTemplateLayer(context, layer, asset, widthPx, heightPx);
    }
  }

  for (const slot of layout.slots) {
    const photoUrl = options.photosBySlotId?.[slot.id];

    if (photoUrl) {
      await drawSlotPhoto(context, slot, photoUrl, widthPx, heightPx);
    } else if (options.showEmptySlotPlaceholder) {
      drawEmptySlotPlaceholder(context, slot, widthPx, heightPx);
    }
  }

  for (const layer of topLayers) {
    const asset = getAssetById(template.assets, layer.assetId);
    if (asset) {
      await drawTemplateLayer(context, layer, asset, widthPx, heightPx);
    }
  }

  return {
    canvas,
    dataUrl: canvas.toDataURL('image/png'),
    widthPx,
    heightPx,
  };
}
