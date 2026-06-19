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

marker = """      <div className="mt-4 rounded-2xl border border-emerald-100 bg-emerald-50 p-4">"""

metadata_block = """      <div className="mt-4 rounded-2xl border border-slate-200 bg-slate-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Render Metadata
        </p>

        <div className="mt-3 grid gap-3 lg:grid-cols-3">
          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-slate-400">
              Template
            </p>
            <p className="mt-1 text-sm font-black text-slate-950">
              {activeTemplate.name}
            </p>
            <p className="mt-1 font-mono text-[10px] font-bold text-slate-400">
              {activeTemplate.id}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-slate-400">
              Layout
            </p>
            <p className="mt-1 text-sm font-black text-slate-950">
              {renderLayout.name}
            </p>
            <p className="mt-1 font-mono text-[10px] font-bold text-slate-400">
              {renderLayout.id}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-slate-400">
              Render
            </p>
            <p className="mt-1 text-sm font-black text-slate-950">
              {renderMode === 'print-ready' ? 'Print-Ready' : 'Raw Template'}
            </p>
            <p className="mt-1 text-[10px] font-bold text-slate-400">
              Sample {samplePhotoCount}/{renderLayout.slots.length}
            </p>
          </div>
        </div>

        <div className="mt-3 grid gap-3 lg:grid-cols-3">
          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-slate-400">
              Canvas
            </p>
            <p className="mt-1 font-mono text-sm font-black text-slate-950">
              {activeTemplate.paperSnapshot.canvasWidthPx} ×{' '}
              {activeTemplate.paperSnapshot.canvasHeightPx}px
            </p>
            <p className="mt-1 text-[10px] font-bold text-slate-400">
              {activeTemplate.paperSnapshot.paperName} ·{' '}
              {activeTemplate.paperSnapshot.dpi} DPI
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-slate-400">
              Printer
            </p>
            <p className="mt-1 text-sm font-black text-slate-950">
              {printerProfile.printerModel}
            </p>
            <p className="mt-1 text-[10px] font-bold text-slate-400">
              {printerProfile.printerType} · {printerProfile.paperName}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-slate-400">
              Adjustment
            </p>
            <p className="mt-1 font-mono text-xs font-black text-slate-950">
              Offset X {printerProfile.offsetPx.x} · Y{' '}
              {printerProfile.offsetPx.y}
            </p>
            <p className="mt-1 text-[10px] font-bold text-slate-400">
              Scale {printerProfile.scalePercent}% · Rotate{' '}
              {printerProfile.rotateBeforePrint ? 'Yes' : 'No'}
            </p>
          </div>
        </div>
      </div>

"""

if "Render Metadata" not in text:
    if marker not in text:
        raise SystemExit("Could not find Sample Photos marker.")
    text = text.replace(marker, metadata_block + marker, 1)

path.write_text(text)
print("10D2H patched:", path)
PY

echo "10D2H mini done."
