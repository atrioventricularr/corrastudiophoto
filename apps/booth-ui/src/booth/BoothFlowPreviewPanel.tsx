import React from 'react';
import { BoothCustomerScreen } from './BoothCustomerScreen';
import { BoothRuntimeProviders } from './BoothRuntimeProviders';

export function BoothFlowPreviewPanel() {
  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="mb-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Customer-Facing Flow
        </p>
        <h4 className="mt-1 text-xl font-black text-slate-950">
          Booth Flow Preview
        </h4>
        <p className="mt-1 text-sm font-semibold text-slate-500">
          Fondasi layar customer. Mode ini sudah punya runtime provider sendiri
          untuk camera capture, render output, dan print queue.
        </p>

        <div className="mt-3 flex flex-wrap gap-2">
          <a
            href="?mode=booth"
            className="rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white"
          >
            Open Booth Mode
          </a>

          <a
            href="#/booth"
            className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-xs font-black text-slate-700"
          >
            Open Hash Route
          </a>
        </div>
      </div>

      <BoothRuntimeProviders>
        <BoothCustomerScreen />
      </BoothRuntimeProviders>
    </section>
  );
}
