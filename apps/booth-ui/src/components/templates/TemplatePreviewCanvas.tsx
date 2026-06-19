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
  const frameAsset = template.assets.find(
    (asset) => asset.id === template.frameOverlayAssetId,
  );

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
          {frameAsset ? 'Frame loaded' : 'No frame'}
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

            {frameAsset?.url && (
              <img
                src={frameAsset.url}
                alt={frameAsset.name}
                className="pointer-events-none absolute inset-0 h-full w-full object-contain"
              />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
