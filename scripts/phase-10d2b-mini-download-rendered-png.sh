#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: TemplateRenderPreviewPanel.tsx not found. Run 10D2A first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx")
text = path.read_text()

marker = """  const handleRenderPreview = async () => {
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

  return ("""

insert = """  const handleRenderPreview = async () => {
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

  return ("""

if "handleDownloadPreview" not in text:
    if marker not in text:
        raise SystemExit("Could not find render handler block.")
    text = text.replace(marker, insert, 1)

old = """          <img
            src={previewUrl}
            alt="Rendered template preview"
            className="mx-auto max-h-[420px] rounded-xl border border-slate-200 bg-white object-contain"
          />"""

new = """          <div className="mb-3 flex justify-end">
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
          />"""

if "Download PNG" not in text:
    if old not in text:
        raise SystemExit("Could not find rendered preview image block.")
    text = text.replace(old, new, 1)

path.write_text(text)
print("PATCH:", path)
PY

echo "10D2B mini done."
