import React from 'react';
import {
  type CameraRenderOutput,
  useCameraRenderOutput,
} from './CameraRenderOutputProvider';

function downloadOutput(output: CameraRenderOutput) {
  const safeTemplateName = output.templateName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

  const link = document.createElement('a');
  link.href = output.dataUrl;
  link.download = `${safeTemplateName || 'corra'}-${output.renderMode}-session-output.png`;
  document.body.appendChild(link);
  link.click();
  link.remove();
}

export function CameraRenderOutputPanel() {
  const {
    latestOutput,
    outputHistory,
    clearRenderOutputs,
  } = useCameraRenderOutput();

  if (!latestOutput) {
    return (
      <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Session Final Output
        </p>
        <h4 className="mt-1 text-xl font-black text-slate-950">
          No Final Output Yet
        </h4>
        <p className="mt-1 text-sm font-semibold text-slate-500">
          Setelah render final berhasil, hasilnya akan tersimpan sementara di
          local session ini.
        </p>
      </section>
    );
  }

  return (
    <section className="rounded-3xl border border-emerald-200 bg-emerald-50 p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">
            Session Final Output
          </p>
          <h4 className="mt-1 text-xl font-black text-emerald-950">
            Latest Render Saved
          </h4>
          <p className="mt-1 text-sm font-semibold text-emerald-700">
            Output terakhir sudah tersimpan di local session sementara.
          </p>
        </div>

        <span className="rounded-full bg-emerald-600 px-3 py-1 text-xs font-black text-white">
          {outputHistory.length} saved
        </span>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-4">
        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Size
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {latestOutput.widthPx} × {latestOutput.heightPx}px
          </p>
        </div>

        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Mode
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {latestOutput.renderMode}
          </p>
        </div>

        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Source
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {latestOutput.source}
          </p>
        </div>

        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Captures
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {latestOutput.capturedSlotCount} / {latestOutput.totalSlotCount}
          </p>
        </div>
      </div>

      <div className="mt-4 rounded-3xl bg-white/80 p-4">
        <img
          src={latestOutput.dataUrl}
          alt="Latest final output"
          className="mx-auto max-h-[420px] rounded-xl border border-emerald-100 bg-white object-contain"
        />
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <button
          type="button"
          onClick={() => downloadOutput(latestOutput)}
          className="rounded-2xl bg-emerald-600 px-4 py-3 text-xs font-black text-white"
        >
          Download Latest Output
        </button>

        <button
          type="button"
          onClick={clearRenderOutputs}
          className="rounded-2xl border border-red-200 bg-white px-4 py-3 text-xs font-black text-red-700"
        >
          Clear Session Outputs
        </button>
      </div>
    </section>
  );
}
