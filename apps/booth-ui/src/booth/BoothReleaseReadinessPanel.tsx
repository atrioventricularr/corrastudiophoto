import React, { useMemo, useState } from 'react';
import {
  clearBoothReleaseCheckRecords,
  loadBoothReleaseCheckRecords,
  REQUIRED_RELEASE_CHECKS,
  summarizeBoothReleaseReadiness,
  upsertBoothReleaseCheckRecord,
} from './booth-release-readiness-storage';
import type { BoothReleaseCheckCategory, BoothReleaseCheckStatus } from './booth-release-types';

function categoryFor(label: string): BoothReleaseCheckCategory {
  if (label.includes('TypeScript') || label.includes('build')) return 'build';
  if (label.includes('Electron')) return 'electron';
  if (label.includes('Payment')) return 'payment';
  if (label.includes('Cloud')) return 'cloud';
  if (label.includes('Disk')) return 'disk';
  if (label.includes('Printer') || label.includes('Camera')) return 'hardware';
  if (label.includes('Kiosk') || label.includes('unlock')) return 'kiosk';
  if (label.includes('delivery')) return 'content';
  return 'release';
}

export function BoothReleaseReadinessPanel() {
  const [records, setRecords] = useState(() => loadBoothReleaseCheckRecords());
  const summary = useMemo(() => summarizeBoothReleaseReadiness(records), [records]);
  const refresh = () => setRecords(loadBoothReleaseCheckRecords());

  const mark = (label: string, status: BoothReleaseCheckStatus) => {
    upsertBoothReleaseCheckRecord({
      label,
      category: categoryFor(label),
      status,
      message: status === 'passed' ? 'Manually marked as passed.' : 'Manual review required.',
    });
    refresh();
  };

  const clear = () => {
    clearBoothReleaseCheckRecords();
    refresh();
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Release Candidate Readiness
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Checklist sebelum Corra Booth dipaketkan sebagai release candidate.
          </p>
        </div>

        <div
          className={`rounded-2xl px-3 py-2 text-xs font-black ${
            summary.ready ? 'bg-emerald-500/20 text-emerald-100' : 'bg-amber-500/20 text-amber-100'
          }`}
        >
          {summary.ready ? 'RC READY' : 'NOT READY'} · {summary.passed}/{summary.required}
        </div>
      </div>

      <div className="mt-4 grid gap-2">
        {REQUIRED_RELEASE_CHECKS.map((label) => {
          const record = records.find((item) => item.label === label);
          const passed = record?.status === 'passed';

          return (
            <div key={label} className={`rounded-2xl p-3 ${passed ? 'bg-emerald-500/20' : 'bg-white/10'}`}>
              <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
                    {passed ? '✅' : '⬜'} {label}
                  </p>
                  {record?.message && (
                    <p className="mt-1 text-[11px] font-bold text-white/50">{record.message}</p>
                  )}
                </div>

                <div className="flex flex-wrap gap-2">
                  <button
                    type="button"
                    onClick={() => mark(label, 'passed')}
                    className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
                  >
                    Pass
                  </button>
                  <button
                    type="button"
                    onClick={() => mark(label, 'warning')}
                    className="rounded-2xl border border-amber-300/30 bg-amber-500/20 px-3 py-2 text-xs font-black text-amber-100"
                  >
                    Warn
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="mt-4 flex flex-wrap gap-2">
        <button type="button" onClick={refresh} className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950">
          Refresh
        </button>
        <button
          type="button"
          onClick={clear}
          className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-2 text-xs font-black text-red-100"
        >
          Clear Release Checks
        </button>
      </div>

      {!summary.ready && (
        <div className="mt-4 rounded-2xl bg-amber-500/20 p-3 text-xs font-bold text-amber-100">
          Missing: {summary.missingLabels.join(', ')}
        </div>
      )}
    </section>
  );
}
