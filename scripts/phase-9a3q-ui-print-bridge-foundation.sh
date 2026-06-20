#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3Q - UI Print Bridge Foundation"
echo "========================================"

mkdir -p apps/booth-ui/src/camera

cat > apps/booth-ui/src/camera/print-bridge.ts <<'TS'
export type CameraPrintBridgeInput = {
  jobId: string;
  dataUrl: string;
  widthPx: number;
  heightPx: number;
  copies: number;
  templateName: string;
  renderMode: string;
};

export type CameraPrintBridgeResult = {
  ok: boolean;
  jobId?: string;
  printerName?: string;
  message?: string;
  error?: string;
};

type CorraPrintBridge = {
  printImageDataUrl?: (
    input: CameraPrintBridgeInput,
  ) => Promise<CameraPrintBridgeResult>;
};

type CorraWindow = Window & {
  corra?: {
    print?: CorraPrintBridge;
  };
};

export function getCameraPrintBridge(): CorraPrintBridge | null {
  if (typeof window === 'undefined') return null;

  const maybeWindow = window as CorraWindow;

  return maybeWindow.corra?.print || null;
}

export function isCameraPrintBridgeAvailable(): boolean {
  return Boolean(getCameraPrintBridge()?.printImageDataUrl);
}

export async function printImageThroughBridge(
  input: CameraPrintBridgeInput,
): Promise<CameraPrintBridgeResult> {
  const bridge = getCameraPrintBridge();

  if (!bridge?.printImageDataUrl) {
    return {
      ok: false,
      jobId: input.jobId,
      error:
        'Electron print bridge is not available. Run inside Electron after the preload/main print handler is added.',
    };
  }

  try {
    return await bridge.printImageDataUrl(input);
  } catch (error) {
    return {
      ok: false,
      jobId: input.jobId,
      error:
        error instanceof Error
          ? error.message
          : 'Unknown print bridge error.',
    };
  }
}
TS

grep -q "print-bridge" apps/booth-ui/src/camera/index.ts || cat >> apps/booth-ui/src/camera/index.ts <<'TS'
export * from './print-bridge';
TS

PANEL="apps/booth-ui/src/camera/CameraPrintQueuePanel.tsx"

[ -f "$PANEL" ] || {
  echo "ERROR: $PANEL not found. Run 9A3P first."
  exit 1
}

cat > "$PANEL" <<'TSX'
import React, { useState } from 'react';
import {
  isCameraPrintBridgeAvailable,
  printImageThroughBridge,
} from './print-bridge';
import { useCameraPrintQueue } from './CameraPrintQueueProvider';
import {
  type CameraRenderOutput,
  useCameraRenderOutput,
} from './CameraRenderOutputProvider';

function formatTime(value: string) {
  return new Intl.DateTimeFormat('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    day: '2-digit',
    month: 'short',
  }).format(new Date(value));
}

function downloadOutput(output: CameraRenderOutput) {
  const safeTemplateName = output.templateName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

  const link = document.createElement('a');
  link.href = output.dataUrl;
  link.download = `${safeTemplateName || 'corra'}-print-candidate.png`;
  document.body.appendChild(link);
  link.click();
  link.remove();
}

