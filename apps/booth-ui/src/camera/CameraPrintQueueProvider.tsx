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
  completedAt?: string;
  errorMessage?: string;
};

type EnqueuePrintJobInput = {
  output: CameraRenderOutput;
  copies: number;
};

type CameraPrintQueueContextValue = {
  printJobs: CameraPrintJob[];
  latestPrintJob: CameraPrintJob | null;
  enqueuePrintJob: (input: EnqueuePrintJobInput) => CameraPrintJob;
  updatePrintJobStatus: (
    jobId: string,
    status: CameraPrintJobStatus,
    errorMessage?: string,
  ) => void;
  removePrintJob: (jobId: string) => void;
  clearPrintJobs: () => void;
};

const CameraPrintQueueContext =
  createContext<CameraPrintQueueContextValue | null>(null);

type CameraPrintQueueProviderProps = {
  children: ReactNode;
};

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
      errorMessage?: string,
    ) => {
      const now = new Date().toISOString();

      setPrintJobs((current) =>
        current.map((job) => {
          if (job.id !== jobId) return job;

          return {
            ...job,
            status,
            updatedAt: now,
            completedAt: status === 'completed' ? now : job.completedAt,
            errorMessage:
              status === 'failed'
                ? errorMessage || 'Print job failed.'
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
