import type { PrinterProfile } from '../print';
import {
  renderFinalTemplateToCanvas,
} from './final-renderer';
import type {
  FinalRenderOptions,
  FinalRenderResult,
} from './final-render-types';

export type PrintReadyRenderOptions = FinalRenderOptions & {
  printerProfile: PrinterProfile;
};

export async function renderPrintReadyTemplateToCanvas(
  options: PrintReadyRenderOptions,
): Promise<FinalRenderResult> {
  const baseResult = await renderFinalTemplateToCanvas(options);
  const { printerProfile } = options;

  const canvas = document.createElement('canvas');
  canvas.width = baseResult.widthPx;
  canvas.height = baseResult.heightPx;

  const context = canvas.getContext('2d');

  if (!context) {
    throw new Error('Canvas 2D context is not available.');
  }

  context.fillStyle = '#ffffff';
  context.fillRect(0, 0, canvas.width, canvas.height);

  const margin = printerProfile.borderless
    ? {
        top: 0,
        right: 0,
        bottom: 0,
        left: 0,
      }
    : printerProfile.marginPx;

  const areaX = margin.left;
  const areaY = margin.top;
  const areaWidth = Math.max(1, canvas.width - margin.left - margin.right);
  const areaHeight = Math.max(1, canvas.height - margin.top - margin.bottom);

  const scale = Math.max(0.01, printerProfile.scalePercent / 100);

  const drawWidth = printerProfile.rotateBeforePrint
    ? areaHeight * scale
    : areaWidth * scale;

  const drawHeight = printerProfile.rotateBeforePrint
    ? areaWidth * scale
    : areaHeight * scale;

  const centerX = areaX + areaWidth / 2 + printerProfile.offsetPx.x;
  const centerY = areaY + areaHeight / 2 + printerProfile.offsetPx.y;

  context.save();
  context.translate(centerX, centerY);

  if (printerProfile.rotateBeforePrint) {
    context.rotate(Math.PI / 2);
  }

  context.drawImage(
    baseResult.canvas,
    -drawWidth / 2,
    -drawHeight / 2,
    drawWidth,
    drawHeight,
  );

  context.restore();

  return {
    canvas,
    dataUrl: canvas.toDataURL('image/png'),
    widthPx: canvas.width,
    heightPx: canvas.height,
  };
}
