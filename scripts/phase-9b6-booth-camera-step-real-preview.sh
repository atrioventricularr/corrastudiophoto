#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9B6 - Booth Camera Step Real Preview"
echo "========================================"

mkdir -p apps/booth-ui/src/booth

cat > apps/booth-ui/src/booth/BoothRuntimeProviders.tsx <<'TSX'
import React, { type ReactNode } from 'react';
import {
  CameraCaptureGuideProvider,
  CameraPrintQueueProvider,
  CameraRenderOutputProvider,
  CapturedFramesProvider,
} from '../camera';
import { BoothFlowProvider } from './BoothFlowProvider';

type BoothRuntimeProvidersProps = {
  children: ReactNode;
};

export function BoothRuntimeProviders({
  children,
}: BoothRuntimeProvidersProps) {
  return (
    <BoothFlowProvider>
      <CameraCaptureGuideProvider>
        <CapturedFramesProvider>
          <CameraRenderOutputProvider>
            <CameraPrintQueueProvider>
              {children}
            </CameraPrintQueueProvider>
          </CameraRenderOutputProvider>
        </CapturedFramesProvider>
      </CameraCaptureGuideProvider>
    </BoothFlowProvider>
  );
}
TSX

cat > apps/booth-ui/src/booth/BoothCameraStep.tsx <<'TSX'
import React, {
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { useLayouts } from '../layouts';
import {
  CameraCaptureCompletionPanel,
  CameraCaptureGuidePanel,
  CameraCountdownPanel,
  CameraGuideOverlay,
  getCaptureCompletionStatus,
  useCapturedFrames,
} from '../camera';
import { useBoothFlow } from './BoothFlowProvider';

function BoothCameraLivePreview() {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const { guideSettings } = useLayouts();

  const [status, setStatus] = useState('Starting camera...');
  const [error, setError] = useState('');

  useEffect(() => {
    let stream: MediaStream | null = null;
    let cancelled = false;

    async function startCamera() {
      try {
        if (!navigator.mediaDevices?.getUserMedia) {
          throw new Error('Camera API is not available in this browser.');
        }

        stream = await navigator.mediaDevices.getUserMedia({
          video: {
            width: { ideal: 1920 },
            height: { ideal: 1080 },
            facingMode: 'user',
          },
          audio: false,
        });

        if (cancelled) {
          stream.getTracks().forEach((track) => track.stop());
          return;
        }

        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          await videoRef.current.play();
        }

        setStatus('Camera ready');
        setError('');
      } catch (caughtError) {
        setStatus('Camera failed');
        setError(
          caughtError instanceof Error
            ? caughtError.message
            : 'Failed to start camera.',
        );
      }
    }

    void startCamera();

    return () => {
      cancelled = true;

      if (stream) {
        stream.getTracks().forEach((track) => track.stop());
      }
    };
  }, []);

  return (
    <div>
      <div
        className="relative aspect-video overflow-hidden rounded-[2rem] border border-white/10 bg-black"
        data-mirror-preview={guideSettings.mirrorPreview ? 'true' : 'false'}
      >
        <video
          ref={videoRef}
          data-corra-camera-preview-video="true"
          muted
          playsInline
          autoPlay
          className="h-full w-full object-cover"
        />

        <CameraGuideOverlay />

        <div className="absolute left-4 top-4 rounded-full bg-black/60 px-4 py-2 text-xs font-black text-white backdrop-blur">
          {status}
        </div>

        {error && (
          <div className="absolute inset-x-4 bottom-4 rounded-2xl border border-red-400/40 bg-red-950/80 p-4 text-sm font-bold text-red-100 backdrop-blur">
            {error}
          </div>
        )}
      </div>

      <p className="mt-3 text-xs font-bold text-white/50">
        Camera ini memakai browser getUserMedia. Di Electron/local Windows,
        device camera/capture card akan ikut kebaca oleh OS.
      </p>
    </div>
  );
}

export function BoothCameraStep() {
  const { setStep } = useBoothFlow();
  const { activeLayout } = useLayouts();
  const { capturedFramesBySlotId } = useCapturedFrames();

  const completion = useMemo(
    () =>
      getCaptureCompletionStatus({
        layout: activeLayout,
        capturedFramesBySlotId,
      }),
    [activeLayout, capturedFramesBySlotId],
  );

  return (
    <div className="mt-4 grid gap-5 xl:grid-cols-[1.25fr_0.75fr]">
      <section className="rounded-[2rem] bg-white/10 p-4">
        <div className="mb-4 flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.25em] text-white/50">
              Camera Capture
            </p>
            <h4 className="mt-1 text-3xl font-black text-white">
              Follow the Pose Guide
            </h4>
            <p className="mt-1 text-sm font-semibold text-white/60">
              Ikuti guide di layar, lalu tekan Start Countdown untuk tiap pose.
            </p>
          </div>

          <span
            className={`rounded-full px-3 py-1 text-xs font-black text-white ${
              completion.isComplete ? 'bg-emerald-600' : 'bg-blue-600'
            }`}
          >
            {completion.totalCaptured} / {completion.totalRequired} captured
          </span>
        </div>

        <BoothCameraLivePreview />
      </section>

      <aside className="grid gap-4">
        <CameraCaptureGuidePanel />
        <CameraCountdownPanel />
      </aside>

      <div className="xl:col-span-2">
        <CameraCaptureCompletionPanel />

        <div className="mt-4 grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => setStep('payment')}
            className="rounded-3xl border border-white/20 bg-white/10 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
          >
            Back to Payment
          </button>

          <button
            type="button"
            onClick={() => setStep('review')}
            disabled={!completion.isComplete}
            className="rounded-3xl bg-white px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-950 disabled:opacity-40"
          >
            Continue to Review
          </button>
        </div>
      </div>
    </div>
  );
}
TSX

