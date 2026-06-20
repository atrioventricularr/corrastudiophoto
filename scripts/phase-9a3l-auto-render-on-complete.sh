#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3L - Auto Render On Complete"
echo "========================================"

FILE="apps/booth-ui/src/camera/CameraCapturedRenderPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found. Run 9A3I first."
  exit 1
}

cat > "$FILE" <<'TSX'
import React, {
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { useLayouts } from '../layouts';
import { usePrinterProfile } from '../print';
import {
  renderFinalTemplateToCanvas,
  renderPrintReadyTemplateToCanvas,
} from '../render';
import { useTemplates } from '../templates';
import { getCaptureCompletionStatus } from './capture-completion';
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
  const [autoRenderOnComplete, setAutoRenderOnComplete] = useState(true);
  const [lastAutoRenderKey, setLastAutoRenderKey] = useState('');

  const autoRenderLockRef = useRef(false);

  const renderLayout =
    layouts.find((layout) => layout.id === activeTemplate.layoutId) ||
    activeLayout;

  const completion = useMemo(
    () =>
      getCaptureCompletionStatus({
        layout: renderLayout,
        capturedFramesBySlotId,
      }),
    [capturedFramesBySlotId, renderLayout],
  );

  const capturedCount = Object.keys(capturedFramesBySlotId).length;

  const renderKey = useMemo(() => {
    return JSON.stringify({
      templateId: activeTemplate.id,
      layoutId: renderLayout.id,
      renderMode,
      mirrorFinalOutput: guideSettings.mirrorFinalOutput,
      capturedSlotIds: Object.keys(capturedFramesBySlotId).sort(),
      capturedAt: Object.values(capturedFramesBySlotId)
        .map((frame) => frame.capturedAt)
        .sort(),
    });
  }, [
    activeTemplate.id,
    capturedFramesBySlotId,
    guideSettings.mirrorFinalOutput,
    renderLayout.id,
    renderMode,
  ]);

  const handleRender = async (source: 'manual' | 'auto' = 'manual') => {
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
        } PNG${source === 'auto' ? ' · auto-rendered' : ''}`,
      );

      if (source === 'auto') {
        setLastAutoRenderKey(renderKey);
      }
    } catch (caughtError) {
      setError(
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to render captured template.',
      );
    } finally {
      setIsRendering(false);
      autoRenderLockRef.current = false;
    }
  };

  useEffect(() => {
    if (!autoRenderOnComplete) return;
    if (!completion.isComplete) return;
    if (capturedCount === 0) return;
    if (isRendering) return;
    if (lastAutoRenderKey === renderKey) return;
    if (autoRenderLockRef.current) return;

    autoRenderLockRef.current = true;
    void handleRender('auto');
  }, [
    autoRenderOnComplete,
    capturedCount,
    completion.isComplete,
    isRendering,
    lastAutoRenderKey,
    renderKey,
  ]);

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

        <span
          className={`rounded-full px-3 py-1 text-xs font-black text-white ${
            completion.isComplete ? 'bg-emerald-600' : 'bg-slate-950'
          }`}
        >
          {capturedCount} / {renderLayout.slots.length} captured
        </span>
      </div>

      <div className="mt-4 rounded-2xl border border-blue-100 bg-blue-50 p-4">
        <div className="grid gap-3 sm:grid-cols-[1fr_180px] sm:items-center">
          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={autoRenderOnComplete}
              onChange={(event) => {
                setAutoRenderOnComplete(event.target.checked);
                setLastAutoRenderKey('');
              }}
            />
            <span className="text-sm font-black text-blue-900">
              Auto-render when all poses complete
            </span>
          </label>

          <div className="rounded-2xl bg-white px-4 py-3 text-xs font-black text-blue-900">
            {completion.isComplete ? 'Ready' : `${completion.progressPercent}% complete`}
          </div>
        </div>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-3">
        <button
          type="button"
          onClick={() => {
            setRenderMode('raw');
            setLastAutoRenderKey('');
          }}
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
          onClick={() => {
            setRenderMode('print-ready');
            setLastAutoRenderKey('');
          }}
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
          onClick={() => void handleRender('manual')}
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

      {completion.isComplete && autoRenderOnComplete && (
        <div className="mt-4 rounded-2xl bg-emerald-50 p-3 text-sm font-bold text-emerald-800">
          Semua pose lengkap. Auto-render aktif, hasil final akan dibuat otomatis.
        </div>
      )}

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

echo ""
echo "Relevant lines:"
grep -n "autoRenderOnComplete\\|Auto-render\\|handleRender('auto'\\|lastAutoRenderKey" "$FILE" || true

echo ""
echo "9A3L done."
