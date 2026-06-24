import React, { useState } from 'react';
import { runBoothReleaseDiagnostics } from './booth-release-diagnostics';

export function BoothReleaseDiagnosticsPanel() {
  const [isRunning, setIsRunning] = useState(false);
  const [results, setResults] = useState<Array<{ label: string; ok: boolean; message: string }>>([]);
  const [error, setError] = useState('');

  const runDiagnostics = async () => {
    setIsRunning(true);
    setError('');

    try {
      setResults(await runBoothReleaseDiagnostics());
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : 'Release diagnostics failed.');
    } finally {
      setIsRunning(false);
    }
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Release Diagnostics
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Pulls payment/cloud/disk/hardware signals into release readiness.
          </p>
        </div>

        <button
          type="button"
          onClick={() => void runDiagnostics()}
          disabled={isRunning}
          className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950 disabled:opacity-40"
        >
          {isRunning ? 'Running...' : 'Run Diagnostics'}
        </button>
      </div>

      {error && (
        <div className="mt-4 rounded-2xl border border-red-300/30 bg-red-500/20 p-3 text-xs font-bold text-red-100">
          {error}
        </div>
      )}

      <div className="mt-4 grid gap-2">
        {results.map((result) => (
          <div
            key={result.label}
            className={`rounded-2xl p-3 ${result.ok ? 'bg-emerald-500/20' : 'bg-amber-500/20'}`}
          >
            <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
              {result.ok ? '✅' : '⚠️'} {result.label}
            </p>
            <p className="mt-1 text-[11px] font-bold text-white/55">{result.message}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
