#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3T - Print Job Result Detail"
echo "========================================"

PROVIDER="apps/booth-ui/src/camera/CameraPrintQueueProvider.tsx"
PANEL="apps/booth-ui/src/camera/CameraPrintQueuePanel.tsx"

[ -f "$PROVIDER" ] || {
  echo "ERROR: $PROVIDER not found. Run 9A3P first."
  exit 1
}

[ -f "$PANEL" ] || {
  echo "ERROR: $PANEL not found. Run 9A3P first."
  exit 1
}

cat > "$PROVIDER" <<'TSX'
import React, {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import type { CameraRenderOutput } from './CameraRenderOutputProvider';

export type CameraPrintJobStatus =
  | 'queued'
  | 'printing'
  | 'completed'
  | 'failed'
  | 'cancelled';

export type CameraPrintJob = {
  id: string;
  outputId: string;
  dataUrl: string;
  widthPx: number;
  heightPx: number;
  templateId: string;
  templateName: string;
  layoutId: string;
  layoutName: string;
  renderMode: string;
  copies: number;
  status: CameraPrintJobStatus;
  createdAt: string;
  updatedAt: string;
  startedAt?: string;
  completedAt?: string;
  printerName?: string;
  resultMessage?: string;
  errorMessage?: string;
};

type EnqueuePrintJobInput = {
  output: CameraRenderOutput;
  copies: number;
};

type CameraPrintJobUpdateMeta =
  | string
  | {
      printerName?: string;
      resultMessage?: string;
      errorMessage?: string;
    };

type CameraPrintQueueContextValue = {
  printJobs: CameraPrintJob[];
  latestPrintJob: CameraPrintJob | null;
  enqueuePrintJob: (input: EnqueuePrintJobInput) => CameraPrintJob;
  updatePrintJobStatus: (
    jobId: string,
    status: CameraPrintJobStatus,
    meta?: CameraPrintJobUpdateMeta,
  ) => void;
  removePrintJob: (jobId: string) => void;
  clearPrintJobs: () => void;
};

const CameraPrintQueueContext =
  createContext<CameraPrintQueueContextValue | null>(null);

type CameraPrintQueueProviderProps = {
  children: ReactNode;
};

function normalizeMeta(meta?: CameraPrintJobUpdateMeta) {
  if (!meta) return {};

  if (typeof meta === 'string') {
    return {
      errorMessage: meta,
    };
  }

  return meta;
}

export function CameraPrintQueueProvider({
  children,
}: CameraPrintQueueProviderProps) {
  const [printJobs, setPrintJobs] = useState<CameraPrintJob[]>([]);

  const enqueuePrintJob = useCallback(
    (input: EnqueuePrintJobInput): CameraPrintJob => {
      const now = new Date().toISOString();

      const job: CameraPrintJob = {
        id: `print-${Date.now()}-${Math.random().toString(16).slice(2)}`,
        outputId: input.output.id,
        dataUrl: input.output.dataUrl,
        widthPx: input.output.widthPx,
        heightPx: input.output.heightPx,
        templateId: input.output.templateId,
        templateName: input.output.templateName,
        layoutId: input.output.layoutId,
        layoutName: input.output.layoutName,
        renderMode: input.output.renderMode,
        copies: input.copies,
        status: 'queued',
        createdAt: now,
        updatedAt: now,
      };

      setPrintJobs((current) => [job, ...current].slice(0, 25));

      return job;
    },
    [],
  );

  const updatePrintJobStatus = useCallback(
    (
      jobId: string,
      status: CameraPrintJobStatus,
      meta?: CameraPrintJobUpdateMeta,
    ) => {
      const now = new Date().toISOString();
      const normalizedMeta = normalizeMeta(meta);

      setPrintJobs((current) =>
        current.map((job) => {
          if (job.id !== jobId) return job;

          return {
            ...job,
            status,
            updatedAt: now,
            startedAt:
              status === 'printing'
                ? now
                : job.startedAt,
            completedAt:
              status === 'completed' ||
              status === 'failed' ||
              status === 'cancelled'
                ? now
                : job.completedAt,
            printerName:
              normalizedMeta.printerName !== undefined
                ? normalizedMeta.printerName
                : job.printerName,
            resultMessage:
              normalizedMeta.resultMessage !== undefined
                ? normalizedMeta.resultMessage
                : status === 'completed' && !job.resultMessage
                  ? 'Print job completed.'
                  : job.resultMessage,
            errorMessage:
              status === 'failed'
                ? normalizedMeta.errorMessage || 'Print job failed.'
                : undefined,
          };
        }),
      );
    },
    [],
  );

  const removePrintJob = useCallback((jobId: string) => {
    setPrintJobs((current) => current.filter((job) => job.id !== jobId));
  }, []);

  const clearPrintJobs = useCallback(() => {
    setPrintJobs([]);
  }, []);

  const latestPrintJob = printJobs[0] || null;

  const value = useMemo<CameraPrintQueueContextValue>(() => {
    return {
      printJobs,
      latestPrintJob,
      enqueuePrintJob,
      updatePrintJobStatus,
      removePrintJob,
      clearPrintJobs,
    };
  }, [
    printJobs,
    latestPrintJob,
    enqueuePrintJob,
    updatePrintJobStatus,
    removePrintJob,
    clearPrintJobs,
  ]);

  return (
    <CameraPrintQueueContext.Provider value={value}>
      {children}
    </CameraPrintQueueContext.Provider>
  );
}

export function useCameraPrintQueue(): CameraPrintQueueContextValue {
  const context = useContext(CameraPrintQueueContext);

  if (!context) {
    throw new Error(
      'useCameraPrintQueue must be used inside CameraPrintQueueProvider',
    );
  }

  return context;
}
TSX

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/camera/CameraPrintQueuePanel.tsx")
text = path.read_text()

old_success = """    if (result.ok) {
      updatePrintJobStatus(job.id, 'completed');
    } else {"""

new_success = """    if (result.ok) {
      updatePrintJobStatus(job.id, 'completed', {
        printerName: result.printerName,
        resultMessage:
          result.message ||
          (result.printerName
            ? `Print sent to ${result.printerName}.`
            : 'Print completed via bridge.'),
      });
    } else {"""

if old_success in text and "Print completed via bridge" not in text:
    text = text.replace(old_success, new_success, 1)

old_failed = """      updatePrintJobStatus(
        job.id,
        'failed',
        result.error || 'Print bridge failed.',
      );"""

new_failed = """      updatePrintJobStatus(job.id, 'failed', {
        printerName: result.printerName,
        errorMessage: result.error || 'Print bridge failed.',
      });"""

if old_failed in text:
    text = text.replace(old_failed, new_failed, 1)

created_marker = """              <p className="mt-1 text-xs font-bold text-slate-400">
                Created {formatTime(job.createdAt)}
              </p>"""

details_block = """              <p className="mt-1 text-xs font-bold text-slate-400">
                Created {formatTime(job.createdAt)}
              </p>

              {job.startedAt && (
                <p className="mt-1 text-xs font-bold text-slate-400">
                  Started {formatTime(job.startedAt)}
                </p>
              )}

              {job.completedAt && (
                <p className="mt-1 text-xs font-bold text-slate-400">
                  Finished {formatTime(job.completedAt)}
                </p>
              )}

              {job.printerName && (
                <p className="mt-2 rounded-xl bg-blue-50 px-3 py-2 text-xs font-bold text-blue-700">
                  Printer: {job.printerName}
                </p>
              )}

              {job.resultMessage && (
                <p className="mt-2 rounded-xl bg-emerald-50 px-3 py-2 text-xs font-bold text-emerald-700">
                  {job.resultMessage}
                </p>
              )}"""

if created_marker in text and "Printer: {job.printerName}" not in text:
    text = text.replace(created_marker, details_block, 1)

manual_completed = "onClick={() => updatePrintJobStatus(job.id, 'completed')}"
manual_completed_new = """onClick={() =>
                  updatePrintJobStatus(job.id, 'completed', {
                    resultMessage: 'Manually marked as completed.',
                  })
                }"""

if manual_completed in text:
    text = text.replace(manual_completed, manual_completed_new)

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "printerName\\|resultMessage\\|startedAt\\|completedAt\\|Print completed via bridge\\|Printer:" -n "$PROVIDER" "$PANEL" || true

echo ""
echo "9A3T done."