grep -q "BoothRuntimeProviders" apps/booth-ui/src/booth/index.ts || cat >> apps/booth-ui/src/booth/index.ts <<'TS'
export * from './BoothRuntimeProviders';
export * from './BoothCameraStep';
TS

cat > apps/booth-ui/src/booth/BoothModePage.tsx <<'TSX'
import React from 'react';
import { BoothCustomerScreen } from './BoothCustomerScreen';
import { BoothRuntimeProviders } from './BoothRuntimeProviders';

function goToAdminMode() {
  if (typeof window === 'undefined') return;

  const url = new URL(window.location.href);
  url.searchParams.delete('mode');
  url.searchParams.delete('booth');
  url.hash = '';

  window.location.href = url.toString();
}

export function BoothModePage() {
  return (
    <main className="min-h-screen bg-slate-950 p-4 text-white sm:p-6 lg:p-8">
      <div className="mx-auto flex max-w-7xl flex-col gap-4">
        <header className="flex flex-col gap-3 rounded-[2rem] border border-white/10 bg-white/5 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.25em] text-white/40">
              Corra Booth
            </p>
            <h1 className="mt-1 text-2xl font-black">
              Customer Booth Mode
            </h1>
            <p className="mt-1 text-sm font-semibold text-white/50">
              Full-page customer-facing flow. Buka via <code>?mode=booth</code>{' '}
              atau <code>#/booth</code>.
            </p>
          </div>

          <button
            type="button"
            onClick={goToAdminMode}
            className="rounded-2xl bg-white px-4 py-3 text-xs font-black text-slate-950"
          >
            Back to Admin
          </button>
        </header>

        <BoothRuntimeProviders>
          <BoothCustomerScreen />
        </BoothRuntimeProviders>
      </div>
    </main>
  );
}
TSX

cat > apps/booth-ui/src/booth/BoothFlowPreviewPanel.tsx <<'TSX'
import React from 'react';
import { BoothCustomerScreen } from './BoothCustomerScreen';
import { BoothRuntimeProviders } from './BoothRuntimeProviders';

export function BoothFlowPreviewPanel() {
  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="mb-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Customer-Facing Flow
        </p>
        <h4 className="mt-1 text-xl font-black text-slate-950">
          Booth Flow Preview
        </h4>
        <p className="mt-1 text-sm font-semibold text-slate-500">
          Fondasi layar customer. Mode ini sudah punya runtime provider sendiri
          untuk camera capture, render output, dan print queue.
        </p>

        <div className="mt-3 flex flex-wrap gap-2">
          <a
            href="?mode=booth"
            className="rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white"
          >
            Open Booth Mode
          </a>

          <a
            href="#/booth"
            className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-xs font-black text-slate-700"
          >
            Open Hash Route
          </a>
        </div>
      </div>

      <BoothRuntimeProviders>
        <BoothCustomerScreen />
      </BoothRuntimeProviders>
    </section>
  );
}
TSX

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

if "BoothCameraStep" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, "import { BoothCameraStep } from './BoothCameraStep';")
    text = "\n".join(lines) + "\n"

if "<BoothCameraStep />" not in text:
    pattern = re.compile(
        r"""\{currentStep === 'camera' && \(
            <div className="mt-4">
              <h4 className="text-4xl font-black">Get Ready</h4>
              <p className="mt-2 text-sm font-semibold text-white/70">
                Camera full-screen customer capture akan ditempel di phase berikutnya\.
              </p>
            </div>
          \)\}""",
        re.MULTILINE,
    )

    text2 = pattern.sub("{currentStep === 'camera' && <BoothCameraStep />}", text, count=1)

    if text2 == text:
        raise SystemExit("Could not replace camera block. Inspect BoothCustomerScreen.tsx manually.")

    text = text2

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "BoothCameraStep\\|BoothRuntimeProviders\\|Follow the Pose Guide\\|data-corra-camera-preview-video" -n apps/booth-ui/src/booth || true

echo ""
echo "9B6 done."