export function CameraPrintQueuePanel() {
  const { printCandidateOutput } = useCameraRenderOutput();
  const {
    printJobs,
    enqueuePrintJob,
    updatePrintJobStatus,
    removePrintJob,
    clearPrintJobs,
  } = useCameraPrintQueue();

  const [copies, setCopies] = useState(1);
  const [printingJobId, setPrintingJobId] = useState('');

  const bridgeAvailable = isCameraPrintBridgeAvailable();

  const handleCreatePrintJob = () => {
    if (!printCandidateOutput) return;

    enqueuePrintJob({
      output: printCandidateOutput,
      copies,
    });
  };

  const handleCreateAndPrintJob = async () => {
    if (!printCandidateOutput) return;

    const job = enqueuePrintJob({
      output: printCandidateOutput,
      copies,
    });

    await handlePrintJob(job);
  };

  const handlePrintJob = async (job: {
    id: string;
    dataUrl: string;
    widthPx: number;
    heightPx: number;
    copies: number;
    templateName: string;
    renderMode: string;
  }) => {
    setPrintingJobId(job.id);
    updatePrintJobStatus(job.id, 'printing');

    const result = await printImageThroughBridge({
      jobId: job.id,
      dataUrl: job.dataUrl,
      widthPx: job.widthPx,
      heightPx: job.heightPx,
      copies: job.copies,
      templateName: job.templateName,
      renderMode: job.renderMode,
    });

    if (result.ok) {
      updatePrintJobStatus(job.id, 'completed');
    } else {
      updatePrintJobStatus(
        job.id,
        'failed',
        result.error || 'Print bridge failed.',
      );
    }

    setPrintingJobId('');
  };

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Local Print Queue
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            Print Job Candidate
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Queue lokal sementara untuk output yang sudah ditandai sebagai print candidate.
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <span className="rounded-full bg-slate-950 px-3 py-1 text-xs font-black text-white">
            {printJobs.length} jobs
          </span>

          <span
            className={`rounded-full px-3 py-1 text-xs font-black text-white ${
              bridgeAvailable ? 'bg-emerald-600' : 'bg-amber-500'
            }`}
          >
            {bridgeAvailable ? 'Bridge ready' : 'Bridge missing'}
          </span>
        </div>
      </div>

      {!bridgeAvailable && (
        <div className="mt-4 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-bold text-amber-800">
          Print bridge belum tersedia di environment ini. Ini normal kalau masih
          buka lewat browser/Codespaces. Next phase kita tambahkan Electron
          preload/main handler.
        </div>
      )}

      {printCandidateOutput ? (
        <div className="mt-4 rounded-3xl border border-blue-100 bg-blue-50 p-4">
          <div className="grid gap-4 lg:grid-cols-[160px_1fr]">
            <img
              src={printCandidateOutput.dataUrl}
              alt="Print candidate"
              className="h-40 w-full rounded-2xl border border-blue-100 bg-white object-contain"
            />

            <div>
              <p className="text-xs font-black uppercase tracking-[0.2em] text-blue-400">
                Current Print Candidate
              </p>
              <h5 className="mt-1 text-lg font-black text-blue-950">
                {printCandidateOutput.templateName}
              </h5>
              <p className="mt-1 text-sm font-bold text-blue-700">
                {printCandidateOutput.widthPx} × {printCandidateOutput.heightPx}px ·{' '}
                {printCandidateOutput.renderMode}
              </p>

              <div className="mt-4 grid gap-3 sm:grid-cols-[1fr_160px_160px_180px]">
                <label className="block">
                  <span className="text-xs font-black uppercase tracking-wider text-blue-400">
                    Copies
                  </span>
                  <select
                    value={copies}
                    onChange={(event) => setCopies(Number(event.target.value))}
                    className="mt-2 w-full rounded-2xl border border-blue-100 bg-white px-4 py-3 text-sm font-bold text-blue-950 outline-none"
                  >
                    <option value={1}>1 copy</option>
                    <option value={2}>2 copies</option>
                    <option value={3}>3 copies</option>
                    <option value={4}>4 copies</option>
                    <option value={5}>5 copies</option>
                  </select>
                </label>

                <button
                  type="button"
                  onClick={() => downloadOutput(printCandidateOutput)}
                  className="self-end rounded-2xl border border-blue-200 bg-white px-4 py-3 text-xs font-black text-blue-700"
                >
                  Download
                </button>

                <button
                  type="button"
                  onClick={handleCreatePrintJob}
                  className="self-end rounded-2xl bg-blue-600 px-4 py-3 text-xs font-black text-white"
                >
                  Create Job
                </button>

                <button
                  type="button"
                  onClick={() => void handleCreateAndPrintJob()}
                  disabled={Boolean(printingJobId)}
                  className="self-end rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white disabled:opacity-40"
                >
                  Create & Print
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="mt-4 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-bold text-amber-800">
          Belum ada print candidate. Pilih output di Session Final Output, lalu klik
          Mark as Print Candidate.
        </div>
      )}

      <div className="mt-4 flex items-center justify-between gap-3">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Queue History
        </p>

        <button
          type="button"
          onClick={clearPrintJobs}
          disabled={printJobs.length === 0}
          className="rounded-2xl border border-red-200 bg-red-50 px-4 py-2 text-xs font-black text-red-700 disabled:opacity-40"
        >
          Clear Queue
        </button>
      </div>

      <div className="mt-3 grid gap-3">
        {printJobs.length === 0 && (
          <div className="rounded-2xl bg-slate-50 p-4 text-sm font-bold text-slate-500">
            No print jobs yet.
          </div>
        )}

        {printJobs.map((job) => (
          <div
            key={job.id}
            className="grid gap-3 rounded-3xl border border-slate-100 bg-slate-50 p-3 lg:grid-cols-[96px_1fr_auto]"
          >
            <img
              src={job.dataUrl}
              alt={job.templateName}
              className="h-24 w-24 rounded-2xl border border-slate-200 bg-white object-cover"
            />

            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h5 className="text-sm font-black text-slate-950">
                  {job.templateName}
                </h5>
                <span
                  className={`rounded-full px-3 py-1 text-[10px] font-black uppercase ${
                    job.status === 'completed'
                      ? 'bg-emerald-100 text-emerald-700'
                      : job.status === 'failed'
                        ? 'bg-red-100 text-red-700'
                        : job.status === 'printing'
                          ? 'bg-blue-100 text-blue-700'
                          : job.status === 'cancelled'
                            ? 'bg-slate-200 text-slate-600'
                            : 'bg-yellow-100 text-yellow-700'
                  }`}
                >
                  {job.status}
                </span>
              </div>

              <p className="mt-1 text-xs font-bold text-slate-500">
                {job.widthPx} × {job.heightPx}px · {job.renderMode} · {job.copies}{' '}
                copy{job.copies > 1 ? 'ies' : ''}
              </p>
              <p className="mt-1 text-xs font-bold text-slate-400">
                Created {formatTime(job.createdAt)}
              </p>

              {job.errorMessage && (
                <p className="mt-2 rounded-xl bg-red-50 px-3 py-2 text-xs font-bold text-red-700">
                  {job.errorMessage}
                </p>
              )}
            </div>

            <div className="grid gap-2 sm:grid-cols-2 lg:w-56 lg:grid-cols-1">
              <button
                type="button"
                onClick={() => void handlePrintJob(job)}
                disabled={Boolean(printingJobId)}
                className="rounded-2xl border border-slate-300 bg-white px-3 py-2 text-[10px] font-black text-slate-800 disabled:opacity-40"
              >
                {printingJobId === job.id ? 'Printing...' : 'Print via Bridge'}
              </button>

              <button
                type="button"
                onClick={() => updatePrintJobStatus(job.id, 'completed')}
                className="rounded-2xl border border-emerald-200 bg-white px-3 py-2 text-[10px] font-black text-emerald-700"
              >
                Mark Completed
              </button>

              <button
                type="button"
                onClick={() =>
                  updatePrintJobStatus(job.id, 'failed', 'Manual failure marker.')
                }
                className="rounded-2xl border border-red-200 bg-white px-3 py-2 text-[10px] font-black text-red-700"
              >
                Mark Failed
              </button>

              <button
                type="button"
                onClick={() => removePrintJob(job.id)}
                className="rounded-2xl border border-slate-200 bg-white px-3 py-2 text-[10px] font-black text-slate-700"
              >
                Remove
              </button>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
TSX

echo ""
echo "Relevant lines:"
grep -R "printImageThroughBridge\\|Print via Bridge\\|Bridge ready\\|Bridge missing" -n apps/booth-ui/src/camera || true

echo ""
echo "9A3Q done."
