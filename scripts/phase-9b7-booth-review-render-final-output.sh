#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9B7 - Booth Review Render Output"
echo "========================================"

mkdir -p apps/booth-ui/src/booth

cat > apps/booth-ui/src/booth/BoothReviewStep.tsx <<'TSX'
import React, {
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { useLayouts } from '../layouts';
import { usePrinterProfile } from '../print';
import {
  getCaptureCompletionStatus,
  useCapturedFrames,
  useCameraRenderOutput,
} from '../camera';
import {
  renderFinalTemplateToCanvas,
  renderPrintReadyTemplateToCanvas,
} from '../render';
import { useTemplates } from '../templates';
import { useBoothFlow } from './BoothFlowProvider';

type BoothReviewRenderMode = 'raw' | 'print-ready';

export function BoothReviewStep() {
  const { setStep } = useBoothFlow();
  const { activeLayout, layouts, guideSettings } = useLayouts();
  const { printerProfile } = usePrinterProfile();
  const { activeTemplate } = useTemplates();
  const {
    capturedFramesBySlotId,
    photosBySlotId,
  } = useCapturedFrames();
  const {
    selectedOutput,
    saveRenderOutput,
    markOutputAsPrintCandidate,
  } = useCameraRenderOutput();

  const [renderMode, setRenderMode] =
    useState<BoothReviewRenderMode>('print-ready');
  const [isRendering, setIsRendering] = useState(false);
  const [error, setError] = useState('');
  const [lastRenderMessage, setLastRenderMessage] = useState('');

  const autoRenderAttemptedRef = useRef(false);

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

  const handleRender = async (source: 'manual' | 'auto' = 'manual') => {
    if (!completion.isComplete) {
      setError('Belum semua pose selesai. Kembali ke camera untuk melengkapi capture.');
      return;
    }

    setIsRendering(true);
    setError('');
    setLastRenderMessage('');

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

      const output = saveRenderOutput({
        dataUrl: result.dataUrl,
        widthPx: result.widthPx,
        heightPx: result.heightPx,
        renderMode,
        templateId: activeTemplate.id,
        templateName: activeTemplate.name,
        layoutId: renderLayout.id,
        layoutName: renderLayout.name,
        mirrorFinalOutput: guideSettings.mirrorFinalOutput,
        capturedSlotCount: capturedCount,
        totalSlotCount: renderLayout.slots.length,
        source,
      });

      markOutputAsPrintCandidate(output.id);

      setLastRenderMessage(
        source === 'auto'
          ? 'Final output auto-rendered and marked as print candidate.'
          : 'Final output rendered and marked as print candidate.',
      );
    } catch (caughtError) {
      setError(
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to render final output.',
      );
    } finally {
      setIsRendering(false);
    }
  };

  useEffect(() => {
    if (autoRenderAttemptedRef.current) return;
    if (!completion.isComplete) return;

    autoRenderAttemptedRef.current = true;
    void handleRender('auto');
  }, [completion.isComplete]);

  const handleContinueDelivery = () => {
    if (!selectedOutput) {
      void handleRender('manual');
      return;
    }

    setStep('delivery');
  };

  return (
    <div className="mt-4 grid gap-6 xl:grid-cols-[0.9fr_1.1fr]">
      <aside className="rounded-[2rem] bg-white p-6 text-slate-950">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-blue-500">
          Review
        </p>

        <h4 className="mt-3 text-5xl font-black leading-none">
          Review Your Photo
        </h4>

        <p className="mt-4 text-sm font-bold leading-relaxed text-slate-600">
          Hasil final dari capture customer akan muncul di sini. Kalau sudah oke,
          lanjutkan ke delivery/print.
        </p>

        <div className="mt-6 grid gap-3">
          <div
            className={`rounded-3xl p-4 ${
              completion.isComplete ? 'bg-emerald-50' : 'bg-amber-50'
            }`}
          >
            <p
              className={`text-xs font-black uppercase tracking-[0.2em] ${
                completion.isComplete ? 'text-emerald-500' : 'text-amber-500'
              }`}
            >
              Capture Status
            </p>
            <p
              className={`mt-2 text-xl font-black ${
                completion.isComplete ? 'text-emerald-800' : 'text-amber-800'
              }`}
            >
              {completion.totalCaptured} / {completion.totalRequired} poses
            </p>
          </div>

          <div className="rounded-3xl bg-blue-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-blue-400">
              Template
            </p>
            <p className="mt-2 text-lg font-black text-blue-800">
              {activeTemplate.name}
            </p>
          </div>

          <div className="rounded-3xl bg-slate-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Final Mirror
            </p>
            <p className="mt-2 text-lg font-black text-slate-800">
              {guideSettings.mirrorFinalOutput ? 'ON' : 'OFF'}
            </p>
          </div>
        </div>

        <div className="mt-6 grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => {
              setRenderMode('raw');
              autoRenderAttemptedRef.current = false;
            }}
            className={`rounded-3xl px-5 py-4 text-xs font-black uppercase tracking-[0.15em] ${
              renderMode === 'raw'
                ? 'bg-slate-950 text-white'
                : 'border border-slate-200 bg-white text-slate-700'
            }`}
          >
            Raw
          </button>

          <button
            type="button"
            onClick={() => {
              setRenderMode('print-ready');
              autoRenderAttemptedRef.current = false;
            }}
            className={`rounded-3xl px-5 py-4 text-xs font-black uppercase tracking-[0.15em] ${
              renderMode === 'print-ready'
                ? 'bg-slate-950 text-white'
                : 'border border-slate-200 bg-white text-slate-700'
            }`}
          >
            Print Ready
          </button>
        </div>

        <div className="mt-3 grid gap-3">
          <button
            type="button"
            onClick={() => void handleRender('manual')}
            disabled={isRendering || !completion.isComplete}
            className="rounded-3xl bg-blue-600 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white disabled:opacity-40"
          >
            {isRendering ? 'Rendering...' : 'Render Again'}
          </button>

          <button
            type="button"
            onClick={() => setStep('camera')}
            className="rounded-3xl border border-slate-200 bg-white px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
          >
            Back to Camera
          </button>

          <button
            type="button"
            onClick={handleContinueDelivery}
            disabled={!completion.isComplete || isRendering}
            className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white disabled:opacity-40"
          >
            Continue to Delivery
          </button>
        </div>

        {lastRenderMessage && (
          <div className="mt-4 rounded-2xl bg-emerald-50 p-3 text-sm font-bold text-emerald-700">
            {lastRenderMessage}
          </div>
        )}

        {error && (
          <div className="mt-4 rounded-2xl border border-red-200 bg-red-50 p-3 text-sm font-bold text-red-700">
            {error}
          </div>
        )}
      </aside>

      <section className="rounded-[2rem] border border-white/10 bg-white/10 p-6">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.25em] text-white/50">
              Final Preview
            </p>
            <h5 className="mt-1 text-2xl font-black text-white">
              {selectedOutput ? 'Output Ready' : 'Waiting for Render'}
            </h5>
          </div>

          {selectedOutput && (
            <span className="rounded-full bg-emerald-500 px-3 py-1 text-xs font-black text-white">
              Print candidate
            </span>
          )}
        </div>

        <div className="mt-5 flex min-h-[520px] items-center justify-center rounded-[2rem] bg-black/20 p-4">
          {isRendering && (
            <div className="text-center">
              <p className="text-5xl font-black text-white">Rendering...</p>
              <p className="mt-3 text-sm font-semibold text-white/50">
                Membuat final output dari captured frames.
              </p>
            </div>
          )}

          {!isRendering && selectedOutput && (
            <img
              src={selectedOutput.dataUrl}
              alt="Final booth output"
              className="max-h-[500px] rounded-3xl border border-white/10 bg-white object-contain"
            />
          )}

          {!isRendering && !selectedOutput && (
            <div className="text-center">
              <p className="text-5xl font-black text-white">No Output Yet</p>
              <p className="mt-3 max-w-md text-sm font-semibold text-white/50">
                Selesaikan semua capture lalu render final output.
              </p>
            </div>
          )}
        </div>

        {selectedOutput && (
          <div className="mt-4 grid gap-3 sm:grid-cols-3">
            <div className="rounded-3xl bg-white/10 p-4">
              <p className="text-xs font-black uppercase text-white/40">
                Size
              </p>
              <p className="mt-1 text-sm font-black text-white">
                {selectedOutput.widthPx} × {selectedOutput.heightPx}px
              </p>
            </div>

            <div className="rounded-3xl bg-white/10 p-4">
              <p className="text-xs font-black uppercase text-white/40">
                Mode
              </p>
              <p className="mt-1 text-sm font-black text-white">
                {selectedOutput.renderMode}
              </p>
            </div>

            <div className="rounded-3xl bg-white/10 p-4">
              <p className="text-xs font-black uppercase text-white/40">
                Captures
              </p>
              <p className="mt-1 text-sm font-black text-white">
                {selectedOutput.capturedSlotCount} / {selectedOutput.totalSlotCount}
              </p>
            </div>
          </div>
        )}
      </section>
    </div>
  );
}
TSX

