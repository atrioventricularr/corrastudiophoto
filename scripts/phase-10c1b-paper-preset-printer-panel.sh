#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10C1B - Paper Preset in Printer Panel"
echo "========================================"

FILE="apps/booth-ui/src/components/admin/PrinterProfilePanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: PrinterProfilePanel.tsx not found. Run 10B1B first."
  exit 1
}

[ -f "apps/booth-ui/src/print/paper-presets.ts" ] || {
  echo "ERROR: paper-presets.ts not found. Run 10C1A first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/PrinterProfilePanel.tsx")
text = path.read_text()

# 1. Add imports.
if "paperSizePresets" not in text:
    text = text.replace(
        """import {
  usePrinterProfile,
  type PrintOrientation,
  type PrinterType,
} from '../../print';""",
        """import {
  findPaperPreset,
  paperSizePresets,
  usePrinterProfile,
  type PaperPresetId,
  type PrintOrientation,
  type PrinterType,
} from '../../print';""",
    )

# 2. Add applyPaperPreset function after applyA3Preset.
if "const applyPaperPreset" not in text:
    marker = """  const applyA3Preset = () => {
    updatePrinterProfile({
      id: 'custom-a3',
      name: 'A3 Event Poster',
      printerType: 'CUSTOM',
      printerModel: 'Custom A3 Printer',
      paperName: 'A3',
      paperWidthInch: 11.69,
      paperHeightInch: 16.54,
      orientation: 'portrait',
      dpi: 300,
      borderless: false,
      rotateBeforePrint: false,
      marginPx: {
        top: 90,
        right: 90,
        bottom: 90,
        left: 90,
      },
      offsetPx: {
        x: 0,
        y: 0,
      },
      scalePercent: 100,
      notes:
        'A3 layout profile for event poster or custom collage.',
    });
  };"""

    insert = marker + """

  const applyPaperPreset = (presetId: PaperPresetId) => {
    const preset = findPaperPreset(presetId);

    updatePrinterProfile({
      paperName: preset.name,
      paperWidthInch: preset.widthInch,
      paperHeightInch: preset.heightInch,
      dpi: preset.recommendedDpi,
      notes:
        presetId === 'custom'
          ? 'Custom paper size. Adjust width, height, and DPI manually.'
          : `Paper preset applied: ${preset.name}.`,
    });
  };"""

    if marker not in text:
      raise SystemExit("Could not find applyA3Preset block.")
    text = text.replace(marker, insert)

# 3. Add dropdown before Paper Name label.
if "Paper Preset" not in text:
    marker = """        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Paper Name
          </span>"""

    dropdown = """        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Paper Preset
          </span>
          <select
            value="custom"
            onChange={(event) =>
              applyPaperPreset(event.target.value as PaperPresetId)
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          >
            <option value="custom">Choose preset...</option>
            {paperSizePresets.map((preset) => (
              <option key={preset.id} value={preset.id}>
                {preset.name}
              </option>
            ))}
          </select>
        </label>

""" + marker

    if marker not in text:
      raise SystemExit("Could not find Paper Name label.")
    text = text.replace(marker, dropdown, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "Paper Preset" "$FILE" || {
  echo "ERROR: Paper Preset dropdown missing."
  exit 1
}

grep -q "applyPaperPreset" "$FILE" || {
  echo "ERROR: applyPaperPreset missing."
  exit 1
}

echo ""
echo "Relevant lines:"
grep -n "paperSizePresets\\|Paper Preset\\|applyPaperPreset" "$FILE" || true

echo ""
echo "Phase 10C1B completed."
