#!/usr/bin/env bash
set -euo pipefail

cat > apps/booth-ui/src/render/printer-calibration-sheet.ts <<'TS'
import type { PrinterProfile } from '../print';
import { drawCalibrationGuide } from './calibration-overlay';
import type { FinalRenderResult } from './final-render-types';

export function renderPrinterCalibrationSheet(input: {
  widthPx: number;
  heightPx: number;
  printerProfile: PrinterProfile;
}): FinalRenderResult {
  const canvas = document.createElement('canvas');
  canvas.width = input.widthPx;
  canvas.height = input.heightPx;

  const context = canvas.getContext('2d');

  if (!context) {
    throw new Error('Canvas 2D context is not available.');
  }

  context.fillStyle = '#ffffff';
  context.fillRect(0, 0, canvas.width, canvas.height);

  context.save();

  const gridStepX = canvas.width / 10;
  const gridStepY = canvas.height / 10;

  context.strokeStyle = '#cbd5e1';
  context.lineWidth = Math.max(1, Math.round(Math.min(canvas.width, canvas.height) * 0.0008));

  for (let index = 1; index < 10; index += 1) {
    context.beginPath();
    context.moveTo(gridStepX * index, 0);
    context.lineTo(gridStepX * index, canvas.height);
    context.moveTo(0, gridStepY * index);
    context.lineTo(canvas.width, gridStepY * index);
    context.stroke();
  }

  context.restore();

  drawCalibrationGuide(context, canvas.width, canvas.height, {
    label: 'PRINTER CALIBRATION SHEET',
    marginPx: input.printerProfile.borderless
      ? undefined
      : input.printerProfile.marginPx,
  });

  context.save();

  const fontSize = Math.max(22, Math.round(canvas.width * 0.016));
  context.font = `${fontSize}px sans-serif`;
  context.fillStyle = '#0f172a';

  const lines = [
    `Printer: ${input.printerProfile.printerModel}`,
    `Type: ${input.printerProfile.printerType}`,
    `Paper: ${input.printerProfile.paperName}`,
    `Canvas: ${canvas.width} x ${canvas.height}px`,
    `DPI: ${input.printerProfile.dpi}`,
    `Borderless: ${input.printerProfile.borderless ? 'Yes' : 'No'}`,
    `Offset: X ${input.printerProfile.offsetPx.x} / Y ${input.printerProfile.offsetPx.y}`,
    `Scale: ${input.printerProfile.scalePercent}%`,
    `Rotate: ${input.printerProfile.rotateBeforePrint ? 'Yes' : 'No'}`,
  ];

  const padding = Math.max(40, Math.round(canvas.width * 0.025));
  const lineHeight = Math.round(fontSize * 1.45);

  context.fillStyle = 'rgba(255,255,255,0.85)';
  context.fillRect(
    padding - 20,
    padding - 20,
    Math.round(canvas.width * 0.52),
    lineHeight * (lines.length + 1),
  );

  context.fillStyle = '#0f172a';
  lines.forEach((line, index) => {
    context.fillText(line, padding, padding + lineHeight * index);
  });

  context.restore();

  return {
    canvas,
    dataUrl: canvas.toDataURL('image/png'),
    widthPx: canvas.width,
    heightPx: canvas.height,
  };
}
TS

grep -q "printer-calibration-sheet" apps/booth-ui/src/render/index.ts || cat >> apps/booth-ui/src/render/index.ts <<'TS'
export * from './printer-calibration-sheet';
TS

FILE="apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx"

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx")
text = path.read_text()

text = text.replace(
    "renderFinalTemplateToCanvas, renderPrintReadyTemplateToCanvas",
    "renderFinalTemplateToCanvas, renderPrintReadyTemplateToCanvas, renderPrinterCalibrationSheet",
)

marker = """  const handleDownloadPreview = () => {
    if (!previewUrl) return;"""

handler = """  const handleRenderCalibrationSheet = () => {
    const result = renderPrinterCalibrationSheet({
      widthPx: activeTemplate.paperSnapshot.canvasWidthPx,
      heightPx: activeTemplate.paperSnapshot.canvasHeightPx,
      printerProfile,
    });

    setPreviewUrl(result.dataUrl);
    setRenderInfo(`${result.widthPx} × ${result.heightPx}px calibration sheet PNG`);
    setError('');
  };

"""

if "handleRenderCalibrationSheet" not in text:
    if marker not in text:
        raise SystemExit("Could not find download handler marker.")
    text = text.replace(marker, handler + marker, 1)

button_marker = """        <button
          type="button"
          onClick={handleRenderPreview}
          disabled={isRendering}
          className="rounded-2xl bg-slate-950 px-5 py-3 text-xs font-black text-white disabled:opacity-50"
        >
          {isRendering ? 'Rendering...' : 'Render Preview PNG'}
        </button>"""

button_block = """        <div className="flex flex-col gap-2 sm:flex-row">
          <button
            type="button"
            onClick={handleRenderCalibrationSheet}
            className="rounded-2xl border border-red-200 bg-red-50 px-5 py-3 text-xs font-black text-red-700"
          >
            Calibration Sheet
          </button>

          <button
            type="button"
            onClick={handleRenderPreview}
            disabled={isRendering}
            className="rounded-2xl bg-slate-950 px-5 py-3 text-xs font-black text-white disabled:opacity-50"
          >
            {isRendering ? 'Rendering...' : 'Render Preview PNG'}
          </button>
        </div>"""

if "Calibration Sheet" not in text:
    if button_marker not in text:
        raise SystemExit("Could not find Render Preview button.")
    text = text.replace(button_marker, button_block, 1)

path.write_text(text)
print("10D2K patched:", path)
PY

echo "10D2K mini done."