grep -q "BoothReviewStep" apps/booth-ui/src/booth/index.ts || cat >> apps/booth-ui/src/booth/index.ts <<'TS'
export * from './BoothReviewStep';
TS

SCREEN="apps/booth-ui/src/booth/BoothCustomerScreen.tsx"

[ -f "$SCREEN" ] || {
  echo "ERROR: $SCREEN not found. Run 9B1 first."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/booth/BoothCustomerScreen.tsx")
text = path.read_text()

if "BoothReviewStep" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, "import { BoothReviewStep } from './BoothReviewStep';")
    text = "\n".join(lines) + "\n"

if "<BoothReviewStep />" not in text:
    pattern = re.compile(
        r"""\{currentStep === 'review' && \(
            <div className="mt-4">
              <h4 className="text-4xl font-black">Review Your Photo</h4>
              <p className="mt-2 text-sm font-semibold text-white/70">
                Hasil final render akan tampil di sini\.
              </p>
            </div>
          \)\}""",
        re.MULTILINE,
    )

    text2 = pattern.sub("{currentStep === 'review' && <BoothReviewStep />}", text, count=1)

    if text2 == text:
        raise SystemExit("Could not replace review block. Inspect BoothCustomerScreen.tsx manually.")

    text = text2

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "BoothReviewStep\\|Review Your Photo\\|Final Preview\\|Continue to Delivery" -n apps/booth-ui/src/booth || true

echo ""
echo "9B7 done."
