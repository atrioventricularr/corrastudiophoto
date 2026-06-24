import React, { useState } from 'react';
import { cleanupBoothDiskOlderThanDays, isCorraDiskAvailable } from './booth-disk-persistence-api';

export function BoothDiskRetentionPanel() {
  const [days, setDays] = useState(30);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const available = isCorraDiskAvailable();

  const cleanup = async () => {
    setMessage('');
    setError('');
    try {
      const result = await cleanupBoothDiskOlderThanDays(days);
      setMessage(`Deleted ${result.deletedCount || 0} old disk file(s).`);
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : 'Cleanup failed.');
    }
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
        Disk Retention
      </p>
      <p className="mt-1 text-sm font-bold text-white/60">
        Clean old Electron output files to avoid storage bloat.
      </p>

      <div className="mt-4 flex flex-col gap-2 sm:flex-row">
        <input
          type="number"
          min={1}
          value={days}
          onChange={(event) => setDays(Number(event.target.value || 30))}
          className="w-36 rounded-2xl border border-white/10 bg-white/10 px-3 py-2 text-xs font-bold text-white outline-none"
        />
        <button
          type="button"
          onClick={() => void cleanup()}
          disabled={!available}
          className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-2 text-xs font-black text-red-100 disabled:opacity-40"
        >
          Delete Files Older Than Days
        </button>
      </div>

      {message && <div className="mt-4 rounded-2xl bg-emerald-500/20 p-3 text-xs font-bold text-emerald-100">{message}</div>}
      {error && <div className="mt-4 rounded-2xl border border-red-300/30 bg-red-500/20 p-3 text-xs font-bold text-red-100">{error}</div>}
    </section>
  );
}
