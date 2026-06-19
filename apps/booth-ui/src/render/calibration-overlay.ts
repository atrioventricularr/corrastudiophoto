import type { PrintMarginPx } from '../print';

export type CalibrationGuideOptions = {
  label?: string;
  marginPx?: PrintMarginPx;
};

export function drawCalibrationGuide(
  context: CanvasRenderingContext2D,
  width: number,
  height: number,
  options: CalibrationGuideOptions = {},
): void {
  const lineWidth = Math.max(2, Math.round(Math.min(width, height) * 0.0015));
  const centerX = width / 2;
  const centerY = height / 2;

  context.save();

  context.lineWidth = lineWidth;
  context.strokeStyle = '#ef4444';
  context.fillStyle = '#ef4444';
  context.font = `${Math.max(24, Math.round(width * 0.018))}px sans-serif`;
  context.setLineDash([]);

  context.strokeRect(
    lineWidth / 2,
    lineWidth / 2,
    width - lineWidth,
    height - lineWidth,
  );

  context.beginPath();
  context.moveTo(centerX, 0);
  context.lineTo(centerX, height);
  context.moveTo(0, centerY);
  context.lineTo(width, centerY);
  context.stroke();

  context.beginPath();
  context.arc(centerX, centerY, Math.max(18, lineWidth * 4), 0, Math.PI * 2);
  context.stroke();

  if (options.marginPx) {
    const margin = options.marginPx;

    context.strokeStyle = '#2563eb';
    context.fillStyle = '#2563eb';
    context.setLineDash([lineWidth * 6, lineWidth * 4]);

    context.strokeRect(
      margin.left,
      margin.top,
      width - margin.left - margin.right,
      height - margin.top - margin.bottom,
    );

    context.setLineDash([]);
    context.fillText(
      `Margin T${margin.top} R${margin.right} B${margin.bottom} L${margin.left}`,
      margin.left + lineWidth * 4,
      margin.top + lineWidth * 14,
    );
  }

  context.fillStyle = '#ef4444';
  context.fillText(
    options.label || 'CALIBRATION GUIDE',
    lineWidth * 8,
    lineWidth * 18,
  );

  context.restore();
}
