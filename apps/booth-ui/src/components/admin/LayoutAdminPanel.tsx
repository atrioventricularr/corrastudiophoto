import React from 'react';
import { useLayouts } from '../../layouts';
import { LayoutPreviewCanvas } from '../layouts';
import { LayoutSlotEditorPanel } from './LayoutSlotEditorPanel';
import { LayoutActionsPanel } from './LayoutActionsPanel';
import { LayoutPaperSettingsPanel } from './LayoutPaperSettingsPanel';

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
    updateGuideSettings,
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

      <div className="mt-5">
        <LayoutActionsPanel />
      </div>

      <div className="mt-5">
        <LayoutPaperSettingsPanel />
      </div>

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

      <div className="mt-5">
        <LayoutPreviewCanvas layout={activeLayout} />
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

      <div className="mt-5">
        <LayoutSlotEditorPanel />
      </div>

      <div className="mt-5 rounded-3xl border border-emerald-100 bg-emerald-50 p-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">
              Guide Controls
            </p>
            <h4 className="mt-1 text-xl font-black text-emerald-950">
              Camera Preview Guide
            </h4>
            <p className="mt-1 text-xs font-bold text-emerald-700">
              Setting ini nanti dipakai di camera preview: mirror, grid, dan slot guide.
            </p>
          </div>

          <span className="rounded-full bg-white px-3 py-1 text-xs font-black text-emerald-700">
            Opacity {Math.round(guideSettings.guideOpacity * 100)}%
          </span>
        </div>

        <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={guideSettings.showGrid}
              onChange={(event) =>
                updateGuideSettings({
                  showGrid: event.target.checked,
                })
              }
            />
            <span className="text-sm font-black text-slate-700">
              Show grid
            </span>
          </label>

          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={guideSettings.showSlotGuide}
              onChange={(event) =>
                updateGuideSettings({
                  showSlotGuide: event.target.checked,
                })
              }
            />
            <span className="text-sm font-black text-slate-700">
              Show slot guide
            </span>
          </label>

          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={guideSettings.mirrorPreview}
              onChange={(event) =>
                updateGuideSettings({
                  mirrorPreview: event.target.checked,
                })
              }
            />
            <span className="text-sm font-black text-slate-700">
              Mirror preview
            </span>
          </label>

          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={guideSettings.mirrorFinalOutput}
              onChange={(event) =>
                updateGuideSettings({
                  mirrorFinalOutput: event.target.checked,
                })
              }
            />
            <span className="text-sm font-black text-slate-700">
              Mirror final output
            </span>
          </label>
        </div>

        <label className="mt-4 block rounded-2xl bg-white px-4 py-3">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Guide Opacity
          </span>
          <input
            type="range"
            min="0"
            max="1"
            step="0.05"
            value={guideSettings.guideOpacity}
            onChange={(event) =>
              updateGuideSettings({
                guideOpacity: Number(event.target.value),
              })
            }
            className="mt-3 w-full"
          />
        </label>
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
