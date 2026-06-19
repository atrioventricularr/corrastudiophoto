#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10D1C - Layout Admin Panel Read-only"
echo "========================================"

mkdir -p apps/booth-ui/src/components/admin

cat > apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx <<'TSX'
import React from 'react';
import { useLayouts } from '../../layouts';

function formatPercent(value: number): string {
  return `${Number(value).toFixed(1)}%`;
}

export function LayoutAdminPanel() {
  const {
    layouts,
    activeLayoutId,
    activeLayout,
    guideSettings,
    setActiveLayoutId,
  } = useLayouts();

  return (
    <section className="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Layout
          </p>
          <h3 className="mt-1 text-2xl font-black text-slate-950">
            Layout Builder
          </h3>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Cek layout aktif, ukuran canvas, paper size, dan posisi photo slot.
          </p>
        </div>

        <span className="rounded-full bg-slate-950 px-3 py-1 text-xs font-black uppercase tracking-wider text-white">
          {activeLayout.mode}
        </span>
      </div>

      <label className="mt-5 block">
        <span className="text-xs font-black uppercase tracking-wider text-slate-400">
          Active Layout
        </span>
        <select
          value={activeLayoutId}
          onChange={(event) => setActiveLayoutId(event.target.value)}
          className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
        >
          {layouts.map((layout) => (
            <option key={layout.id} value={layout.id}>
              {layout.name}
            </option>
          ))}
        </select>
      </label>

      <div className="mt-5 grid gap-4 lg:grid-cols-4">
        <div className="rounded-3xl bg-slate-50 p-4">
          <p className="text-xs font-black uppercase tracking-wider text-slate-400">
            Paper
          </p>
          <p className="mt-2 text-lg font-black text-slate-950">
            {activeLayout.paperName}
          </p>
          <p className="mt-1 text-xs font-bold text-slate-500">
            {activeLayout.paperWidthInch} × {activeLayout.paperHeightInch} inch
          </p>
        </div>

        <div className="rounded-3xl bg-slate-50 p-4">
          <p className="text-xs font-black uppercase tracking-wider text-slate-400">
            Canvas
          </p>
          <p className="mt-2 text-lg font-black text-slate-950">
            {activeLayout.canvasWidthPx} × {activeLayout.canvasHeightPx}
          </p>
          <p className="mt-1 text-xs font-bold text-slate-500">
            pixels
          </p>
        </div>

        <div className="rounded-3xl bg-slate-50 p-4">
          <p className="text-xs font-black uppercase tracking-wider text-slate-400">
            Orientation
          </p>
          <p className="mt-2 text-lg font-black capitalize text-slate-950">
            {activeLayout.orientation}
          </p>
          <p className="mt-1 text-xs font-bold text-slate-500">
            {activeLayout.dpi} DPI
          </p>
        </div>

        <div className="rounded-3xl bg-slate-50 p-4">
          <p className="text-xs font-black uppercase tracking-wider text-slate-400">
            Slots
          </p>
          <p className="mt-2 text-lg font-black text-slate-950">
            {activeLayout.slots.length}
          </p>
          <p className="mt-1 text-xs font-bold text-slate-500">
            photo slot
          </p>
        </div>
      </div>

      <div className="mt-5 rounded-3xl border border-blue-100 bg-blue-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-blue-400">
          Camera Guide Settings
        </p>

        <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-blue-400">
              Grid
            </p>
            <p className="mt-1 text-sm font-black text-blue-950">
              {guideSettings.showGrid ? 'ON' : 'OFF'}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-blue-400">
              Slot Guide
            </p>
            <p className="mt-1 text-sm font-black text-blue-950">
              {guideSettings.showSlotGuide ? 'ON' : 'OFF'}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-blue-400">
              Opacity
            </p>
            <p className="mt-1 text-sm font-black text-blue-950">
              {Math.round(guideSettings.guideOpacity * 100)}%
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-blue-400">
              Mirror Preview
            </p>
            <p className="mt-1 text-sm font-black text-blue-950">
              {guideSettings.mirrorPreview ? 'ON' : 'OFF'}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-blue-400">
              Mirror Final
            </p>
            <p className="mt-1 text-sm font-black text-blue-950">
              {guideSettings.mirrorFinalOutput ? 'ON' : 'OFF'}
            </p>
          </div>
        </div>
      </div>

      <div className="mt-5 overflow-hidden rounded-3xl border border-slate-100">
        <div className="bg-slate-50 px-4 py-3">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Photo Slots
          </p>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-white text-slate-400">
              <tr>
                <th className="px-4 py-3 font-black">Order</th>
                <th className="px-4 py-3 font-black">Name</th>
                <th className="px-4 py-3 font-black">Position</th>
                <th className="px-4 py-3 font-black">Size</th>
                <th className="px-4 py-3 font-black">Shape</th>
                <th className="px-4 py-3 font-black">Crop</th>
                <th className="px-4 py-3 font-black">Guide</th>
              </tr>
            </thead>
            <tbody>
              {activeLayout.slots.map((slot) => (
                <tr key={slot.id} className="border-t border-slate-100">
                  <td className="px-4 py-3 font-mono font-black text-slate-700">
                    {slot.captureOrder}
                  </td>
                  <td className="px-4 py-3 font-bold text-slate-700">
                    {slot.name}
                  </td>
                  <td className="px-4 py-3 font-mono font-bold text-slate-600">
                    X {formatPercent(slot.xPercent)} · Y{' '}
                    {formatPercent(slot.yPercent)}
                  </td>
                  <td className="px-4 py-3 font-mono font-bold text-slate-600">
                    W {formatPercent(slot.widthPercent)} · H{' '}
                    {formatPercent(slot.heightPercent)}
                  </td>
                  <td className="px-4 py-3 font-bold text-slate-600">
                    {slot.shape}
                  </td>
                  <td className="px-4 py-3 font-bold text-slate-600">
                    {slot.cropMode}
                  </td>
                  <td className="px-4 py-3 font-bold text-slate-600">
                    {slot.showGuide ? slot.guideLabel : 'Hidden'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {activeLayout.notes && (
        <div className="mt-5 rounded-3xl bg-slate-50 p-4">
          <p className="text-xs font-black uppercase tracking-wider text-slate-400">
            Notes
          </p>
          <p className="mt-2 text-sm font-bold text-slate-600">
            {activeLayout.notes}
          </p>
        </div>
      )}
    </section>
  );
}
TSX

ADMIN="apps/booth-ui/src/components/AdminPanel.tsx"

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

if "LayoutAdminPanel" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(
        insert_at,
        "import { LayoutAdminPanel } from './admin/LayoutAdminPanel';",
    )
    text = "\n".join(lines) + "\n"

pattern = r'<AdminPage activeSection=\{activeSection\} section="layout">[\s\S]*?</AdminPage>'
replacement = '''<AdminPage activeSection={activeSection} section="layout">
          <LayoutAdminPanel />
        </AdminPage>'''

text = re.sub(pattern, replacement, text, count=1)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Created:"
echo "- apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx"
echo ""
echo "Patched:"
echo "- apps/booth-ui/src/components/AdminPanel.tsx"
echo ""
echo "Phase 10D1C completed."
