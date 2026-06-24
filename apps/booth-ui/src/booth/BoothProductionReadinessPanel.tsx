import React, { useMemo, useState } from 'react';
import {
  clearBoothHardwareTestRecords,
  loadBoothHardwareTestRecords,
} from './booth-hardware-test-storage';

const REQUIRED_TESTS = [
  'Electron runtime bridge',
  'Printer discovery',
  'Printer test',
  'Camera discovery',
  'Camera preview',
  'Fullscreen on',
  'Kiosk on',
];

export function BoothProductionReadinessPanel() {
  const [records, setRecords] = useState(() => loadBoothHardwareTestRecords());

  const summary = useMemo(() => {
    const passedLabels = new Set(
      records
        .filter((record) => record.status === 'passed')
        .map((record) => record.label),
    );

    const missing = REQUIRED_TESTS.filter((label) => !passedLabels.has(label));

    return {
      required: REQUIRED_TESTS.length,
      passed: REQUIRED_TESTS.length - missing.length,
      missing,
      ready: missing.length === 0,
    };
  }, [records]);

  const refresh = () => setRecords(loadBoothHardwareTestRecords());

  const clear = () => {
    clearBoothHardwareTestRecords();
    refresh();
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Production Readiness
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Final hardware checklist before booth goes live.
          </p>
        </div>

        <div
          className={`rounded-2xl px-3 py-2 text-xs font-black ${
            summary.ready
              ? 'bg-emerald-500/20 text-emerald-100'
              : 'bg-amber-500/20 text-amber-100'
          }`}
        >
          {summary.ready ? 'READY' : 'NOT READY'} · {summary.passed}/{summary.required}
        </div>
      </div>

      <div className="mt-4 grid gap-2">
        {REQUIRED_TESTS.map((label) => {
          const record = records.find((item) => item.label === label);
          const passed = record?.status === 'passed';

          return (
            <div
              key={label}
              className={`rounded-2xl p-3 ${
                passed ? 'bg-emerald-500/20' : 'bg-white/10'
              }`}
            >
              <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
                {passed ? '✅' : '⬜'} {label}
              </p>
              {record?.message && (
                <p className="mt-1 text-[11px] font-bold text-white/50">
                  {record.message}
                </p>
              )}
            </div>
          );
        })}
      </div>

      <div className="mt-4 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={refresh}
          className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
        >
          Refresh
        </button>

        <button
          type="button"
          onClick={clear}
          className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-2 text-xs font-black text-red-100"
        >
          Clear Test Records
        </button>
      </div>

      {!summary.ready && (
        <div className="mt-4 rounded-2xl bg-amber-500/20 p-3 text-xs font-bold text-amber-100">
          Missing: {summary.missing.join(', ')}
        </div>
      )}
    </section>
  );
}
