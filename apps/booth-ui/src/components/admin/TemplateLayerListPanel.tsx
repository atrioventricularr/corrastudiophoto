import React from 'react';
import { useTemplates } from '../../templates';

export function TemplateLayerListPanel() {
  const { activeTemplate } = useTemplates();

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

      <div className="mt-4 space-y-2">
        {activeTemplate.layers.length === 0 && (
          <div className="rounded-2xl bg-slate-50 p-4 text-center text-sm font-bold text-slate-400">
            No layers yet.
          </div>
        )}

        {activeTemplate.layers.map((layer) => (
          <div
            key={layer.id}
            className="grid gap-2 rounded-2xl bg-slate-50 p-3 text-xs sm:grid-cols-[60px_1fr_100px_80px]"
          >
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

            <div className="font-bold text-slate-600">
              {Math.round(layer.opacity * 100)}%
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
