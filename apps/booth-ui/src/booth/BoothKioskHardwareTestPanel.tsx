import React, { useMemo, useState } from 'react';
import {
  setBoothFullscreen,
  setBoothKiosk,
} from './booth-hardware-api';
import {
  loadBoothHardwareTestRecords,
  upsertBoothHardwareTestRecord,
} from './booth-hardware-test-storage';

export function BoothKioskHardwareTestPanel() {
  const [records, setRecords] = useState(() => loadBoothHardwareTestRecords());
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const passedCount = useMemo(() => {
    return records.filter((record) => record.status === 'passed').length;
  }, [records]);

  const runAction = async (
    label: string,
    action: () => Promise<{ ok: boolean; error?: string }>,
  ) => {
    setMessage('');
    setError('');

    const result = await action();

    upsertBoothHardwareTestRecord({
      label,
      status: result.ok ? 'passed' : 'failed',
      message: result.ok ? `${label} succeeded.` : result.error,
    });

    setRecords(loadBoothHardwareTestRecords());

    if (result.ok) setMessage(`${label} succeeded.`);
    else setError(result.error || `${label} failed.`);
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Kiosk Runtime Test
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Fullscreen/kiosk mode controls and hardware readiness checklist.
          </p>
        </div>

        <div className="rounded-2xl bg-white/10 px-3 py-2 text-xs font-black text-white">
          {passedCount}/{records.length} passed
        </div>
      </div>

      <div className="mt-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
        <button
          type="button"
          onClick={() => void runAction('Fullscreen on', () => setBoothFullscreen(true))}
          className="rounded-2xl bg-white px-3 py-3 text-xs font-black text-slate-950"
        >
          Fullscreen On
        </button>

        <button
          type="button"
          onClick={() => void runAction('Fullscreen off', () => setBoothFullscreen(false))}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-3 text-xs font-black text-white"
        >
          Fullscreen Off
        </button>

        <button
          type="button"
          onClick={() => void runAction('Kiosk on', () => setBoothKiosk(true))}
          className="rounded-2xl bg-white px-3 py-3 text-xs font-black text-slate-950"
        >
          Kiosk On
        </button>

        <button
          type="button"
          onClick={() => void runAction('Kiosk off', () => setBoothKiosk(false))}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-3 text-xs font-black text-white"
        >
          Kiosk Off
        </button>
      </div>

      {message && (
        <div className="mt-4 rounded-2xl bg-emerald-500/20 p-3 text-xs font-bold text-emerald-100">
          {message}
        </div>
      )}

      {error && (
        <div className="mt-4 rounded-2xl border border-red-300/30 bg-red-500/20 p-3 text-xs font-bold text-red-100">
          {error}
        </div>
      )}

      <div className="mt-4 grid gap-2">
        {records.map((record) => (
          <div key={record.id} className="rounded-2xl bg-white/10 p-3">
            <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
              {record.label} · {record.status}
            </p>
            {record.message && (
              <p className="mt-1 text-[11px] font-bold text-white/50">
                {record.message}
              </p>
            )}
          </div>
        ))}
      </div>
    </section>
  );
}
