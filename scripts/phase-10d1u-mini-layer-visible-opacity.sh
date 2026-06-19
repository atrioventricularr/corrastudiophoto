#!/usr/bin/env bash
set -euo pipefail

cat > apps/booth-ui/src/components/admin/TemplateLayerListPanel.tsx <<'TSX'
import React from 'react';
import { useTemplates } from '../../templates';

export function TemplateLayerListPanel() {
  const {
    activeTemplate,
    updateTemplateLayer,
  } = useTemplates();

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Template Layers
          </p>
          <h4 className="mt-1 text-lg font-black text-slate-950">
            Layer Stack
          </h4>
        </div>

        <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-black text-slate-600">
          {activeTemplate.layers.length} layers
        </span>
      </div>

      <div className="mt-4 space-y-3">
        {activeTemplate.layers.length === 0 && (
          <div className="rounded-2xl bg-slate-50 p-4 text-center text-sm font-bold text-slate-400">
            No layers yet.
          </div>
        )}

        {activeTemplate.layers.map((layer) => (
          <div
            key={layer.id}
            className="rounded-2xl bg-slate-50 p-3"
          >
            <div className="grid gap-3 text-xs lg:grid-cols-[70px_1fr_100px_120px_180px] lg:items-center">
              <div className="font-mono font-black text-slate-500">
                Z {layer.zIndex}
              </div>

              <div>
                <p className="font-black text-slate-800">{layer.name}</p>
                <p className="mt-1 font-mono text-[10px] font-bold text-slate-400">
                  {layer.assetId}
                </p>
              </div>

              <div className="font-bold text-slate-600">
                {layer.kind}
              </div>

              <label className="flex items-center gap-2 font-black text-slate-700">
                <input
                  type="checkbox"
                  checked={layer.visible}
                  onChange={(event) =>
                    updateTemplateLayer(activeTemplate.id, layer.id, {
                      visible: event.target.checked,
                    })
                  }
                />
                Visible
              </label>

              <label className="block">
                <div className="flex items-center justify-between gap-2">
                  <span className="font-black text-slate-700">
                    Opacity
                  </span>
                  <span className="font-mono font-black text-slate-500">
                    {Math.round(layer.opacity * 100)}%
                  </span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="1"
                  step="0.05"
                  value={layer.opacity}
                  onChange={(event) =>
                    updateTemplateLayer(activeTemplate.id, layer.id, {
                      opacity: Number(event.target.value),
                    })
                  }
                  className="mt-2 w-full"
                />
              </label>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
TSX

cat > apps/booth-ui/src/components/templates/TemplatePreviewCanvas.tsx <<'TSX'
import React from 'react';
import { useLayouts } from '../../layouts';
import type { PhotoTemplate } from '../../templates';

type TemplatePreviewCanvasProps = {
  template: PhotoTemplate;
};

export function TemplatePreviewCanvas({
  template,
}: TemplatePreviewCanvasProps) {
  const { layouts } = useLayouts();

  const layout = layouts.find((item) => item.id === template.layoutId);

  const frameLayer = template.layers.find(
    (layer) =>
      layer.assetId === template.frameOverlayAssetId &&
      layer.kind === 'frame-overlay',
  );

  const frameAsset = template.assets.find(
    (asset) => asset.id === template.frameOverlayAssetId,
  );

  const showFrame = Boolean(frameAsset?.url && (frameLayer?.visible ?? true));

  return (
    <div className="rounded-[2rem] border border-slate-200 bg-slate-50 p-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Template Preview
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            {template.customerFacingName}
          </h4>
          <p className="mt-1 text-xs font-bold text-slate-500">
            {template.paperSnapshot.canvasWidthPx} ×{' '}
            {template.paperSnapshot.canvasHeightPx}px ·{' '}
            {template.paperSnapshot.paperName}
          </p>
        </div>

        <span className="rounded-full bg-white px-3 py-1 text-xs font-black text-slate-600">
          {showFrame ? 'Frame visible' : 'No visible frame'}
        </span>
      </div>

      <div className="mt-5 flex justify-center">
        <div className="w-full max-w-md rounded-3xl bg-slate-200 p-4">
          <div
            className="relative mx-auto w-full overflow-hidden rounded-2xl border border-slate-300 bg-white shadow-inner"
            style={{
              aspectRatio: `${template.paperSnapshot.canvasWidthPx} / ${template.paperSnapshot.canvasHeightPx}`,
            }}
          >
            <div className="absolute inset-0 bg-[linear-gradient(to_right,rgba(15,23,42,0.08)_1px,transparent_1px),linear-gradient(to_bottom,rgba(15,23,42,0.08)_1px,transparent_1px)] bg-[size:10%_10%]" />

            {layout?.slots.map((slot) => (
              <div
                key={slot.id}
                className="absolute flex items-center justify-center border-2 border-dashed border-blue-500 bg-blue-100/50 text-center"
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
                <p className="px-2 text-[10px] font-black uppercase text-blue-800">
                  {slot.guideLabel || slot.name}
                </p>
              </div>
            ))}

            {showFrame && frameAsset?.url && (
              <img
                src={frameAsset.url}
                alt={frameAsset.name}
                className="pointer-events-none absolute inset-0 h-full w-full object-contain"
                style={{
                  opacity: frameLayer?.opacity ?? 1,
                }}
              />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
TSX

echo "10D1U mini done."
