#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3C - Mirror Final Output Render"
echo "========================================"

python - <<'PY'
from pathlib import Path
import re

# 1. Add mirrorFinalOutput option to render types.
types_path = Path("apps/booth-ui/src/render/final-render-types.ts")
text = types_path.read_text()

if "mirrorFinalOutput?: boolean;" not in text:
    text = text.replace(
        "  showCalibrationGuide?: boolean;\n};",
        "  showCalibrationGuide?: boolean;\n  mirrorFinalOutput?: boolean;\n};",
    )

types_path.write_text(text)
print("PATCH:", types_path)

# 2. Patch final renderer slot photo drawing.
renderer_path = Path("apps/booth-ui/src/render/final-renderer.ts")
text = renderer_path.read_text()

text = text.replace(
    """async function drawSlotPhoto(
  context: CanvasRenderingContext2D,
  slot: PhotoLayoutSlot,
  photoUrl: string,
  canvasWidth: number,
  canvasHeight: number,
) {""",
    """async function drawSlotPhoto(
  context: CanvasRenderingContext2D,
  slot: PhotoLayoutSlot,
  photoUrl: string,
  canvasWidth: number,
  canvasHeight: number,
  mirrorFinalOutput: boolean,
) {""",
)

if "if (mirrorFinalOutput)" not in text:
    text = text.replace(
        """  clipSlotPath(context, slot, x, y, width, height);

  if (slot.cropMode === 'contain') {""",
        """  clipSlotPath(context, slot, x, y, width, height);

  if (mirrorFinalOutput) {
    context.translate(x + width / 2, y + height / 2);
    context.scale(-1, 1);
    context.translate(-(x + width / 2), -(y + height / 2));
  }

  if (slot.cropMode === 'contain') {""",
        1,
    )

text = text.replace(
    """      await drawSlotPhoto(context, slot, photoUrl, widthPx, heightPx);""",
    """      await drawSlotPhoto(
        context,
        slot,
        photoUrl,
        widthPx,
        heightPx,
        Boolean(options.mirrorFinalOutput),
      );""",
)

renderer_path.write_text(text)
print("PATCH:", renderer_path)

# 3. Patch TemplateRenderPreviewPanel to pass guideSettings.mirrorFinalOutput.
panel_path = Path("apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx")
text = panel_path.read_text()

text = text.replace(
    "  const { layouts, activeLayout } = useLayouts();",
    "  const { layouts, activeLayout, guideSettings } = useLayouts();",
)

# Add option to every renderFinal/renderPrintReady call if missing per block.
def add_option_to_render_calls(source: str) -> str:
    pattern = re.compile(
        r"((?:renderPrintReadyTemplateToCanvas|renderFinalTemplateToCanvas)\(\{[\s\S]*?\n\s*\}\))",
        re.MULTILINE,
    )

    matches = list(pattern.finditer(source))

    for match in reversed(matches):
        block = match.group(1)

        if "mirrorFinalOutput" in block:
            continue

        if "showCalibrationGuide," in block:
            block2 = block.replace(
                "showCalibrationGuide,",
                "showCalibrationGuide,\n              mirrorFinalOutput: guideSettings.mirrorFinalOutput,",
                1,
            )
        elif "showEmptySlotPlaceholder: true," in block:
            block2 = block.replace(
                "showEmptySlotPlaceholder: true,",
                "showEmptySlotPlaceholder: true,\n              mirrorFinalOutput: guideSettings.mirrorFinalOutput,",
                1,
            )
        else:
            block2 = block.replace(
                "\n      });",
                "\n        mirrorFinalOutput: guideSettings.mirrorFinalOutput,\n      });",
                1,
            )

        source = source[:match.start(1)] + block2 + source[match.end(1):]

    return source

text = add_option_to_render_calls(text)

# Add mirror final info into Render Status if possible.
if "Final Mirror" not in text:
    marker = """          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-cyan-400">
              Template
            </p>
            <p className="mt-1 truncate text-sm font-black text-cyan-950">
              {activeTemplate.name}
            </p>
          </div>"""

    replacement = marker + """

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-cyan-400">
              Final Mirror
            </p>
            <p className="mt-1 text-sm font-black text-cyan-950">
              {guideSettings.mirrorFinalOutput ? 'ON' : 'OFF'}
            </p>
          </div>"""

    if marker in text:
        text = text.replace(marker, replacement, 1)
        text = text.replace("sm:grid-cols-4", "sm:grid-cols-5", 1)

panel_path.write_text(text)
print("PATCH:", panel_path)
PY

echo ""
echo "Check mirror references:"
grep -R "mirrorFinalOutput" -n apps/booth-ui/src/render apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx || true

echo ""
echo "9A3C done."
