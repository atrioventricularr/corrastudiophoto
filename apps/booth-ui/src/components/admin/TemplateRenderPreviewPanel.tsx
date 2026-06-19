import React, { useState } from 'react';
import { useLayouts } from '../../layouts';
import { renderFinalTemplateToCanvas } from '../../render';
import { useTemplates } from '../../templates';

export function TemplateRenderPreviewPanel() {
  const { activeTemplate } = useTemplates();
  const { layouts, activeLayout } = useLayouts();

  const [previewUrl, setPreviewUrl] = useState<string>('');
  const [renderInfo, setRenderInfo] = useState<string>('');
  const [error, setError] = useState<string>('');
  const [isRendering, setIsRendering] = useState(false);

  const handleRenderPreview = async () => {
    setIsRendering(true);
    setError('');

    try {
      const layout =
        layouts.find((item) => item.id === activeTemplate.layoutId) ||
        activeLayout;

      const result = await renderFinalTemplateToCanvas({
        template: activeTemplate,
        layout,
        showEmptySlotPlaceholder: true,
      });

      setPreviewUrl(result.dataUrl);
      setRenderInfo(`${result.widthPx} × ${result.heightPx}px PNG`);
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
            Tes output final dengan placeholder slot foto.
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

      {error && (
        <div className="mt-4 rounded-2xl border border-red-200 bg-red-50 p-3 text-xs font-bold text-red-700">
          {error}
        </div>
      )}

      {previewUrl && (
        <div className="mt-4 rounded-2xl bg-slate-50 p-4">
          <p className="mb-3 text-xs font-black uppercase tracking-wider text-slate-400">
            {renderInfo}
          </p>
          <div className="mb-3 flex justify-end">
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
