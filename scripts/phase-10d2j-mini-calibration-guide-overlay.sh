#!/usr/bin/env bash
set -euo pipefail

echo "Phase 10D2J - Calibration Guide Overlay"

cat > apps/booth-ui/src/render/calibration-overlay.ts <<'TS'
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
TS

python - <<'PY'
from pathlib import Path

# 1. Add option type
types_path = Path("apps/booth-ui/src/render/final-render-types.ts")
text = types_path.read_text()

if "showCalibrationGuide?: boolean;" not in text:
    text = text.replace(
        "  backgroundColor?: string;\n};",
        "  backgroundColor?: string;\n  showCalibrationGuide?: boolean;\n};",
    )

types_path.write_text(text)

# 2. Patch final renderer
renderer_path = Path("apps/booth-ui/src/render/final-renderer.ts")
text = renderer_path.read_text()

if "drawCalibrationGuide" not in text:
    text = text.replace(
        "import type { PhotoTemplateLayer, TemplateAssetRef } from '../templates';",
        "import type { PhotoTemplateLayer, TemplateAssetRef } from '../templates';\nimport { drawCalibrationGuide } from './calibration-overlay';",
    )

if "RAW TEMPLATE" not in text:
    text = text.replace(
        "  return {\n    canvas,",
        """  if (options.showCalibrationGuide) {
    drawCalibrationGuide(context, widthPx, heightPx, {
      label: 'RAW TEMPLATE',
    });
  }

  return {
    canvas,""",
        1,
    )

renderer_path.write_text(text)

# 3. Patch print-ready renderer
print_path = Path("apps/booth-ui/src/render/print-ready-renderer.ts")
text = print_path.read_text()

if "drawCalibrationGuide" not in text:
    text = text.replace(
        "import type { PrinterProfile } from '../print';",
        "import type { PrinterProfile } from '../print';\nimport { drawCalibrationGuide } from './calibration-overlay';",
    )

text = text.replace(
    "const baseResult = await renderFinalTemplateToCanvas(options);",
    "const baseResult = await renderFinalTemplateToCanvas({\n    ...options,\n    showCalibrationGuide: false,\n  });",
)

if "PRINT READY" not in text:
    text = text.replace(
        "  return {\n    canvas,",
        """  if (options.showCalibrationGuide) {
    drawCalibrationGuide(context, canvas.width, canvas.height, {
      label: 'PRINT READY',
      marginPx: printerProfile.borderless ? undefined : printerProfile.marginPx,
    });
  }

  return {
    canvas,""",
        1,
    )

print_path.write_text(text)

# 4. Export calibration overlay
index_path = Path("apps/booth-ui/src/render/index.ts")
text = index_path.read_text()

if "calibration-overlay" not in text:
    text += "\nexport * from './calibration-overlay';\n"

index_path.write_text(text)

print("Renderer patched.")
PY

FILE="apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx"

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx")
text = path.read_text()

# Add state
if "showCalibrationGuide" not in text:
    text = text.replace(
        "  const [renderMode, setRenderMode] = useState<RenderMode>('print-ready');",
        "  const [renderMode, setRenderMode] = useState<RenderMode>('print-ready');\n  const [showCalibrationGuide, setShowCalibrationGuide] = useState(false);",
    )

# Add option to both render calls safely
def add_option_to_call(source: str, call_name: str) -> str:
    pattern = re.compile(rf"({call_name}\(\{{[\s\S]*?\n\s*\}}\))")
    matches = list(pattern.finditer(source))

    for match in reversed(matches):
        block = match.group(1)

        if "showCalibrationGuide" in block:
            continue

        block2 = block.replace(
            "showEmptySlotPlaceholder: true,",
            "showEmptySlotPlaceholder: true,\n              showCalibrationGuide,",
            1,
        )

        source = source[:match.start(1)] + block2 + source[match.end(1):]

    return source

text = add_option_to_call(text, "renderPrintReadyTemplateToCanvas")
text = add_option_to_call(text, "renderFinalTemplateToCanvas")

# Insert UI toggle before Render Status block
marker = """      <div className="mt-4 rounded-2xl border border-cyan-100 bg-cyan-50 p-4">"""

block = """      <div className="mt-4 rounded-2xl border border-red-100 bg-red-50 p-4">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.2em] text-red-500">
              Calibration Guide
            </p>
            <p className="mt-1 text-xs font-bold text-red-700">
              Overlay garis bantu untuk cek border, center, margin, offset, dan scale print.
            </p>
          </div>

          <label className="flex items-center gap-2 rounded-2xl bg-white px-4 py-3 text-xs font-black text-red-700">
            <input
              type="checkbox"
              checked={showCalibrationGuide}
              onChange={(event) =>
                setShowCalibrationGuide(event.target.checked)
              }
            />
            Show Guide
          </label>
        </div>
      </div>

"""

if "Calibration Guide" not in text:
    if marker not in text:
        raise SystemExit("Could not find Render Status block marker.")
    text = text.replace(marker, block + marker, 1)

path.write_text(text)
print("Panel patched.")
PY

echo "10D2J mini done."
