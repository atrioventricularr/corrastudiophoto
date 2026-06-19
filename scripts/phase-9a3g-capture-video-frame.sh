#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3G - Capture Video Frame"
echo "========================================"

mkdir -p apps/booth-ui/src/camera

cat > apps/booth-ui/src/camera/capture-frame.ts <<'TS'
export type CameraFrameCaptureResult = {
  dataUrl: string;
  widthPx: number;
  heightPx: number;
  capturedAt: string;
};

export function getCameraPreviewVideoElement(): HTMLVideoElement | null {
  if (typeof document === 'undefined') return null;

  return document.querySelector<HTMLVideoElement>(
    '[data-corra-camera-preview-video="true"]',
  );
}

export function captureCameraPreviewFrame(input: {
  mirror?: boolean;
  mimeType?: 'image/png' | 'image/jpeg';
  quality?: number;
} = {}): CameraFrameCaptureResult {
  const video = getCameraPreviewVideoElement();

  if (!video) {
    throw new Error('Camera preview video element was not found.');
  }

  const width = video.videoWidth;
  const height = video.videoHeight;

  if (!width || !height) {
    throw new Error('Camera video is not ready yet.');
  }

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;

  const context = canvas.getContext('2d');

  if (!context) {
    throw new Error('Canvas 2D context is not available.');
  }

  if (input.mirror) {
    context.translate(width, 0);
    context.scale(-1, 1);
  }

  context.drawImage(video, 0, 0, width, height);

  return {
    dataUrl: canvas.toDataURL(input.mimeType || 'image/png', input.quality),
    widthPx: width,
    heightPx: height,
    capturedAt: new Date().toISOString(),
  };
}
TS

grep -q "capture-frame" apps/booth-ui/src/camera/index.ts || cat >> apps/booth-ui/src/camera/index.ts <<'TS'
export * from './capture-frame';
TS

PREVIEW="apps/booth-ui/src/camera/CameraLivePreview.tsx"

