import React, { useMemo } from 'react';
import { useCameraPrintQueue } from './CameraPrintQueueProvider';

function formatTime(value: string) {
  return new Intl.DateTimeFormat('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    day: '2-digit',
    month: 'short',
  }).format(new Date(value));
}

export function CameraPrintQueueSummaryPanel() {
  const { printJobs, latestPrintJob } = useCameraPrintQueue();

  const summary = useMemo(() => {
    return {
      total: printJobs.length,
      queued: printJobs.filter((job) => job.status === 'queued').length,
      printing: printJobs.filter((job) => job.status === 'printing').length,
      completed: printJobs.filter((job) => job.status === 'completed').length,
      failed: printJobs.filter((job) => job.status === 'failed').length,
      cancelled: printJobs.filter((job) => job.status === 'cancelled').length,
    };
  }, [printJobs]);

  const successRate =
    summary.total === 0
      ? 0
      : Math.round((summary.completed / summary.total) * 100);

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Print Queue Summary
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            {summary.total === 0
              ? 'No Print Jobs Yet'
              : `${summary.completed} / ${summary.total} Completed`}
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Ringkasan status print job lokal untuk sesi ini.
          </p>
        </div>

        <span
          className={`rounded-full px-3 py-1 text-xs font-black text-white ${
            summary.failed > 0
              ? 'bg-red-600'
              : summary.printing > 0
                ? 'bg-blue-600'
                : summary.completed > 0
                  ? 'bg-emerald-600'
                  : 'bg-slate-950'
          }`}
        >
          {successRate}% success
        </span>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-3 lg:grid-cols-6">
        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Total
          </p>
          <p className="mt-1 text-2xl font-black text-slate-950">
            {summary.total}
          </p>
        </div>

        <div className="rounded-2xl bg-yellow-50 p-3">
          <p className="text-[10px] font-black uppercase text-yellow-500">
            Queued
          </p>
          <p className="mt-1 text-2xl font-black text-yellow-700">
            {summary.queued}
          </p>
        </div>

        <div className="rounded-2xl bg-blue-50 p-3">
          <p className="text-[10px] font-black uppercase text-blue-500">
            Printing
          </p>
          <p className="mt-1 text-2xl font-black text-blue-700">
            {summary.printing}
          </p>
        </div>

        <div className="rounded-2xl bg-emerald-50 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Completed
          </p>
          <p className="mt-1 text-2xl font-black text-emerald-700">
            {summary.completed}
          </p>
        </div>

        <div className="rounded-2xl bg-red-50 p-3">
          <p className="text-[10px] font-black uppercase text-red-500">
            Failed
          </p>
          <p className="mt-1 text-2xl font-black text-red-700">
            {summary.failed}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-100 p-3">
          <p className="text-[10px] font-black uppercase text-slate-500">
            Cancelled
          </p>
          <p className="mt-1 text-2xl font-black text-slate-700">
            {summary.cancelled}
          </p>
        </div>
      </div>

      <div className="mt-4 h-3 overflow-hidden rounded-full bg-slate-100">
        <div
          className="h-full rounded-full bg-emerald-600"
          style={{ width: `${successRate}%` }}
        />
      </div>

      {latestPrintJob && (
        <div className="mt-4 rounded-3xl bg-slate-50 p-4">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Latest Job
          </p>

          <div className="mt-3 grid gap-3 lg:grid-cols-[96px_1fr_auto] lg:items-center">
            <img
              src={latestPrintJob.dataUrl}
              alt={latestPrintJob.templateName}
              className="h-24 w-24 rounded-2xl border border-slate-200 bg-white object-cover"
            />

            <div>
              <h5 className="text-sm font-black text-slate-950">
                {latestPrintJob.templateName}
              </h5>
              <p className="mt-1 text-xs font-bold text-slate-500">
                {latestPrintJob.widthPx} × {latestPrintJob.heightPx}px ·{' '}
                {latestPrintJob.copies} copy
                {latestPrintJob.copies > 1 ? 'ies' : ''}
              </p>
              <p className="mt-1 text-xs font-bold text-slate-400">
                Updated {formatTime(latestPrintJob.updatedAt)}
              </p>

              {latestPrintJob.printerName && (
                <p className="mt-2 text-xs font-bold text-blue-700">
                  Printer: {latestPrintJob.printerName}
                </p>
              )}

              {latestPrintJob.errorMessage && (
                <p className="mt-2 text-xs font-bold text-red-700">
                  {latestPrintJob.errorMessage}
                </p>
              )}
            </div>

            <span
              className={`rounded-full px-3 py-1 text-xs font-black uppercase text-white ${
                latestPrintJob.status === 'completed'
                  ? 'bg-emerald-600'
                  : latestPrintJob.status === 'failed'
                    ? 'bg-red-600'
                    : latestPrintJob.status === 'printing'
                      ? 'bg-blue-600'
                      : latestPrintJob.status === 'cancelled'
                        ? 'bg-slate-500'
                        : 'bg-yellow-500'
              }`}
            >
              {latestPrintJob.status}
            </span>
          </div>
        </div>
      )}
    </section>
  );
}
