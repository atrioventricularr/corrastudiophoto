import React, {
  useEffect,
  useMemo,
  useState,
} from 'react';
import { useLayouts } from '../layouts';
import { getCaptureCompletionStatus } from './capture-completion';
import { getCameraPreviewVideoElement } from './capture-frame';
import { useCapturedFrames } from './CapturedFramesProvider';
import { isCameraPrintBridgeAvailable } from './print-bridge';
import { useCameraPrintQueue } from './CameraPrintQueueProvider';
import { useCameraRenderOutput } from './CameraRenderOutputProvider';

type ChecklistItem = {
  id: string;
  label: string;
  description: string;
  complete: boolean;
  warning?: boolean;
};

function ChecklistRow({ item }: { item: ChecklistItem }) {
  return (
    <div
      className={`flex items-start gap-3 rounded-2xl p-3 ${
        item.complete
          ? 'bg-emerald-50'
          : item.warning
            ? 'bg-amber-50'
            : 'bg-slate-50'
      }`}
    >
      <div
        className={`mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-black ${
          item.complete
            ? 'bg-emerald-600 text-white'
            : item.warning
              ? 'bg-amber-500 text-white'
              : 'bg-slate-300 text-slate-700'
        }`}
      >
        {item.complete ? '✓' : '!'}
      </div>

      <div>
        <p
          className={`text-sm font-black ${
            item.complete
              ? 'text-emerald-950'
              : item.warning
                ? 'text-amber-900'
                : 'text-slate-800'
          }`}
        >
          {item.label}
        </p>
        <p
          className={`mt-1 text-xs font-bold ${
            item.complete
              ? 'text-emerald-700'
              : item.warning
                ? 'text-amber-700'
                : 'text-slate-500'
          }`}
        >
          {item.description}
        </p>
      </div>
    </div>
  );
}