[ -f "$PREVIEW" ] || {
  echo "ERROR: $PREVIEW not found."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/camera/CameraLivePreview.tsx")
text = path.read_text()

if "data-corra-camera-preview-video" not in text:
    text = re.sub(
        r"<video(\s)",
        '<video\n        data-corra-camera-preview-video="true"\\1',
        text,
        count=1,
    )

path.write_text(text)
print("PATCH:", path)
PY

COUNTDOWN="apps/booth-ui/src/camera/CameraCountdownPanel.tsx"

[ -f "$COUNTDOWN" ] || {
  echo "ERROR: $COUNTDOWN not found. Run 9A3F first."
  exit 1
}

cat > "$COUNTDOWN" <<'TSX'
import React, {
  useEffect,
  useState,
} from 'react';
import { useLayouts } from '../layouts';
import {
  captureCameraPreviewFrame,
  type CameraFrameCaptureResult,
} from './capture-frame';
import { useCameraCaptureGuide } from './CameraCaptureGuideProvider';

type CountdownStatus =
  | 'idle'
  | 'counting'
  | 'captured'
  | 'failed';

export function CameraCountdownPanel() {
  const {
    activeStep,
    nextStep,
  } = useCameraCaptureGuide();
  const { guideSettings } = useLayouts();

  const [countdownSeconds, setCountdownSeconds] = useState(3);
  const [secondsLeft, setSecondsLeft] = useState<number | null>(null);
  const [status, setStatus] = useState<CountdownStatus>('idle');
  const [lastMessage, setLastMessage] = useState('');
  const [capturedFrame, setCapturedFrame] =
    useState<CameraFrameCaptureResult | null>(null);

  const isCounting = secondsLeft !== null;

  useEffect(() => {
    if (secondsLeft === null) return;

    if (secondsLeft <= 0) {
      try {
        const result = captureCameraPreviewFrame({
          mirror: guideSettings.mirrorFinalOutput,
          mimeType: 'image/png',
        });

        setCapturedFrame(result);
        setStatus('captured');
        setLastMessage(
          activeStep
            ? `Captured ${activeStep.label} at ${result.widthPx} × ${result.heightPx}px.`
            : `Captured frame at ${result.widthPx} × ${result.heightPx}px.`,
        );
      } catch (error) {
        setStatus('failed');
        setLastMessage(
          error instanceof Error
            ? error.message
            : 'Failed to capture camera frame.',
        );
      }

      setSecondsLeft(null);
      return;
    }

    const timer = window.setTimeout(() => {
      setSecondsLeft((current) => {
        if (current === null) return null;
        return current - 1;
      });
    }, 1000);

    return () => window.clearTimeout(timer);
  }, [activeStep, guideSettings.mirrorFinalOutput, secondsLeft]);

  const handleStartCountdown = () => {
    if (!activeStep) return;

    setStatus('counting');
    setLastMessage('');
    setCapturedFrame(null);
    setSecondsLeft(countdownSeconds);
  };

  const handleCancelCountdown = () => {
    setSecondsLeft(null);
    setStatus('idle');
    setLastMessage('Countdown cancelled.');
  };

  const handleRetake = () => {
    setStatus('idle');
    setLastMessage('');
    setCapturedFrame(null);
  };

  const handleNextAfterCapture = () => {
    setStatus('idle');
    setLastMessage('');
    setCapturedFrame(null);
    nextStep();
  };

  if (!activeStep) {
    return (
      <section className="rounded-3xl border border-amber-200 bg-amber-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-amber-500">
          Countdown
        </p>
        <p className="mt-2 text-sm font-bold text-amber-800">
          Tidak ada slot aktif untuk countdown.
        </p>
      </section>
    );
  }

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Countdown Capture
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            {isCounting ? `${secondsLeft}` : activeStep.label}
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Slot {activeStep.index + 1} dari {activeStep.total} ·{' '}
            {activeStep.slot.name}
          </p>
        </div>

        <span className="rounded-full bg-slate-950 px-3 py-1 text-xs font-black uppercase text-white">
          {status}
        </span>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-[1fr_160px]">
        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Countdown Seconds
          </span>
          <select
            value={countdownSeconds}
            onChange={(event) => setCountdownSeconds(Number(event.target.value))}
            disabled={isCounting}
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none disabled:opacity-50"
          >
            <option value={3}>3 seconds</option>
            <option value={5}>5 seconds</option>
            <option value={7}>7 seconds</option>
            <option value={10}>10 seconds</option>
          </select>
        </label>

        <div className="flex items-end">
          {isCounting ? (
            <button
              type="button"
              onClick={handleCancelCountdown}
              className="w-full rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-xs font-black text-red-700"
            >
              Cancel
            </button>
          ) : (
            <button
              type="button"
              onClick={handleStartCountdown}
              className="w-full rounded-2xl bg-blue-600 px-4 py-3 text-xs font-black text-white"
            >
              Start Countdown
            </button>
          )}
        </div>
      </div>

      {isCounting && (
        <div className="mt-4 rounded-3xl bg-blue-50 p-6 text-center">
          <p className="text-7xl font-black text-blue-700">
            {secondsLeft}
          </p>
          <p className="mt-2 text-xs font-black uppercase tracking-[0.2em] text-blue-400">
            Get Ready
          </p>
        </div>
      )}

      {capturedFrame && (
        <div className="mt-4 rounded-3xl bg-slate-50 p-4">
          <div className="mb-3 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-xs font-black uppercase tracking-wider text-slate-400">
              Captured Frame
            </p>
            <p className="font-mono text-xs font-bold text-slate-500">
              {capturedFrame.widthPx} × {capturedFrame.heightPx}px
            </p>
          </div>

          <img
            src={capturedFrame.dataUrl}
            alt="Captured frame"
            className="mx-auto max-h-72 rounded-2xl border border-slate-200 bg-white object-contain"
          />
        </div>
      )}

      {lastMessage && (
        <div className="mt-4 rounded-2xl bg-slate-50 p-3 text-sm font-bold text-slate-600">
          {lastMessage}
        </div>
      )}

      {status === 'captured' && (
        <div className="mt-4 grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            onClick={handleRetake}
            className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-xs font-black text-slate-700"
          >
            Retake
          </button>

          <button
            type="button"
            onClick={handleNextAfterCapture}
            className="rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white"
          >
            Continue to Next Pose
          </button>
        </div>
      )}
    </section>
  );
}
TSX

echo ""
echo "Relevant lines:"
grep -R "captureCameraPreviewFrame\\|data-corra-camera-preview-video\\|Captured Frame" -n apps/booth-ui/src/camera || true

echo ""
echo "9A3G done."
