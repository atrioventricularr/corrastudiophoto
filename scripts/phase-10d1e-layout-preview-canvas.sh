#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10D1E - Layout Preview Canvas"
echo "========================================"

mkdir -p apps/booth-ui/src/components/layouts

cat > apps/booth-ui/src/components/layouts/LayoutPreviewCanvas.tsx <<'TSX'
import React from 'react';
import type { PhotoLayout } from '../../layouts';

type LayoutPreviewCanvasProps = {
  layout: PhotoLayout;
};

function getAspectRatio(layout: PhotoLayout): string {
  return `${layout.canvasWidthPx} / ${layout.canvasHeightPx}`;
}

export function LayoutPreviewCanvas({ layout }: LayoutPreviewCanvasProps) {
  return (
    <div className="rounded-[2rem] border border-slate-200 bg-slate-50 p-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Layout Preview
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            {layout.name}
          </h4>
          <p className="mt-1 text-xs font-bold text-slate-500">
            {layout.canvasWidthPx} × {layout.canvasHeightPx}px ·{' '}
            {layout.paperName}
          </p>
        </div>

        <span className="rounded-full bg-white px-3 py-1 text-xs font-black text-slate-600">
          {layout.slots.length} slots
        </span>
      </div>

      <div className="mt-5 flex justify-center">
        <div className="w-full max-w-md rounded-3xl bg-slate-200 p-4">
          <div
            className="relative mx-auto w-full overflow-hidden rounded-2xl border border-slate-300 bg-white shadow-inner"
            style={{
              aspectRatio: getAspectRatio(layout),
              backgroundColor: layout.backgroundColor,
            }}
          >
            <div className="absolute inset-0 bg-[linear-gradient(to_right,rgba(15,23,42,0.08)_1px,transparent_1px),linear-gradient(to_bottom,rgba(15,23,42,0.08)_1px,transparent_1px)] bg-[size:10%_10%]" />

            {layout.slots.map((slot) => (
              <div
                key={slot.id}
                className="absolute flex items-center justify-center border-2 border-dashed border-blue-500 bg-blue-100/60 text-center"
                style={{
                  left: `${slot.xPercent}%`,
                  top: `${slot.yPercent}%`,
                  width: `${slot.widthPercent}%`,
                  height: `${slot.heightPercent}%`,
                  borderRadius:
                    slot.shape === 'circle'
                      ? '9999px'
                      : `${slot.borderRadiusPercent}%`,
                  transform: `rotate(${slot.rotationDeg}deg)`,
                }}
              >
                <div className="px-2">
                  <p className="text-[10px] font-black uppercase tracking-wider text-blue-800">
                    {slot.guideLabel || slot.name}
                  </p>
                  <p className="mt-1 font-mono text-[9px] font-bold text-blue-600">
                    #{slot.captureOrder}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <p className="mt-4 text-center text-xs font-semibold text-slate-400">
        Preview ini pakai persentase canvas. Ukuran print final tetap mengikuti
        pixel canvas asli.
      </p>
    </div>
  );
}
TSX

cat > apps/booth-ui/src/components/layouts/index.ts <<'TS'
export * from './LayoutPreviewCanvas';
TS

FILE="apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx"

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx")
text = path.read_text()

if "LayoutPreviewCanvas" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(
        insert_at,
        "import { LayoutPreviewCanvas } from '../layouts';",
    )
    text = "\n".join(lines) + "\n"

marker = """      <div className="mt-5 rounded-3xl border border-blue-100 bg-blue-50 p-4">"""

insert = """      <div className="mt-5">
        <LayoutPreviewCanvas layout={activeLayout} />
      </div>

"""

if "<LayoutPreviewCanvas layout={activeLayout}" not in text:
    if marker not in text:
        raise SystemExit("Could not find guide settings marker.")
    text = text.replace(marker, insert + marker, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Phase 10D1E completed."
