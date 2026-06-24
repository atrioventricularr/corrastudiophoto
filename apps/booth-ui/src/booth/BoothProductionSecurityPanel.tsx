import React, { useMemo, useState } from 'react';
import {
  clearProductionSecurityItems,
  loadProductionSecurityItems,
  REQUIRED_PRODUCTION_SECURITY_ITEMS,
  summarizeProductionSecurityItems,
  upsertProductionSecurityItem,
} from './booth-production-security-storage';

function getStatusClass(status: string) {
  if (status === 'passed') return 'bg-emerald-500/20 text-emerald-100';
  if (status === 'warning') return 'bg-amber-500/20 text-amber-100';
  if (status === 'failed') return 'bg-red-500/20 text-red-100';
  return 'bg-white/10 text-white/60';
}

export function BoothProductionSecurityPanel() {
  const [items, setItems] = useState(() => loadProductionSecurityItems());
  const [message, setMessage] = useState('');

  const summary = useMemo(() => summarizeProductionSecurityItems(items), [items]);

  const refresh = () => setItems(loadProductionSecurityItems());

  const setItemStatus = (label: string, status: 'passed' | 'warning' | 'failed') => {
    upsertProductionSecurityItem({
      label,
      status,
      message:
        status === 'passed'
          ? 'Checked manually.'
          : status === 'warning'
            ? 'Needs manual review.'
            : 'Blocked for production.',
    });

    refresh();
  };

  const runSoftAudit = () => {
    const hasSupabaseUrl = Boolean(import.meta.env.VITE_SUPABASE_URL);
    const hasAnonKey = Boolean(import.meta.env.VITE_SUPABASE_ANON_KEY);
    const hasUploadUrl = Boolean(import.meta.env.VITE_UPLOAD_BOOTH_ASSET_URL);
    const hasMayarUrl = Boolean(import.meta.env.VITE_CREATE_MAYAR_CHECKOUT_URL);
    const hasRefreshUrl = Boolean(import.meta.env.VITE_REFRESH_BOOTH_SIGNED_URL_URL);

    upsertProductionSecurityItem({
      label: 'Cloud upload configured',
      status: hasSupabaseUrl && hasAnonKey && hasUploadUrl && hasRefreshUrl ? 'passed' : 'warning',
      message: hasUploadUrl ? 'Cloud upload env detected.' : 'Cloud upload env missing.',
    });

    upsertProductionSecurityItem({
      label: 'Payment provider configured',
      status: hasMayarUrl ? 'passed' : 'warning',
      message: hasMayarUrl ? 'Mayar checkout env detected.' : 'Mayar checkout env missing.',
    });

    upsertProductionSecurityItem({
      label: 'Secrets not stored in frontend',
      status: 'warning',
      message: 'Manual check required: service role and Mayar secret must stay only in Supabase secrets.',
    });

    refresh();
    setMessage('Soft audit completed. Manual items still need review.');
  };

  const clear = () => {
    clearProductionSecurityItems();
    refresh();
    setMessage('Production security checklist cleared.');
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Production Security
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Manual + soft audit checklist before real deployment.
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
        {REQUIRED_PRODUCTION_SECURITY_ITEMS.map((label) => {
          const item = items.find((candidate) => candidate.label === label);
          const status = item?.status || 'untested';

          return (
            <div key={label} className={`rounded-2xl p-3 ${getStatusClass(status)}`}>
              <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
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
                    onClick={() => setItemStatus(label, 'passed')}
                    className="rounded-xl bg-white px-2 py-1 text-[10px] font-black text-slate-950"
                  >
                    Pass
                  </button>
                  <button
                    type="button"
                    onClick={() => setItemStatus(label, 'warning')}
                    className="rounded-xl border border-white/20 px-2 py-1 text-[10px] font-black"
                  >
                    Warn
                  </button>
                  <button
                    type="button"
                    onClick={() => setItemStatus(label, 'failed')}
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
          onClick={runSoftAudit}
          className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
        >
          Run Soft Audit
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
