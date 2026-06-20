#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3I - Render Template From Captured Frames"
echo "========================================"

mkdir -p apps/booth-ui/src/camera

cat > apps/booth-ui/src/camera/CameraCapturedRenderPanel.tsx <<'TSX'
import React, { useState } from 'react';
import { useLayouts } from '../layouts';
import { usePrinterProfile } from '../print';
import {
  renderFinalTemplateToCanvas,
  renderPrintReadyTemplateToCanvas,
} from '../render';
import { useTemplates } from '../templates';
import { useCapturedFrames } from './CapturedFramesProvider';

type CameraRenderMode = 'raw' | 'print-ready';

export function CameraCapturedRenderPanel() {
  const { activeLayout, layouts, guideSettings } = useLayouts();
  const { activeTemplate } = useTemplates();
  const { printerProfile } = usePrinterProfile();
  const { photosBySlotId, capturedFramesBySlotId } = useCapturedFrames();

  const [renderMode, setRenderMode] = useState<CameraRenderMode>('print-ready');
  const [previewUrl, setPreviewUrl] = useState('');
  const [renderInfo, setRenderInfo] = useState('');
  const [error, setError] = useState('');
  const [isRendering, setIsRendering] = useState(false);

  const capturedCount = Object.keys(capturedFramesBySlotId).length;

  const renderLayout =
    layouts.find((layout) => layout.id === activeTemplate.layoutId) ||
    activeLayout;

  const handleRender = async () => {
    setIsRendering(true);
    setError('');

    try {
      const result =
        renderMode === 'print-ready'
          ? await renderPrintReadyTemplateToCanvas({
              template: activeTemplate,
              layout: renderLayout,
              printerProfile,
              photosBySlotId,
              showEmptySlotPlaceholder: true,
              mirrorFinalOutput: guideSettings.mirrorFinalOutput,
            })
          : await renderFinalTemplateToCanvas({
              template: activeTemplate,
              layout: renderLayout,
              photosBySlotId,
              showEmptySlotPlaceholder: true,
              mirrorFinalOutput: guideSettings.mirrorFinalOutput,
            });

      setPreviewUrl(result.dataUrl);
      setRenderInfo(
        `${result.widthPx} × ${result.heightPx}px ${
          renderMode === 'print-ready' ? 'print-ready' : 'raw'
        } PNG`,
      );
    } catch (caughtError) {
      setError(
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to render captured template.',
      );
    } finally {
      setIsRendering(false);
    }
  };

  const handleDownload = () => {
    if (!previewUrl) return;

    const safeName = activeTemplate.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const link = document.createElement('a');
    link.href = previewUrl;
    link.download = `${safeName || 'corra-captured'}-${renderMode}-captured-render.png`;
    document.body.appendChild(link);
    link.click();
    link.remove();
  };

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Captured Template Render
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            Render From Camera Captures
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Pakai foto hasil countdown capture untuk render template aktif.
          </p>
        </div>

        <span className="rounded-full bg-slate-950 px-3 py-1 text-xs font-black text-white">
          {capturedCount} / {renderLayout.slots.length} captured
        </span>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-3">
        <button
          type="button"
          onClick={() => setRenderMode('raw')}
          className={`rounded-2xl px-4 py-3 text-xs font-black ${
            renderMode === 'raw'
              ? 'bg-slate-950 text-white'
              : 'border border-slate-200 bg-slate-50 text-slate-700'
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
              : 'border border-slate-200 bg-slate-50 text-slate-700'
          }`}
        >
          Print-Ready
        </button>

        <button
          type="button"
          onClick={handleRender}
          disabled={isRendering || capturedCount === 0}
          className="rounded-2xl bg-blue-600 px-4 py-3 text-xs font-black text-white disabled:opacity-40"
        >
          {isRendering ? 'Rendering...' : 'Render Captured Template'}
        </button>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-3">
        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Template
          </p>
          <p className="mt-1 truncate text-sm font-black text-slate-900">
            {activeTemplate.name}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Layout
          </p>
          <p className="mt-1 truncate text-sm font-black text-slate-900">
            {renderLayout.name}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Final Mirror
          </p>
          <p className="mt-1 text-sm font-black text-slate-900">
            {guideSettings.mirrorFinalOutput ? 'ON' : 'OFF'}
          </p>
        </div>
      </div>

      {error && (
        <div className="mt-4 rounded-2xl border border-red-200 bg-red-50 p-3 text-xs font-bold text-red-700">
          {error}
        </div>
      )}

      {previewUrl && (
        <div className="mt-4 rounded-3xl bg-slate-50 p-4">
          <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-xs font-black uppercase tracking-wider text-slate-400">
              {renderInfo}
            </p>

            <button
              type="button"
              onClick={handleDownload}
              className="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-xs font-black text-slate-700"
            >
              Download PNG
            </button>
          </div>

          <img
            src={previewUrl}
            alt="Captured template render"
            className="mx-auto max-h-[420px] rounded-xl border border-slate-200 bg-white object-contain"
          />
        </div>
      )}
    </section>
  );
}
TSX

grep -q "CameraCapturedRenderPanel" apps/booth-ui/src/camera/index.ts || cat >> apps/booth-ui/src/camera/index.ts <<'TS'
export * from './CameraCapturedRenderPanel';
TS

FILE="apps/booth-ui/src/camera/CameraSetupPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/camera/CameraSetupPanel.tsx")
text = path.read_text()

if "CameraCapturedRenderPanel" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(
        insert_at,
        "import { CameraCapturedRenderPanel } from './CameraCapturedRenderPanel';",
    )
    text = "\n".join(lines) + "\n"

if "<CameraCapturedRenderPanel />" not in text:
    marker = "<CapturedFramesPanel />"

    if marker not in text:
        raise SystemExit(
            "Could not find <CapturedFramesPanel />. Put <CameraCapturedRenderPanel /> below it manually."
        )

    text = text.replace(
        marker,
        marker + "\n      <CameraCapturedRenderPanel />",
        1,
    )

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "CameraCapturedRenderPanel\\|Render Captured Template\\|renderPrintReadyTemplateToCanvas" -n apps/booth-ui/src/camera || true

echo ""
echo "9A3I done."
