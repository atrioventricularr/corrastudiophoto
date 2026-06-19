#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10D1H - Layout Paper Settings Editor"
echo "========================================"

mkdir -p apps/booth-ui/src/components/admin

cat > apps/booth-ui/src/components/admin/LayoutPaperSettingsPanel.tsx <<'TSX'
import React from 'react';
import {
  calculateCanvasPixelSize,
  findPaperPreset,
  paperSizePresets,
  type PaperPresetId,
  type PrintOrientation,
} from '../../print';
import { useLayouts } from '../../layouts';

function toNumber(value: string, fallback: number): number {
  const parsed = Number(value);

  if (Number.isNaN(parsed)) {
    return fallback;
  }

  return parsed;
}

export function LayoutPaperSettingsPanel() {
  const {
    activeLayout,
    updateLayout,
  } = useLayouts();

  const updateCanvas = (input: {
    paperWidthInch?: number;
    paperHeightInch?: number;
    orientation?: PrintOrientation;
    dpi?: number;
  }) => {
    const paperWidthInch = input.paperWidthInch ?? activeLayout.paperWidthInch;
    const paperHeightInch =
      input.paperHeightInch ?? activeLayout.paperHeightInch;
    const orientation = input.orientation ?? activeLayout.orientation;
    const dpi = input.dpi ?? activeLayout.dpi;

    const canvas = calculateCanvasPixelSize({
      widthInch: paperWidthInch,
      heightInch: paperHeightInch,
      orientation,
      dpi,
    });

    updateLayout(activeLayout.id, {
      paperWidthInch,
      paperHeightInch,
      orientation,
      dpi,
      canvasWidthPx: canvas.widthPx,
      canvasHeightPx: canvas.heightPx,
    });
  };

  const applyPaperPreset = (presetId: PaperPresetId) => {
    const preset = findPaperPreset(presetId);
    const dpi = preset.recommendedDpi;

    const canvas = calculateCanvasPixelSize({
      widthInch: preset.widthInch,
      heightInch: preset.heightInch,
      orientation: activeLayout.orientation,
      dpi,
    });

    updateLayout(activeLayout.id, {
      paperPresetId: preset.id,
      paperName: preset.name,
      paperWidthInch: preset.widthInch,
      paperHeightInch: preset.heightInch,
      dpi,
      canvasWidthPx: canvas.widthPx,
      canvasHeightPx: canvas.heightPx,
    });
  };

  return (
    <section className="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Paper Settings
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            Layout Canvas & Paper
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Ukuran ini menentukan canvas final untuk template, guide kamera, dan
            output print.
          </p>
        </div>

        <span className="rounded-full bg-slate-950 px-3 py-1 text-xs font-black text-white">
          {activeLayout.canvasWidthPx} × {activeLayout.canvasHeightPx}px
        </span>
      </div>

      <div className="mt-5 grid gap-4 lg:grid-cols-4">
        <label className="block lg:col-span-2">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Paper Preset
          </span>
          <select
            value={activeLayout.paperPresetId}
            onChange={(event) =>
              applyPaperPreset(event.target.value as PaperPresetId)
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          >
            {paperSizePresets.map((preset) => (
              <option key={preset.id} value={preset.id}>
                {preset.name}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Orientation
          </span>
          <select
            value={activeLayout.orientation}
            onChange={(event) =>
              updateCanvas({
                orientation: event.target.value as PrintOrientation,
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          >
            <option value="portrait">Portrait</option>
            <option value="landscape">Landscape</option>
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            DPI
          </span>
          <input
            type="number"
            value={activeLayout.dpi}
            onChange={(event) =>
              updateCanvas({
                dpi: toNumber(event.target.value, activeLayout.dpi),
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>
      </div>

      <div className="mt-4 grid gap-4 lg:grid-cols-4">
        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Paper Name
          </span>
          <input
            value={activeLayout.paperName}
            onChange={(event) =>
              updateLayout(activeLayout.id, {
                paperName: event.target.value,
                paperPresetId: 'custom',
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Width Inch
          </span>
          <input
            type="number"
            step="0.01"
            value={activeLayout.paperWidthInch}
            onChange={(event) =>
              updateCanvas({
                paperWidthInch: toNumber(
                  event.target.value,
                  activeLayout.paperWidthInch,
                ),
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Height Inch
          </span>
          <input
            type="number"
            step="0.01"
            value={activeLayout.paperHeightInch}
            onChange={(event) =>
              updateCanvas({
                paperHeightInch: toNumber(
                  event.target.value,
                  activeLayout.paperHeightInch,
                ),
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Background
          </span>
          <input
            type="color"
            value={activeLayout.backgroundColor}
            onChange={(event) =>
              updateLayout(activeLayout.id, {
                backgroundColor: event.target.value,
              })
            }
            className="mt-2 h-[46px] w-full rounded-2xl border border-slate-200 bg-slate-50 px-2 py-2 outline-none"
          />
        </label>
      </div>

      <div className="mt-5 rounded-3xl bg-slate-50 p-4">
        <p className="text-xs font-black uppercase tracking-wider text-slate-400">
          Output Canvas
        </p>
        <p className="mt-2 text-2xl font-black text-slate-950">
          {activeLayout.canvasWidthPx} × {activeLayout.canvasHeightPx}px
        </p>
        <p className="mt-1 text-xs font-bold text-slate-500">
          {activeLayout.paperWidthInch} × {activeLayout.paperHeightInch} inch ·{' '}
          {activeLayout.orientation} · {activeLayout.dpi} DPI
        </p>
      </div>
    </section>
  );
}
TSX

FILE="apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx"

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx")
text = path.read_text()

if "LayoutPaperSettingsPanel" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(
        insert_at,
        "import { LayoutPaperSettingsPanel } from './LayoutPaperSettingsPanel';",
    )
    text = "\n".join(lines) + "\n"

marker = """      <div className="mt-5 grid gap-4 lg:grid-cols-4">"""

insert = """      <div className="mt-5">
        <LayoutPaperSettingsPanel />
      </div>

"""

if "<LayoutPaperSettingsPanel />" not in text:
    if marker not in text:
        raise SystemExit("Could not find layout info grid marker.")
    text = text.replace(marker, insert + marker, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Created:"
echo "- apps/booth-ui/src/components/admin/LayoutPaperSettingsPanel.tsx"
echo ""
echo "Patched:"
echo "- apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx"
echo ""
echo "Phase 10D1H completed."
