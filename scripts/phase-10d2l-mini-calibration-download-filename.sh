#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: TemplateRenderPreviewPanel.tsx not found."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx")
text = path.read_text()

# Add output kind type
if "type RenderOutputKind" not in text:
    text = text.replace(
        "type RenderMode = 'raw' | 'print-ready';",
        "type RenderMode = 'raw' | 'print-ready';\ntype RenderOutputKind = 'template-preview' | 'calibration-sheet';",
    )

# Add output kind state
if "renderOutputKind" not in text:
    text = text.replace(
        "  const [renderMode, setRenderMode] = useState<RenderMode>('print-ready');",
        "  const [renderMode, setRenderMode] = useState<RenderMode>('print-ready');\n  const [renderOutputKind, setRenderOutputKind] =\n    useState<RenderOutputKind>('template-preview');",
    )

# Mark normal render as template-preview
if "setRenderOutputKind('template-preview');" not in text:
    text = text.replace(
        "      setPreviewUrl(result.dataUrl);\n      setRenderInfo(",
        "      setRenderOutputKind('template-preview');\n      setPreviewUrl(result.dataUrl);\n      setRenderInfo(",
        1,
    )

# Mark calibration render as calibration-sheet
if "setRenderOutputKind('calibration-sheet');" not in text:
    text = text.replace(
        "    setPreviewUrl(result.dataUrl);\n    setRenderInfo(`${result.widthPx} × ${result.heightPx}px calibration sheet PNG`);",
        "    setRenderOutputKind('calibration-sheet');\n    setPreviewUrl(result.dataUrl);\n    setRenderInfo(`${result.widthPx} × ${result.heightPx}px calibration sheet PNG`);",
        1,
    )

old = """    const safeName = activeTemplate.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const link = document.createElement('a');
    link.href = previewUrl;
    link.download = `${safeName || 'corra-template'}-render-preview.png`;"""

new = """    const safeName = activeTemplate.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const safePrinter = printerProfile.printerModel
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const safePaper = printerProfile.paperName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const fileName =
      renderOutputKind === 'calibration-sheet'
        ? `corra-calibration-${safePrinter || 'printer'}-${safePaper || 'paper'}-${renderMode}.png`
        : `${safeName || 'corra-template'}-${renderMode}-render-preview.png`;

    const link = document.createElement('a');
    link.href = previewUrl;
    link.download = fileName;"""

if "corra-calibration-" not in text:
    if old not in text:
        raise SystemExit("Could not find download filename block.")
    text = text.replace(old, new, 1)

# Change download button label dynamically
text = text.replace(
    "Download PNG",
    "{renderOutputKind === 'calibration-sheet' ? 'Download Calibration PNG' : 'Download PNG'}",
    1,
)

path.write_text(text)
print("10D2L patched:", path)
PY

echo "10D2L mini done."
