import React, { useState } from 'react';
import {
  getBoothHardwareRuntimeInfo,
  isCorraHardwareBridgeAvailable,
  openBoothUserDataPath,
} from './booth-hardware-api';
import type { BoothHardwareRuntimeInfo } from './booth-hardware-types';
import { upsertBoothHardwareTestRecord } from './booth-hardware-test-storage';

export function BoothHardwareDiagnosticsPanel() {
  const [runtime, setRuntime] = useState<BoothHardwareRuntimeInfo | null>(null);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const runDiagnostics = async () => {
    setMessage('');
    setError('');

    const result = await getBoothHardwareRuntimeInfo();
    setRuntime(result);

    upsertBoothHardwareTestRecord({
      label: 'Electron runtime bridge',
      status: result.ok ? 'passed' : 'failed',
      message: result.ok ? 'Hardware bridge available.' : result.error,
    });

    if (result.ok) setMessage('Runtime diagnostics passed.');
    else setError(result.error || 'Runtime diagnostics failed.');
  };

  const openUserData = async () => {
    const result = await openBoothUserDataPath();

    if (result.ok) setMessage('Opened userData folder.');
    else setError(result.error || 'Failed to open userData folder.');
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Hardware Diagnostics
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Electron bridge, runtime, userData path, platform info.
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => void runDiagnostics()}
            className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
          >
            Run
          </button>

          <button
            type="button"
            onClick={() => void openUserData()}
            className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
          >
            Open userData
          </button>
        </div>
      </div>

      <div className="mt-4 rounded-2xl bg-white/10 p-3 text-xs font-bold text-white/60">
        Bridge: {isCorraHardwareBridgeAvailable() ? 'Available' : 'Unavailable'}
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

      {runtime && (
        <pre className="mt-4 max-h-72 overflow-auto rounded-2xl bg-black/40 p-3 text-[11px] font-bold text-white/60">
          {JSON.stringify(runtime, null, 2)}
        </pre>
      )}
    </section>
  );
}
