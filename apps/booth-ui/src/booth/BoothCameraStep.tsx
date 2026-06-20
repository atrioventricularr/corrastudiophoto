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
