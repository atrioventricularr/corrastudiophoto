import React from 'react';
import { useTemplates } from '../../templates';

export function TemplateAssetSummaryPanel() {
  const { activeTemplate } = useTemplates();

  const hasFrame = Boolean(activeTemplate.frameOverlayAssetId);
  const hasBackground = Boolean(activeTemplate.backgroundAssetId);
  const visibleLayers = activeTemplate.layers.filter((layer) => layer.visible);

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4">
      <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
        Asset Summary
      </p>

      <div className="mt-4 grid gap-3 sm:grid-cols-5">
        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Assets
          </p>
          <p className="mt-1 text-xl font-black text-slate-950">
            {activeTemplate.assets.length}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Layers
          </p>
          <p className="mt-1 text-xl font-black text-slate-950">
            {activeTemplate.layers.length}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Visible
          </p>
          <p className="mt-1 text-xl font-black text-slate-950">
            {visibleLayers.length}
          </p>
        </div>

        <div className="rounded-2xl bg-blue-50 p-3">
          <p className="text-[10px] font-black uppercase text-blue-400">
            Frame
          </p>
          <p className="mt-1 text-sm font-black text-blue-900">
            {hasFrame ? 'Ready' : 'Missing'}
          </p>
        </div>

        <div className="rounded-2xl bg-purple-50 p-3">
          <p className="text-[10px] font-black uppercase text-purple-400">
            Background
          </p>
          <p className="mt-1 text-sm font-black text-purple-900">
            {hasBackground ? 'Ready' : 'Missing'}
          </p>
        </div>
      </div>
    </section>
  );
}