export function CameraToPrintFlowChecklistPanel() {
  const { activeLayout } = useLayouts();
  const { capturedFramesBySlotId } = useCapturedFrames();
  const {
    selectedOutput,
    printCandidateOutput,
  } = useCameraRenderOutput();
  const { printJobs } = useCameraPrintQueue();

  const [cameraReady, setCameraReady] = useState(false);

  useEffect(() => {
    const checkCameraReady = () => {
      const video = getCameraPreviewVideoElement();

      setCameraReady(
        Boolean(
          video &&
            video.readyState >= 2 &&
            video.videoWidth > 0 &&
            video.videoHeight > 0,
        ),
      );
    };

    checkCameraReady();

    const timer = window.setInterval(checkCameraReady, 1000);

    return () => window.clearInterval(timer);
  }, []);

  const completion = useMemo(
    () =>
      getCaptureCompletionStatus({
        layout: activeLayout,
        capturedFramesBySlotId,
      }),
    [activeLayout, capturedFramesBySlotId],
  );

  const completedPrintJobs = printJobs.filter(
    (job) => job.status === 'completed',
  );

  const failedPrintJobs = printJobs.filter((job) => job.status === 'failed');

  const bridgeAvailable = isCameraPrintBridgeAvailable();

  const checklist = useMemo<ChecklistItem[]>(() => {
    return [
      {
        id: 'camera-ready',
        label: 'Camera preview ready',
        description: cameraReady
          ? 'Preview camera sudah aktif dan punya frame video.'
          : 'Nyalakan / pilih camera device sampai preview muncul.',
        complete: cameraReady,
      },
      {
        id: 'captures-complete',
        label: 'All required poses captured',
        description: completion.isComplete
          ? `${completion.totalCaptured} dari ${completion.totalRequired} pose sudah captured.`
          : `${completion.missingSlots.length} pose masih missing.`,
        complete: completion.isComplete,
      },
      {
        id: 'render-saved',
        label: 'Final render saved',
        description: selectedOutput
          ? `${selectedOutput.widthPx} × ${selectedOutput.heightPx}px output sudah tersimpan di session.`
          : 'Render final template dari captured frames dulu.',
        complete: Boolean(selectedOutput),
      },
      {
        id: 'print-candidate',
        label: 'Print candidate selected',
        description: printCandidateOutput
          ? 'Output sudah ditandai sebagai kandidat print.'
          : 'Pilih output lalu klik Mark as Print Candidate.',
        complete: Boolean(printCandidateOutput),
      },
      {
        id: 'print-bridge',
        label: 'Electron print bridge ready',
        description: bridgeAvailable
          ? 'Bridge tersedia. Print bisa dikirim ke Electron.'
          : 'Bridge belum tersedia kalau masih di browser/Codespaces.',
        complete: bridgeAvailable,
        warning: !bridgeAvailable,
      },
      {
        id: 'print-completed',
        label: 'Print job completed',
        description:
          completedPrintJobs.length > 0
            ? `${completedPrintJobs.length} print job completed.`
            : failedPrintJobs.length > 0
              ? `${failedPrintJobs.length} print job failed. Cek error di queue.`
              : 'Buat print job lalu jalankan Print via Bridge / Mark Completed.',
        complete: completedPrintJobs.length > 0,
        warning: failedPrintJobs.length > 0,
      },
    ];
  }, [
    bridgeAvailable,
    cameraReady,
    completedPrintJobs.length,
    completion.isComplete,
    completion.missingSlots.length,
    completion.totalCaptured,
    completion.totalRequired,
    failedPrintJobs.length,
    printCandidateOutput,
    selectedOutput,
  ]);

  const requiredChecklist = checklist.filter(
    (item) => item.id !== 'print-bridge',
  );

  const completedRequired = requiredChecklist.filter(
    (item) => item.complete,
  ).length;

  const progressPercent = Math.round(
    (completedRequired / requiredChecklist.length) * 100,
  );

  const flowComplete = completedRequired === requiredChecklist.length;

  return (
    <section
      className={`rounded-3xl border p-4 shadow-sm ${
        flowComplete
          ? 'border-emerald-200 bg-emerald-50'
          : 'border-slate-200 bg-white'
      }`}
    >
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p
            className={`text-xs font-black uppercase tracking-[0.2em] ${
              flowComplete ? 'text-emerald-500' : 'text-slate-400'
            }`}
          >
            Camera to Print Flow
          </p>
          <h4
            className={`mt-1 text-xl font-black ${
              flowComplete ? 'text-emerald-950' : 'text-slate-950'
            }`}
          >
            {flowComplete
              ? 'End-to-End Flow Complete'
              : `${completedRequired} / ${requiredChecklist.length} Steps Complete`}
          </h4>
          <p
            className={`mt-1 text-sm font-semibold ${
              flowComplete ? 'text-emerald-700' : 'text-slate-500'
            }`}
          >
            Checklist cepat untuk memastikan alur camera → render → print sudah
            siap.
          </p>
        </div>

        <span
          className={`rounded-full px-3 py-1 text-xs font-black text-white ${
            flowComplete ? 'bg-emerald-600' : 'bg-slate-950'
          }`}
        >
          {progressPercent}%
        </span>
      </div>

      <div className="mt-4 h-3 overflow-hidden rounded-full bg-white/80">
        <div
          className={`h-full rounded-full ${
            flowComplete ? 'bg-emerald-600' : 'bg-blue-600'
          }`}
          style={{ width: `${progressPercent}%` }}
        />
      </div>

      <div className="mt-4 grid gap-3 lg:grid-cols-2">
        {checklist.map((item) => (
          <ChecklistRow key={item.id} item={item} />
        ))}
      </div>

      {flowComplete && (
        <div className="mt-4 rounded-2xl bg-white/80 p-3 text-sm font-bold text-emerald-800">
          Mantap. Satu flow lengkap dari capture sampai print status sudah
          berhasil di sesi ini.
        </div>
      )}
    </section>
  );
}
