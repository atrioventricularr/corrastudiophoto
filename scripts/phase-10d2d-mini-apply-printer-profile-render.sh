#!/usr/bin/env bash
set -euo pipefail

mkdir -p apps/booth-ui/src/render

cat > apps/booth-ui/src/render/print-ready-renderer.ts <<'TS'
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
TS

grep -q "print-ready-renderer" apps/booth-ui/src/render/index.ts || cat >> apps/booth-ui/src/render/index.ts <<'TS'
export * from './print-ready-renderer';
TS

FILE="apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx"

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx")
text = path.read_text()

text = text.replace(
    "import { renderFinalTemplateToCanvas } from '../../render';",
    "import { renderPrintReadyTemplateToCanvas } from '../../render';",
)

text = text.replace(
    "const result = await renderFinalTemplateToCanvas({\n        template: activeTemplate,\n        layout,\n        showEmptySlotPlaceholder: true,\n      });",
    "const result = await renderPrintReadyTemplateToCanvas({\n        template: activeTemplate,\n        layout,\n        printerProfile,\n        showEmptySlotPlaceholder: true,\n      });",
)

text = text.replace(
    "setRenderInfo(`${result.widthPx} × ${result.heightPx}px PNG`);",
    "setRenderInfo(`${result.widthPx} × ${result.heightPx}px print-ready PNG`);",
)

text = text.replace(
    "Tes output final dengan placeholder slot foto.",
    "Tes output final print-ready dengan placeholder slot foto dan printer profile aktif.",
)

path.write_text(text)
print("PATCH:", path)
PY

echo "10D2D mini done."
