import React, { useState } from 'react';
import { useLayouts } from '../../layouts';
import { usePrinterProfile } from '../../print';
import { renderFinalTemplateToCanvas, renderPrintReadyTemplateToCanvas } from '../../render';
import { useTemplates } from '../../templates';

type RenderMode = 'raw' | 'print-ready';

export function TemplateRenderPreviewPanel() {
  const { activeTemplate } = useTemplates();
  const { layouts, activeLayout } = useLayouts();
  const { printerProfile } = usePrinterProfile();

  const [previewUrl, setPreviewUrl] = useState<string>('');
  const [renderInfo, setRenderInfo] = useState<string>('');
  const [error, setError] = useState<string>('');
  const [isRendering, setIsRendering] = useState(false);
  const [renderMode, setRenderMode] = useState<RenderMode>('print-ready');

  const handleRenderPreview = async () => {
    setIsRendering(true);
    setError('');

    try {
      const layout =
        layouts.find((item) => item.id === activeTemplate.layoutId) ||
        activeLayout;

      const result =
        renderMode === 'print-ready'
          ? await renderPrintReadyTemplateToCanvas({
              template: activeTemplate,
              layout,
              printerProfile,
              showEmptySlotPlaceholder: true,
            })
          : await renderFinalTemplateToCanvas({
              template: activeTemplate,
              layout,
              showEmptySlotPlaceholder: true,
            });

      setPreviewUrl(result.dataUrl);
      setRenderInfo(
        `${result.widthPx} × ${result.heightPx}px ${
          renderMode === 'print-ready' ? 'print-ready' : 'raw template'
        } PNG`,
      );
    } catch (caughtError) {
      setError(
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to render template preview.',
      );
    } finally {
      setIsRendering(false);
    }
  };

  const handleDownloadPreview = () => {
    if (!previewUrl) return;

    const safeName = activeTemplate.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const link = document.createElement('a');
    link.href = previewUrl;
    link.download = `${safeName || 'corra-template'}-render-preview.png`;
    document.body.appendChild(link);
    link.click();
    link.remove();
  };

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Final Render Test
          </p>
          <h4 className="mt-1 text-lg font-black text-slate-950">
            Render Preview PNG
          </h4>
          <p className="mt-1 text-xs font-bold text-slate-500">
            Bandingkan raw template render vs print-ready render dengan printer profile aktif.
          </p>
        </div>

        <button
          type="button"
          onClick={handleRenderPreview}
          disabled={isRendering}
          className="rounded-2xl bg-slate-950 px-5 py-3 text-xs font-black text-white disabled:opacity-50"
        >
          {isRendering ? 'Rendering...' : 'Render Preview PNG'}
        </button>
      </div>

      <div className="mt-4 rounded-2xl border border-slate-200 bg-slate-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Render Mode
        </p>

        <div className="mt-3 grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => setRenderMode('raw')}
            className={`rounded-2xl px-4 py-3 text-xs font-black ${
              renderMode === 'raw'
                ? 'bg-slate-950 text-white'
                : 'border border-slate-200 bg-white text-slate-700'
            }`}
          >
            Raw Template
          </button>

          <button
            type="button"
            onClick={() => setRenderMode('print-ready')}
            className={`rounded-2xl px-4 py-3 text-xs font-black ${
              renderMode === 'print-ready'
                ? 'bg-slate-950 text-white'
                : 'border border-slate-200 bg-white text-slate-700'
            }`}
          >
            Print-Ready
          </button>
        </div>
      </div>

      <div className="mt-4 rounded-2xl border border-indigo-100 bg-indigo-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-indigo-400">
          Active Printer Profile
        </p>

        <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-indigo-400">
              Printer
            </p>
            <p className="mt-1 text-sm font-black text-indigo-950">
              {printerProfile.printerModel}
            </p>
            <p className="mt-1 text-[10px] font-bold text-indigo-500">
              {printerProfile.printerType}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-indigo-400">
              Paper
            </p>
            <p className="mt-1 text-sm font-black text-indigo-950">
              {printerProfile.paperName}
            </p>
            <p className="mt-1 text-[10px] font-bold text-indigo-500">
              {printerProfile.paperWidthInch} × {printerProfile.paperHeightInch} inch
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-indigo-400">
              Offset / Scale
            </p>
            <p className="mt-1 font-mono text-sm font-black text-indigo-950">
              X {printerProfile.offsetPx.x} · Y {printerProfile.offsetPx.y}
            </p>
            <p className="mt-1 text-[10px] font-bold text-indigo-500">
              Scale {printerProfile.scalePercent}%
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-indigo-400">
              Print Mode
            </p>
            <p className="mt-1 text-sm font-black text-indigo-950">
              {printerProfile.borderless ? 'Borderless' : 'With Margin'}
            </p>
            <p className="mt-1 text-[10px] font-bold text-indigo-500">
              Rotate: {printerProfile.rotateBeforePrint ? 'Yes' : 'No'}
            </p>
          </div>
        </div>

        <div className="mt-3 rounded-2xl bg-white p-3">
          <p className="text-[10px] font-black uppercase text-indigo-400">
            Margin px
          </p>
          <p className="mt-1 font-mono text-xs font-black text-indigo-950">
            Top {printerProfile.marginPx.top} · Right {printerProfile.marginPx.right} · Bottom{' '}
            {printerProfile.marginPx.bottom} · Left {printerProfile.marginPx.left}
          </p>
        </div>
      </div>

      {error && (
        <div className="mt-4 rounded-2xl border border-red-200 bg-red-50 p-3 text-xs font-bold text-red-700">
          {error}
        </div>
      )}

      {previewUrl && (
        <div className="mt-4 rounded-2xl bg-slate-50 p-4">
          <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-xs font-black uppercase tracking-wider text-slate-400">
              {renderInfo}
            </p>

            <button
              type="button"
              onClick={handleDownloadPreview}
              className="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-xs font-black text-slate-700"
            >
              Download PNG
            </button>
          </div>

          <img
            src={previewUrl}
            alt="Rendered template preview"
            className="mx-auto max-h-[420px] rounded-xl border border-slate-200 bg-white object-contain"
          />
        </div>
      )}
    </section>
  );
}
