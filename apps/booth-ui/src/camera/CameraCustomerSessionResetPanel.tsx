import React, {
  useMemo,
  useState,
} from 'react';
import { useLayouts } from '../layouts';
import { getCaptureCompletionStatus } from './capture-completion';
import { useCameraCaptureGuide } from './CameraCaptureGuideProvider';
import { useCapturedFrames } from './CapturedFramesProvider';
import { useCameraPrintQueue } from './CameraPrintQueueProvider';
import { useCameraRenderOutput } from './CameraRenderOutputProvider';

export function CameraCustomerSessionResetPanel() {
  const { activeLayout } = useLayouts();
  const { resetStep } = useCameraCaptureGuide();

  const {
    capturedFramesBySlotId,
    clearCapturedFrames,
  } = useCapturedFrames();

  const {
    selectedOutput,
    printCandidateOutput,
    outputHistory,
    clearRenderOutputs,
  } = useCameraRenderOutput();

  const {
    printJobs,
    clearPrintJobs,
  } = useCameraPrintQueue();

  const [confirmArmed, setConfirmArmed] = useState(false);
  const [lastResetAt, setLastResetAt] = useState('');

  const completion = useMemo(
    () =>
      getCaptureCompletionStatus({
        layout: activeLayout,
        capturedFramesBySlotId,
      }),
    [activeLayout, capturedFramesBySlotId],
  );

  const capturedCount = Object.keys(capturedFramesBySlotId).length;
  const hasSessionData =
    capturedCount > 0 ||
    outputHistory.length > 0 ||
    printJobs.length > 0 ||
    Boolean(selectedOutput) ||
    Boolean(printCandidateOutput);

  const handleReset = () => {
    if (!confirmArmed) {
      setConfirmArmed(true);
      return;
    }

    clearCapturedFrames();
    clearRenderOutputs();
    clearPrintJobs();
    resetStep();

    setConfirmArmed(false);
    setLastResetAt(new Date().toLocaleString('id-ID'));
  };

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Customer Session Reset
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            Reset Local Session
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Pakai ini setelah satu customer selesai, supaya booth siap untuk
            customer berikutnya.
          </p>
        </div>

        <span
          className={`rounded-full px-3 py-1 text-xs font-black text-white ${
            hasSessionData ? 'bg-amber-500' : 'bg-emerald-600'
          }`}
        >
          {hasSessionData ? 'Session has data' : 'Clean'}
        </span>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-4">
        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Captures
          </p>
          <p className="mt-1 text-2xl font-black text-slate-950">
            {capturedCount}
          </p>
          <p className="mt-1 text-xs font-bold text-slate-500">
            {completion.progressPercent}% complete
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Render Outputs
          </p>
          <p className="mt-1 text-2xl font-black text-slate-950">
            {outputHistory.length}
          </p>
          <p className="mt-1 text-xs font-bold text-slate-500">
            {selectedOutput ? 'selected' : 'none'}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Print Candidate
          </p>
          <p className="mt-1 text-2xl font-black text-slate-950">
            {printCandidateOutput ? '1' : '0'}
          </p>
          <p className="mt-1 text-xs font-bold text-slate-500">
            {printCandidateOutput ? 'ready' : 'none'}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Print Jobs
          </p>
          <p className="mt-1 text-2xl font-black text-slate-950">
            {printJobs.length}
          </p>
          <p className="mt-1 text-xs font-bold text-slate-500">
            local queue
          </p>
        </div>
      </div>

      {confirmArmed && (
        <div className="mt-4 rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
          Klik tombol merah sekali lagi untuk benar-benar reset local customer
          session. Data capture/render/print queue sesi ini akan hilang dari UI.
        </div>
      )}

      {lastResetAt && (
        <div className="mt-4 rounded-2xl bg-emerald-50 p-3 text-sm font-bold text-emerald-700">
          Session terakhir di-reset pada {lastResetAt}.
        </div>
      )}

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <button
          type="button"
          onClick={handleReset}
          disabled={!hasSessionData && !confirmArmed}
          className={`rounded-2xl px-4 py-3 text-xs font-black text-white disabled:opacity-40 ${
            confirmArmed ? 'bg-red-600' : 'bg-slate-950'
          }`}
        >
          {confirmArmed
            ? 'Confirm Reset Customer Session'
            : 'Reset Customer Session'}
        </button>

        <button
          type="button"
          onClick={() => setConfirmArmed(false)}
          disabled={!confirmArmed}
          className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-xs font-black text-slate-700 disabled:opacity-40"
        >
          Cancel Reset
        </button>
      </div>
    </section>
  );
}
