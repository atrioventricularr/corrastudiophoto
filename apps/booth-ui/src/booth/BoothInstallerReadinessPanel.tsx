import React, { useMemo, useState } from 'react';
import {
  clearInstallerReadinessItems,
  loadInstallerReadinessItems,
  REQUIRED_INSTALLER_READINESS_ITEMS,
  summarizeInstallerReadiness,
  upsertInstallerReadinessItem,
} from './booth-installer-readiness-storage';
import type { BoothInstallerReadinessStatus } from './booth-installer-readiness-types';

function statusClass(status: BoothInstallerReadinessStatus | 'untested') {
  if (status === 'passed') return 'bg-emerald-500/20 text-emerald-100';
  if (status === 'warning') return 'bg-amber-500/20 text-amber-100';
  if (status === 'failed') return 'bg-red-500/20 text-red-100';
  return 'bg-white/10 text-white/60';
}

export function BoothInstallerReadinessPanel() {
  const [items, setItems] = useState(() => loadInstallerReadinessItems());
  const [message, setMessage] = useState('');

  const summary = useMemo(() => summarizeInstallerReadiness(items), [items]);

  const refresh = () => setItems(loadInstallerReadinessItems());

  const setStatus = (
    label: string,
    status: BoothInstallerReadinessStatus,
    nextMessage?: string,
  ) => {
    upsertInstallerReadinessItem({
      label,
      status,
      message: nextMessage || 'Manually checked.',
    });
    refresh();
  };

  const runSoftChecklist = () => {
    upsertInstallerReadinessItem({
      label: 'Electron Builder configured',
      status: 'warning',
      message: 'Run scripts/check-windows-installer-readiness.sh for filesystem check.',
    });

    upsertInstallerReadinessItem({
      label: 'Code signing configured',
      status: 'warning',
      message: 'Manual check: certificate/PFX/Thumbprint must be configured on Windows.',
    });

    upsertInstallerReadinessItem({
      label: 'Installer smoke tested',
      status: 'warning',
      message: 'Manual check required on Windows booth PC.',
    });

    refresh();
    setMessage('Soft checklist marked items that need manual Windows verification.');
  };

  const clear = () => {
    clearInstallerReadinessItems();
    refresh();
    setMessage('Installer readiness checklist cleared.');
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Windows Installer Readiness
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Checklist for installer, signing, kiosk startup, and real-machine QA.
          </p>
        </div>

        <div
          className={`rounded-2xl px-3 py-2 text-xs font-black ${
            summary.ready
              ? 'bg-emerald-500/20 text-emerald-100'
              : 'bg-amber-500/20 text-amber-100'
          }`}
        >
          {summary.ready ? 'READY' : 'REVIEW'} · {summary.passed}/{summary.total}
        </div>
      </div>

      <div className="mt-4 grid gap-2">
        {REQUIRED_INSTALLER_READINESS_ITEMS.map((label) => {
          const item = items.find((candidate) => candidate.label === label);
          const status = item?.status || 'untested';

          return (
            <div key={label} className={`rounded-2xl p-3 ${statusClass(status)}`}>
              <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <p className="text-xs font-black uppercase tracking-[0.14em]">
                    {label} · {status}
                  </p>
                  {item?.message && (
                    <p className="mt-1 text-[11px] font-bold opacity-80">
                      {item.message}
                    </p>
                  )}
                </div>

                <div className="flex flex-wrap gap-2">
                  <button
                    type="button"
                    onClick={() => setStatus(label, 'passed')}
                    className="rounded-xl bg-white px-2 py-1 text-[10px] font-black text-slate-950"
                  >
                    Pass
                  </button>
                  <button
                    type="button"
                    onClick={() => setStatus(label, 'warning', 'Needs manual review.')}
                    className="rounded-xl border border-white/20 px-2 py-1 text-[10px] font-black"
                  >
                    Warn
                  </button>
                  <button
                    type="button"
                    onClick={() => setStatus(label, 'failed', 'Blocked for installer release.')}
                    className="rounded-xl border border-red-200/40 px-2 py-1 text-[10px] font-black"
                  >
                    Fail
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="mt-4 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={runSoftChecklist}
          className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
        >
          Run Soft Checklist
        </button>

        <button
          type="button"
          onClick={refresh}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
        >
          Refresh
        </button>

        <button
          type="button"
          onClick={clear}
          className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-2 text-xs font-black text-red-100"
        >
          Clear
        </button>
      </div>

      {message && (
        <p className="mt-3 rounded-2xl bg-emerald-500/20 p-3 text-xs font-bold text-emerald-100">
          {message}
        </p>
      )}
    </section>
  );
}
