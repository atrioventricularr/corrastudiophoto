import React, { useState } from 'react';
import { useLayouts } from '../../layouts';
import { usePrinterProfile } from '../../print';
import { renderFinalTemplateToCanvas, renderPrintReadyTemplateToCanvas, type SlotPhotoMap } from '../../render';
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
  const [samplePhotosBySlotId, setSamplePhotosBySlotId] =
    useState<SlotPhotoMap>({});

  const renderLayout =
    layouts.find((item) => item.id === activeTemplate.layoutId) ||
    activeLayout;

  const samplePhotoCount = Object.keys(samplePhotosBySlotId).length;

  const handleRenderPreview = async () => {
    setIsRendering(true);
    setError('');

    try {
      const layout = renderLayout;

      const result =
        renderMode === 'print-ready'
          ? await renderPrintReadyTemplateToCanvas({
              template: activeTemplate,
              layout,
              printerProfile,
              photosBySlotId: samplePhotosBySlotId,
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

  const handleSamplePhotoUpload = (
    slotId: string,
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];

    if (!file) return;

    if (!file.type.startsWith('image/')) {
      window.alert('Sample photo harus image.');
      event.target.value = '';
      return;
    }

    const reader = new FileReader();

    reader.onload = () => {
      if (typeof reader.result !== 'string') return;

      setSamplePhotosBySlotId((current) => ({
        ...current,
        [slotId]: reader.result as string,
      }));
    };

    reader.readAsDataURL(file);
    event.target.value = '';
  };

  const handleRemoveSamplePhoto = (slotId: string) => {
    setSamplePhotosBySlotId((current) => {
      const next = { ...current };
      delete next[slotId];
      return next;
    });
  };

  const handleClearSamplePhotos = () => {
    setSamplePhotosBySlotId({});
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

      <div className="mt-4 rounded-2xl border border-cyan-100 bg-cyan-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-cyan-500">
          Render Status
        </p>

        <div className="mt-3 grid gap-3 sm:grid-cols-4">
          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-cyan-400">
              Mode
            </p>
            <p className="mt-1 text-sm font-black text-cyan-950">
              {renderMode === 'print-ready' ? 'Print-Ready' : 'Raw Template'}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-cyan-400">
              Sample Photos
            </p>
            <p className="mt-1 text-sm font-black text-cyan-950">
              {samplePhotoCount} / {renderLayout.slots.length}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-cyan-400">
              Template
            </p>
            <p className="mt-1 truncate text-sm font-black text-cyan-950">
              {activeTemplate.name}
            </p>
          </div>

          <button
            type="button"
            onClick={handleClearSamplePhotos}
            disabled={samplePhotoCount === 0}
            className="rounded-2xl border border-cyan-200 bg-white px-4 py-3 text-xs font-black text-cyan-700 disabled:opacity-40"
          >
            Clear Sample Photos
          </button>
        </div>
      </div>

      <div className="mt-4 rounded-2xl border border-emerald-100 bg-emerald-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">
          Sample Photos
        </p>
        <p className="mt-1 text-xs font-bold text-emerald-700">
          Upload foto dummy per slot untuk tes hasil render final.
        </p>

        <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {renderLayout.slots.map((slot) => (
            <div key={slot.id} className="rounded-2xl bg-white p-3">
              <p className="text-sm font-black text-slate-800">
                #{slot.captureOrder} · {slot.name}
              </p>

              {samplePhotosBySlotId[slot.id] && (
                <img
                  src={samplePhotosBySlotId[slot.id]}
                  alt={slot.name}
                  className="mt-3 h-24 w-full rounded-xl object-cover"
                />
              )}

              <div className="mt-3 flex gap-2">
                <label className="flex-1 cursor-pointer rounded-xl bg-emerald-600 px-3 py-2 text-center text-[11px] font-black text-white">
                  Upload
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(event) =>
                      handleSamplePhotoUpload(slot.id, event)
                    }
                    className="hidden"
                  />
                </label>

                {samplePhotosBySlotId[slot.id] && (
                  <button
                    type="button"
                    onClick={() => handleRemoveSamplePhoto(slot.id)}
                    className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-[11px] font-black text-red-700"
                  >
                    Remove
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
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
